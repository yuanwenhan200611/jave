package com.fenglin.springboottest.service;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import com.fenglin.springboottest.entity.Category;
import com.fenglin.springboottest.entity.ContentItem;
import com.fenglin.springboottest.entity.SearchLog;
import com.fenglin.springboottest.mapper.CategoryMapper;
import com.fenglin.springboottest.mapper.ContentItemMapper;
import com.fenglin.springboottest.mapper.SearchLogMapper;
import com.fenglin.springboottest.vo.ContentItemVO;
import com.fenglin.springboottest.vo.PageResult;
import lombok.RequiredArgsConstructor;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;

import java.util.*;
import java.util.stream.Collectors;

/**
 * 首页服务：分类树、首页展示、关键词搜索（支持分级分类过滤 + 分页 + 排序）、
 * 搜索热词、条目详情、浏览量累加。
 */
@Service
@RequiredArgsConstructor
public class HomeService {

    private static final Logger log = LoggerFactory.getLogger(HomeService.class);

    /** 搜索排序方式 */
    public static final String SORT_HOT = "hot";        // 按浏览量（默认）
    public static final String SORT_NEW = "new";        // 按创建时间
    public static final String SORT_GRADE = "grade";    // 按品阶（天 > 地 > 玄 > 黄）
    public static final String SORT_TITLE = "title";    // 按标题

    private static final long DEFAULT_PAGE_SIZE = 10L;
    private static final long MAX_PAGE_SIZE = 100L;
    /** 搜索关键词最大长度，防超长串拖库 */
    private static final int MAX_KEYWORD_LENGTH = 50;

    private final CategoryMapper categoryMapper;
    private final ContentItemMapper contentItemMapper;
    private final SearchLogMapper searchLogMapper;

    // ==========================================================
    // 一、首页展示
    // ==========================================================

    /**
     * 首页展示数据：
     *   categories      分类树（含子孙）
     *   hotItems        热门榜（按浏览量前 8）
     *   latestItems     最新上架（按创建时间前 8）
     *   categoryCounts  各分类及其子孙分类的条目数
     *   grades          品阶列表（供前端筛选）
     *   totalItems      上架条目总数
     */
    public Map<String, Object> homeSummary() {
        Map<String, Object> data = new LinkedHashMap<>();

        List<Category> all = categoryMapper.selectList(
                new LambdaQueryWrapper<Category>()
                        .orderByAsc(Category::getLevel)
                        .orderByAsc(Category::getSort)
                        .orderByAsc(Category::getId));
        data.put("categories", buildTree(all));

        // 上架条目一次性取出，避免多次查库；数据量大时应改为 SQL 聚合
        List<ContentItem> allItems = contentItemMapper.selectList(
                new LambdaQueryWrapper<ContentItem>()
                        .eq(ContentItem::getStatus, 1));

        Map<Long, String> nameMap = all.stream()
                .collect(Collectors.toMap(Category::getId, Category::getName, (a, b) -> a));
        Map<Long, Long> parentMap = all.stream()
                .collect(Collectors.toMap(Category::getId, Category::getParentId, (a, b) -> a));

        // 热门榜：浏览量降序
        List<ContentItemVO> hot = allItems.stream()
                .sorted(Comparator.comparing(ContentItem::getViewCount,
                                Comparator.nullsFirst(Comparator.naturalOrder()))
                        .reversed())
                .limit(8)
                .map(i -> toVO(i, nameMap, parentMap))
                .collect(Collectors.toList());
        data.put("hotItems", hot);

        // 最新上架
        List<ContentItemVO> latest = allItems.stream()
                .sorted(Comparator.comparing(ContentItem::getCreateTime,
                                Comparator.nullsFirst(Comparator.naturalOrder()))
                        .reversed()
                        .thenComparing(ContentItem::getId, Comparator.reverseOrder()))
                .limit(8)
                .map(i -> toVO(i, nameMap, parentMap))
                .collect(Collectors.toList());
        data.put("latestItems", latest);

        // 各分类条目数（含子孙聚合）
        Map<Long, Long> direct = new HashMap<>();
        for (ContentItem i : allItems) {
            if (i.getCategoryId() != null) {
                direct.merge(i.getCategoryId(), 1L, Long::sum);
            }
        }
        Map<Long, List<Long>> childrenMap = buildChildrenMap(all);
        Map<Long, Long> aggregated = new LinkedHashMap<>();
        for (Category c : all) {
            aggregated.put(c.getId(), sumDeep(c.getId(), childrenMap, direct, new HashSet<>()));
        }
        data.put("categoryCounts", aggregated);

        // 品阶（去重，按 天/地/玄/黄 固定顺序，其余排后）
        List<String> gradeOrder = List.of("天阶", "地阶", "玄阶", "黄阶");
        List<String> grades = allItems.stream()
                .map(ContentItem::getGrade)
                .filter(Objects::nonNull)
                .map(String::trim)
                .filter(s -> !s.isEmpty())
                .distinct()
                .sorted(Comparator.comparingInt(g -> {
                    int idx = gradeOrder.indexOf(g);
                    return idx < 0 ? gradeOrder.size() : idx;
                }))
                .collect(Collectors.toList());
        data.put("grades", grades);

        data.put("totalItems", allItems.size());
        return data;
    }

    private long sumDeep(Long id, Map<Long, List<Long>> childrenMap,
                         Map<Long, Long> direct, Set<Long> visited) {
        if (!visited.add(id)) {
            return 0L; // 防环
        }
        long sum = direct.getOrDefault(id, 0L);
        for (Long child : childrenMap.getOrDefault(id, Collections.emptyList())) {
            sum += sumDeep(child, childrenMap, direct, visited);
        }
        return sum;
    }

    // ==========================================================
    // 二、分类树
    // ==========================================================

    /** 全量分类树（从顶级开始，children 已挂好） */
    public List<Category> categoryTree() {
        List<Category> all = categoryMapper.selectList(
                new LambdaQueryWrapper<Category>()
                        .orderByAsc(Category::getSort)
                        .orderByAsc(Category::getId));
        return buildTree(all);
    }

    /** 由扁平列表构建树；parentId 指向不存在的节点时按顶级处理，避免整枝丢失 */
    private List<Category> buildTree(List<Category> all) {
        Set<Long> ids = all.stream().map(Category::getId).collect(Collectors.toSet());
        Map<Long, List<Category>> byParent = new LinkedHashMap<>();
        for (Category c : all) {
            c.setChildren(new ArrayList<>());
            Long pid = (c.getParentId() == null || !ids.contains(c.getParentId())) ? 0L : c.getParentId();
            byParent.computeIfAbsent(pid, k -> new ArrayList<>()).add(c);
        }
        List<Category> roots = byParent.getOrDefault(0L, new ArrayList<>());
        attachChildren(roots, byParent, new HashSet<>());
        return roots;
    }

    private void attachChildren(List<Category> nodes, Map<Long, List<Category>> byParent, Set<Long> visited) {
        for (Category node : nodes) {
            if (!visited.add(node.getId())) {
                node.setChildren(new ArrayList<>());
                continue; // 数据脏导致成环时直接截断
            }
            List<Category> children = byParent.getOrDefault(node.getId(), new ArrayList<>());
            node.setChildren(children);
            attachChildren(children, byParent, visited);
        }
    }

    private Map<Long, List<Long>> buildChildrenMap(List<Category> all) {
        Map<Long, List<Long>> childrenMap = new HashMap<>();
        for (Category c : all) {
            childrenMap.computeIfAbsent(c.getParentId(), k -> new ArrayList<>()).add(c.getId());
        }
        return childrenMap;
    }

    /** 收集某分类自身 + 全部子孙分类的 id（分级搜索核心） */
    public List<Long> descendantIdsIncludingSelf(Long categoryId) {
        List<Category> all = categoryMapper.selectList(null);
        Map<Long, List<Long>> childrenMap = buildChildrenMap(all);
        List<Long> result = new ArrayList<>();
        Deque<Long> stack = new ArrayDeque<>();
        stack.push(categoryId);
        while (!stack.isEmpty()) {
            Long id = stack.pop();
            if (!result.add(id)) {
                continue; // 防环
            }
            List<Long> children = childrenMap.get(id);
            if (children != null) {
                stack.addAll(children);
            }
        }
        return result;
    }

    // ==========================================================
    // 三、搜索
    // ==========================================================

    /**
     * 搜索（分页）。保留原签名，内部走 {@link #searchPage}。
     */
    public Map<String, Object> search(String keyword, Long categoryId) {
        PageResult<ContentItemVO> page = searchPage(keyword, categoryId, SORT_HOT, 1,
                (int) DEFAULT_PAGE_SIZE, null);
        Map<String, Object> data = new LinkedHashMap<>();
        data.put("total", page.getTotal());
        data.put("list", page.getList());
        return data;
    }

    /**
     * 搜索（分页 + 排序）。
     *
     * @param keyword    关键词，匹配标题 / 简介 / 品阶；可空
     * @param categoryId 分类过滤，传任意层级会包含其全部子孙分类；可空
     * @param sort       hot(默认) / new / grade / title
     * @param pageNo     页码，从 1 开始
     * @param pageSize   每页条数，1~100，默认 10
     * @param username   发起搜索的用户（可空，落 search_log 供洞府联动）
     */
    public PageResult<ContentItemVO> searchPage(String keyword, Long categoryId,
                                                String sort, Integer pageNo, Integer pageSize,
                                                String username) {
        long p = pageNo == null || pageNo < 1 ? 1 : pageNo;
        long s = pageSize == null || pageSize < 1 ? DEFAULT_PAGE_SIZE : Math.min(pageSize, MAX_PAGE_SIZE);

        String kw = normalizeKeyword(keyword);
        boolean hasKw = kw != null;
        // 关键词与分类都没给：按「全部分类 + 热榜」处理，返回上架条目
        boolean hasCat = categoryId != null && categoryId > 0;

        LambdaQueryWrapper<ContentItem> countQw = buildSearchWrapper(kw, hasCat ? categoryId : null);
        Long totalObj = contentItemMapper.selectCount(countQw);
        long total = totalObj == null ? 0L : totalObj;

        List<ContentItemVO> list = new ArrayList<>();
        if (total > 0) {
            long offset = (p - 1) * s;
            if (offset < total) {
                LambdaQueryWrapper<ContentItem> qw = buildSearchWrapper(kw, hasCat ? categoryId : null);
                applySortAndLimit(qw, sort, s, offset);
                List<ContentItem> rows = contentItemMapper.selectList(qw);
                list = toVOList(rows);
            }
        }

        // 记录搜索日志（失败不影响主流程）；带上 username 供洞府「搜索足迹」联动
        if (hasKw || hasCat) {
            writeSearchLog(kw, hasCat ? categoryId : null, (int) total,
                    username == null || username.isBlank() ? null : username.trim());
        }
        return PageResult.of(list, total, p, s);
    }

    /** 构造搜索条件：status=1 且（关键词 OR 分组）且 category_id IN (子孙) */
    private LambdaQueryWrapper<ContentItem> buildSearchWrapper(String kw, Long categoryId) {
        LambdaQueryWrapper<ContentItem> qw = new LambdaQueryWrapper<>();
        qw.eq(ContentItem::getStatus, 1);
        if (kw != null) {
            // 关键词内的 % _ 需转义，否则用户输入 % 会变成通配符
            String escaped = kw.replace("\\", "\\\\").replace("%", "\\%").replace("_", "\\_");
            qw.and(w -> w.like(ContentItem::getTitle, escaped)
                    .or().like(ContentItem::getDescription, escaped)
                    .or().like(ContentItem::getGrade, escaped));
        }
        if (categoryId != null) {
            List<Long> ids = descendantIdsIncludingSelf(categoryId);
            if (ids.isEmpty()) {
                ids = List.of(categoryId);
            }
            qw.in(ContentItem::getCategoryId, ids);
        }
        return qw;
    }

    /**
     * 排序在「拼 SQL」阶段完成，而不是用 qw.orderByXxx + qw.last()：
     * MP 会把实体生成的 ORDER BY 追加到 last() 之后，导致品阶自定义排序被覆盖。
     * 这里 last 里带上完整的 ORDER BY + LIMIT，且各排序分支都以 id DESC 收尾保证稳定分页。
     */
    private void applySortAndLimit(LambdaQueryWrapper<ContentItem> qw, String sort, long limit, long offset) {
        String s = sort == null ? SORT_HOT : sort.trim().toLowerCase();
        String orderBy = switch (s) {
            case SORT_NEW -> "ORDER BY create_time DESC, id DESC";
            case SORT_TITLE -> "ORDER BY title ASC, id DESC";
            // 品阶：天 > 地 > 玄 > 黄，未在列表中的排在最后
            case SORT_GRADE -> "ORDER BY FIELD(grade, '天阶', '地阶', '玄阶', '黄阶') ASC, view_count DESC, id DESC";
            default -> "ORDER BY view_count DESC, id DESC";
        };
        qw.last(orderBy + " LIMIT " + limit + " OFFSET " + offset);
    }

    private String normalizeKeyword(String keyword) {
        if (keyword == null) {
            return null;
        }
        String kw = keyword.trim();
        if (kw.isEmpty()) {
            return null;
        }
        return kw.length() > MAX_KEYWORD_LENGTH ? kw.substring(0, MAX_KEYWORD_LENGTH) : kw;
    }

    private void writeSearchLog(String keyword, Long categoryId, int resultCount, String username) {
        try {
            // 只记录带关键词的搜索（纯点分类不算搜索词）
            if (keyword == null) {
                return;
            }
            SearchLog logRow = new SearchLog();
            logRow.setKeyword(keyword);
            logRow.setCategoryId(categoryId);
            logRow.setResultCount(resultCount);
            logRow.setUsername(username);
            searchLogMapper.insert(logRow);
        } catch (Exception e) {
            log.warn("写入搜索日志失败：{}", e.getMessage());
        }
    }

    // ==========================================================
    // 四、热词 / 详情 / 浏览量
    // ==========================================================

    /**
     * 搜索热词榜：近 N 天搜索日志中按次数降序取前 limit 个。
     * 日志为空时退化为「热门条目标题」，保证首页不空。
     */
    public List<Map<String, Object>> hotKeywords(int limit, int days) {
        int top = limit <= 0 ? 10 : Math.min(limit, 50);
        int span = days <= 0 ? 30 : Math.min(days, 365);

        List<Map<String, Object>> result = new ArrayList<>();

        List<Map<String, Object>> logRows = searchLogMapper.selectMaps(
                new QueryWrapper<SearchLog>()
                        .select("keyword", "COUNT(*) AS cnt")
                        .isNotNull("keyword")
                        .ne("keyword", "")
                        .ge("create_time", java.time.LocalDateTime.now().minusDays(span))
                        .groupBy("keyword")
                        .orderByDesc("cnt")
                        .last("LIMIT " + top));

        if (logRows != null && !logRows.isEmpty()) {
            for (Map<String, Object> row : logRows) {
                Map<String, Object> item = new LinkedHashMap<>();
                item.put("keyword", String.valueOf(row.get("keyword")));
                item.put("count", ((Number) row.get("cnt")).longValue());
                result.add(item);
            }
            return result;
        }

        // 兜底：用热门条目标题当热词
        List<ContentItem> hot = contentItemMapper.selectList(
                new LambdaQueryWrapper<ContentItem>()
                        .eq(ContentItem::getStatus, 1)
                        .orderByDesc(ContentItem::getViewCount)
                        .last("LIMIT " + top));
        for (ContentItem i : hot) {
            Map<String, Object> item = new LinkedHashMap<>();
            item.put("keyword", i.getTitle());
            item.put("count", i.getViewCount() == null ? 0L : i.getViewCount());
            result.add(item);
        }
        return result;
    }

    /** 条目详情（仅上架），同时浏览量 +1 */
    public ContentItemVO detail(Long id) {
        if (id == null) {
            throw new IllegalArgumentException("条目 id 不能为空");
        }
        ContentItem item = contentItemMapper.selectById(id);
        if (item == null || item.getStatus() == null || item.getStatus() != 1) {
            throw new IllegalArgumentException("条目不存在或已下架");
        }
        // 浏览量 +1（用 SQL 自增，避免并发丢失）
        contentItemMapper.update(null, new com.baomidou.mybatisplus.core.conditions.update.UpdateWrapper<ContentItem>()
                .setSql("view_count = view_count + 1")
                .eq("id", id));
        item.setViewCount((item.getViewCount() == null ? 0L : item.getViewCount()) + 1);
        return toVOList(List.of(item)).get(0);
    }

    /** 浏览量 +1，返回最新浏览量 */
    public long increaseView(Long id) {
        if (id == null) {
            throw new IllegalArgumentException("条目 id 不能为空");
        }
        ContentItem item = contentItemMapper.selectById(id);
        if (item == null) {
            throw new IllegalArgumentException("条目不存在");
        }
        contentItemMapper.update(null, new com.baomidou.mybatisplus.core.conditions.update.UpdateWrapper<ContentItem>()
                .setSql("view_count = view_count + 1")
                .eq("id", id));
        return (item.getViewCount() == null ? 0L : item.getViewCount()) + 1;
    }

    /** 同一分类下的相关推荐（按浏览量取前 N，排除自身） */
    public List<ContentItemVO> related(Long id, int limit) {
        ContentItem self = contentItemMapper.selectById(id);
        if (self == null) {
            return new ArrayList<>();
        }
        int top = limit <= 0 ? 6 : Math.min(limit, 20);
        List<Long> catIds = descendantIdsIncludingSelf(self.getCategoryId());
        List<ContentItem> rows = contentItemMapper.selectList(
                new LambdaQueryWrapper<ContentItem>()
                        .eq(ContentItem::getStatus, 1)
                        .in(self.getCategoryId() != null, ContentItem::getCategoryId, catIds)
                        .ne(ContentItem::getId, id)
                        .orderByDesc(ContentItem::getViewCount)
                        .last("LIMIT " + top));
        return toVOList(rows);
    }

    // ==========================================================
    // 五、VO 转换
    // ==========================================================

    private List<ContentItemVO> toVOList(List<ContentItem> rows) {
        if (rows == null || rows.isEmpty()) {
            return new ArrayList<>();
        }
        List<Category> all = categoryMapper.selectList(null);
        Map<Long, String> nameMap = all.stream()
                .collect(Collectors.toMap(Category::getId, Category::getName, (a, b) -> a));
        Map<Long, Long> parentMap = all.stream()
                .collect(Collectors.toMap(Category::getId, Category::getParentId, (a, b) -> a));
        return rows.stream().map(i -> toVO(i, nameMap, parentMap)).collect(Collectors.toList());
    }

    private ContentItemVO toVO(ContentItem src, Map<Long, String> nameMap, Map<Long, Long> parentMap) {
        ContentItemVO vo = new ContentItemVO();
        vo.setId(src.getId());
        vo.setTitle(src.getTitle());
        vo.setDescription(src.getDescription());
        vo.setCategoryId(src.getCategoryId());
        vo.setGrade(src.getGrade());
        vo.setIcon(src.getIcon());
        vo.setViewCount(src.getViewCount() == null ? 0L : src.getViewCount());
        vo.setStatus(src.getStatus());
        vo.setCreateTime(src.getCreateTime());
        vo.setCategoryName(nameMap.getOrDefault(src.getCategoryId(), "未分类"));
        vo.setCategoryPath(buildPath(src.getCategoryId(), nameMap, parentMap));
        return vo;
    }

    /** 自底向上拼接分类路径，如「功法 / 炼体功法」 */
    private String buildPath(Long categoryId, Map<Long, String> nameMap, Map<Long, Long> parentMap) {
        if (categoryId == null || !nameMap.containsKey(categoryId)) {
            return "未分类";
        }
        LinkedList<String> parts = new LinkedList<>();
        Long cur = categoryId;
        Set<Long> visited = new HashSet<>();
        while (cur != null && cur != 0L && nameMap.containsKey(cur) && visited.add(cur)) {
            parts.addFirst(nameMap.get(cur));
            cur = parentMap.get(cur);
        }
        return String.join(" / ", parts);
    }
}
