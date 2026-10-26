package com.fenglin.springboottest.service;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import com.fenglin.springboottest.entity.Category;
import com.fenglin.springboottest.entity.ContentItem;
import com.fenglin.springboottest.mapper.CategoryMapper;
import com.fenglin.springboottest.mapper.ContentItemMapper;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.util.*;

/**
 * 首页服务：分类树、首页展示数据、关键词搜索（支持分级分类过滤）。
 */
@Service
@RequiredArgsConstructor
public class HomeService {

    private final CategoryMapper categoryMapper;
    private final ContentItemMapper contentItemMapper;

    /** 首页展示：分类树 + 热门条目 + 各分类条目数 */
    public Map<String, Object> homeSummary() {
        Map<String, Object> data = new HashMap<>();
        data.put("categories", categoryTree());
        // 热门展示：按浏览量取前 8 条上架条目
        List<ContentItem> hot = contentItemMapper.selectList(
                new LambdaQueryWrapper<ContentItem>()
                        .eq(ContentItem::getStatus, 1)
                        .orderByDesc(ContentItem::getViewCount)
                        .last("LIMIT 8"));
        data.put("hotItems", hot);
        // 各分类条目数（含子孙分类聚合，供分类导航展示）
        Map<Long, Long> direct = new HashMap<>();
        for (Map<String, Object> row : contentItemMapper.selectMaps(
                new QueryWrapper<ContentItem>()
                        .select("category_id", "COUNT(*) AS cnt")
                        .eq("status", 1)
                        .groupBy("category_id"))) {
            direct.put(((Number) row.get("category_id")).longValue(),
                    ((Number) row.get("cnt")).longValue());
        }
        List<Category> all = categoryMapper.selectList(null);
        Map<Long, List<Long>> childrenMap = new HashMap<>();
        for (Category c : all) {
            childrenMap.computeIfAbsent(c.getParentId(), k -> new ArrayList<>()).add(c.getId());
        }
        Map<Long, Long> aggregated = new HashMap<>();
        for (Category c : all) {
            aggregated.put(c.getId(), sumDeep(c.getId(), childrenMap, direct, new HashSet<>()));
        }
        data.put("categoryCounts", aggregated);
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

    /** 全量分类树（从顶级开始） */
    public List<Category> categoryTree() {
        List<Category> all = categoryMapper.selectList(
                new LambdaQueryWrapper<Category>().orderByAsc(Category::getSort));
        Map<Long, List<Category>> byParent = new HashMap<>();
        for (Category c : all) {
            byParent.computeIfAbsent(c.getParentId(), k -> new ArrayList<>()).add(c);
        }
        List<Category> roots = byParent.getOrDefault(0L, new ArrayList<>());
        attachChildren(roots, byParent);
        return roots;
    }

    private void attachChildren(List<Category> nodes, Map<Long, List<Category>> byParent) {
        for (Category node : nodes) {
            List<Category> children = byParent.getOrDefault(node.getId(), new ArrayList<>());
            node.setChildren(children);
            attachChildren(children, byParent);
        }
    }

    /**
     * 搜索：关键词匹配标题/简介/品阶，可选按分类过滤。
     * 分级分类搜索：传入任意层级 categoryId，会自动包含其全部子孙分类下的条目。
     */
    public Map<String, Object> search(String keyword, Long categoryId) {
        List<Long> categoryIds = null;
        if (categoryId != null) {
            categoryIds = descendantIdsIncludingSelf(categoryId);
        }

        LambdaQueryWrapper<ContentItem> qw = new LambdaQueryWrapper<>();
        qw.eq(ContentItem::getStatus, 1);
        if (keyword != null && !keyword.isBlank()) {
            String kw = keyword.trim();
            qw.and(w -> w.like(ContentItem::getTitle, kw)
                    .or().like(ContentItem::getDescription, kw)
                    .or().like(ContentItem::getGrade, kw));
        }
        if (categoryIds != null) {
            qw.in(ContentItem::getCategoryId, categoryIds);
        }
        qw.orderByDesc(ContentItem::getViewCount);

        List<ContentItem> list = contentItemMapper.selectList(qw);
        Map<String, Object> data = new HashMap<>();
        data.put("total", list.size());
        data.put("list", list);
        return data;
    }

    /** 收集某分类自身 + 全部子孙分类的 id（分级搜索核心） */
    public List<Long> descendantIdsIncludingSelf(Long categoryId) {
        List<Category> all = categoryMapper.selectList(null);
        Map<Long, List<Long>> childrenMap = new HashMap<>();
        for (Category c : all) {
            childrenMap.computeIfAbsent(c.getParentId(), k -> new ArrayList<>()).add(c.getId());
        }
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
}
