package com.fenglin.springboottest.service;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.core.conditions.update.UpdateWrapper;
import com.fenglin.springboottest.entity.Quest;
import com.fenglin.springboottest.entity.UserProfile;
import com.fenglin.springboottest.entity.UserQuest;
import com.fenglin.springboottest.mapper.QuestMapper;
import com.fenglin.springboottest.mapper.UserProfileMapper;
import com.fenglin.springboottest.mapper.UserQuestMapper;
import com.fenglin.springboottest.util.RealmTier;
import com.fenglin.springboottest.vo.PageResult;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.function.Function;
import java.util.stream.Collectors;

/**
 * 任务阁服务：悬赏任务分页 / 个人发布 / 接取 / 完成 / 放弃 / 我的任务牌。
 *
 * 两大悬赏来源：
 *   · sect     宗门颁发，奖励贡献值 / 灵石（可兼得）
 *   · personal 个人发布，奖励天才地宝 / 法宝等（reward_item 描述，强度随难度）
 * 接取门槛：min_realm 修为限制 + max_accept 人数限制（完成/进行中占用名额，放弃释放）。
 *
 * 与洞府联动：user_quest 以 username 关联，ProfileService 聚合
 * 进行中任务数、完成任务数、累计贡献值与灵石；/api/profile/quests 返回我的任务牌。
 */
@Service
public class QuestService {

    private static final long DEFAULT_PAGE_SIZE = 10L;
    private static final long MAX_PAGE_SIZE = 50L;
    private static final int MAX_LIST = 50;
    private static final int MAX_MAX_ACCEPT = 99;

    private static final Set<String> DIFFICULTIES = Set.of("简单", "普通", "困难", "地狱");
    private static final Set<String> CATEGORIES = Set.of("斩妖", "夺宝", "护送", "炼丹", "寻物", "戒律", "其它");
    private static final Set<String> QUEST_TYPES = Set.of("sect", "personal");

    /** 境界从低到高：接取任务的修为门槛按此序比较（统一取自 RealmTier） */
    public static final List<String> REALM_ORDER = RealmTier.REALMS;

    private static final Map<Integer, String> STATUS_TEXT = Map.of(
            0, "进行中", 1, "已完成", 2, "已放弃");

    private final QuestMapper questMapper;
    private final UserQuestMapper userQuestMapper;
    private final UserProfileMapper userProfileMapper;

    public QuestService(QuestMapper questMapper, UserQuestMapper userQuestMapper,
                        UserProfileMapper userProfileMapper) {
        this.questMapper = questMapper;
        this.userQuestMapper = userQuestMapper;
        this.userProfileMapper = userProfileMapper;
    }

    /**
     * 悬赏任务分页列表，附带名额占用情况。
     *
     * @param type     sect（宗门悬赏）/ personal（个人悬赏），空 = 全部
     * @param category 分类过滤（可空 = 全部分类）
     * @param sort     hot（接取次数倒序，默认）/ new（发布时间倒序）/ reward（奖励倒序）/ hard（难度高在前）
     */
    public PageResult<Quest> page(String type, String category, String sort, Integer pageNo, Integer pageSize) {
        long p = pageNo == null || pageNo < 1 ? 1 : pageNo;
        long s = pageSize == null || pageSize < 1 ? DEFAULT_PAGE_SIZE : Math.min(pageSize, MAX_PAGE_SIZE);

        LambdaQueryWrapper<Quest> countQw = new LambdaQueryWrapper<Quest>().eq(Quest::getStatus, 1);
        if (type != null && !type.isBlank()) {
            countQw.eq(Quest::getQuestType, type.trim());
        }
        if (category != null && !category.isBlank()) {
            countQw.eq(Quest::getCategory, category.trim());
        }
        Long totalObj = questMapper.selectCount(countQw);
        long total = totalObj == null ? 0L : totalObj;

        List<Quest> list = new ArrayList<>();
        long offset = (p - 1) * s;
        if (total > 0 && offset < total) {
            LambdaQueryWrapper<Quest> qw = new LambdaQueryWrapper<Quest>().eq(Quest::getStatus, 1);
            if (type != null && !type.isBlank()) {
                qw.eq(Quest::getQuestType, type.trim());
            }
            if (category != null && !category.isBlank()) {
                qw.eq(Quest::getCategory, category.trim());
            }
            String key = sort == null ? "" : sort.trim().toLowerCase();
            if ("new".equals(key)) {
                qw.orderByDesc(Quest::getCreateTime).orderByDesc(Quest::getId);
            } else if ("reward".equals(key)) {
                // 奖励倒序：贡献值 + 灵石合计为宗门任务排序，个人任务按难度兜底
                qw.last("ORDER BY (reward_contribution + reward_stones) DESC, FIELD(difficulty, '地狱', '困难', '普通', '简单'), id DESC LIMIT " + s + " OFFSET " + offset);
            } else if ("hard".equals(key)) {
                // 难度排序需要 FIELD 函数，无法用 Wrapper 表达，直接拼 SQL 片段
                qw.last("ORDER BY FIELD(difficulty, '地狱', '困难', '普通', '简单') ASC, (reward_contribution + reward_stones) DESC LIMIT " + s + " OFFSET " + offset);
            } else {
                qw.orderByDesc(Quest::getAcceptCount).orderByDesc(Quest::getId);
            }
            if (!"reward".equals(key) && !"hard".equals(key)) {
                qw.last("LIMIT " + s + " OFFSET " + offset);
            }
            list = questMapper.selectList(qw);
        }
        fillQuota(list);
        return PageResult.of(list, total, p, s);
    }

    /** 分类统计（上架任务），供分堂 tab 计数。 */
    public Map<String, Long> categoryCounts(String type) {
        LambdaQueryWrapper<Quest> qw = new LambdaQueryWrapper<Quest>().eq(Quest::getStatus, 1);
        if (type != null && !type.isBlank()) {
            qw.eq(Quest::getQuestType, type.trim());
        }
        List<Quest> all = questMapper.selectList(qw);
        return all.stream().collect(Collectors.groupingBy(
                Quest::getCategory, Collectors.counting()));
    }

    /** 两大悬赏来源的数量统计，供类型 tab 计数。 */
    public Map<String, Long> typeCounts() {
        List<Quest> all = questMapper.selectList(
                new LambdaQueryWrapper<Quest>().eq(Quest::getStatus, 1));
        Map<String, Long> counts = new HashMap<>();
        counts.put("sect", all.stream().filter(q -> "sect".equals(q.getQuestType())).count());
        counts.put("personal", all.stream().filter(q -> "personal".equals(q.getQuestType())).count());
        return counts;
    }

    /**
     * 发布个人悬赏：奖励为物品（天才地宝/法宝等），强度自定（难度 + 修为门槛）。
     */
    @Transactional
    public Quest publish(String username, String title, String description, String category,
                         String difficulty, String minRealm, Integer maxAccept,
                         String rewardItem, String icon) {
        String name = requireUsername(username);

        String t = normalize(title, null, 100);
        if (t == null) {
            throw new IllegalArgumentException("任务名不能为空");
        }
        String d = normalize(description, "", 500);
        String c = normalize(category, "其它", 20);
        if (!CATEGORIES.contains(c)) {
            throw new IllegalArgumentException("分类不在可选范围内");
        }
        String diff = normalize(difficulty, "普通", 10);
        if (!DIFFICULTIES.contains(diff)) {
            throw new IllegalArgumentException("难度不在可选范围内");
        }
        String realm = normalize(minRealm, "炼气", 10);
        // 支持纯大境界（筑基）或大境界+层次（筑基中期），只要能解析出已知境界即合法
        if (RealmTier.realmWeight(realm) <= 0 && !REALM_ORDER.contains(realm)) {
            throw new IllegalArgumentException("修为门槛不在十大境界之内");
        }
        int quota = maxAccept == null ? 1 : maxAccept;
        if (quota < 1 || quota > MAX_MAX_ACCEPT) {
            throw new IllegalArgumentException("接取名额需在 1-" + MAX_MAX_ACCEPT + " 之间");
        }
        String item = normalize(rewardItem, null, 100);
        if (item == null) {
            throw new IllegalArgumentException("个人悬赏必须写明奖励（天才地宝/法宝等）");
        }

        Quest quest = new Quest();
        quest.setQuestType("personal");
        quest.setPublisher(name);
        quest.setTitle(t);
        quest.setDescription(d);
        quest.setCategory(c);
        quest.setDifficulty(diff);
        quest.setMinRealm(realm);
        quest.setMaxAccept(quota);
        quest.setRewardContribution(0L);
        quest.setRewardStones(0L);
        quest.setRewardItem(item);
        quest.setIcon(normalize(icon, "🗡️", 16));
        quest.setStatus(1);
        quest.setAcceptCount(0L);
        quest.setCreateTime(LocalDateTime.now());
        questMapper.insert(quest);
        return questMapper.selectById(quest.getId());
    }

    /**
     * 接取任务：依次校验 任务上架 → 名额未满 → 修为达标 → 未重复接取。
     * 接取成功后任务累计接取次数 +1。
     */
    @Transactional
    public Map<String, Object> accept(String username, Long questId) {
        String name = requireUsername(username);
        Quest quest = requireQuest(questId);

        // 名额校验：进行中 + 已完成的去重人数占用名额
        Long used = countUsedQuota(quest.getId());
        long quota = quest.getMaxAccept() == null ? 0L : quest.getMaxAccept();
        if (quota > 0 && used >= quota) {
            throw new IllegalArgumentException("名额已满（" + used + "/" + quota + "），等下一批悬赏吧");
        }

        // 修为门槛校验：以洞府档案境界 + 修为折算的小层次为准（支持「筑基中期」这类精确门槛）
        int needWeight = RealmTier.realmWeight(quest.getMinRealm() == null ? "炼气" : quest.getMinRealm());
        UserProfile profile = userProfileMapper.selectOne(
                new LambdaQueryWrapper<UserProfile>().eq(UserProfile::getUsername, name));
        String myRealm = profile == null || profile.getRealm() == null ? "炼气" : profile.getRealm();
        long myCultivation = profile == null || profile.getCultivation() == null ? 0L : profile.getCultivation();
        String myFull = RealmTier.fullRealm(myRealm, RealmTier.stageOf(myRealm, myCultivation));
        int myWeight = RealmTier.realmWeight(myFull);
        if (myWeight < needWeight) {
            throw new IllegalArgumentException("修为不足：此任务需 " + quest.getMinRealm() + " 以上，你当前 " + myFull);
        }

        // 重复接取校验
        Long ongoing = userQuestMapper.selectCount(
                new LambdaQueryWrapper<UserQuest>()
                        .eq(UserQuest::getUsername, name)
                        .eq(UserQuest::getQuestId, quest.getId())
                        .eq(UserQuest::getStatus, 0));
        if (ongoing != null && ongoing > 0) {
            throw new IllegalArgumentException("此任务已在手，先做完再来");
        }

        UserQuest record = new UserQuest();
        record.setUsername(name);
        record.setQuestId(quest.getId());
        record.setStatus(0);
        record.setRewardContribution(0L);
        record.setRewardStones(0L);
        record.setCreateTime(LocalDateTime.now());
        userQuestMapper.insert(record);

        questMapper.update(null, new UpdateWrapper<Quest>()
                .setSql("accept_count = accept_count + 1")
                .eq("id", quest.getId()));

        Map<String, Object> data = new LinkedHashMap<>();
        data.put("recordId", record.getId());
        data.put("questId", quest.getId());
        data.put("status", 0);
        data.put("statusText", "进行中");
        return data;
    }

    /**
     * 完成任务：按任务类型结算奖励并快照到接取记录（洞府统计联动）。
     */
    @Transactional
    public Map<String, Object> finish(String username, Long questId) {
        String name = requireUsername(username);
        Quest quest = requireQuest(questId);

        UserQuest record = userQuestMapper.selectOne(
                new LambdaQueryWrapper<UserQuest>()
                        .eq(UserQuest::getUsername, name)
                        .eq(UserQuest::getQuestId, quest.getId())
                        .eq(UserQuest::getStatus, 0)
                        .orderByDesc(UserQuest::getId)
                        .last("LIMIT 1"));
        if (record == null) {
            throw new IllegalArgumentException("尚未接取此任务，先去任务牌前领一枚任务牌");
        }

        record.setStatus(1);
        record.setRewardContribution(quest.getRewardContribution() == null ? 0L : quest.getRewardContribution());
        record.setRewardStones(quest.getRewardStones() == null ? 0L : quest.getRewardStones());
        record.setRewardItem(quest.getRewardItem());
        record.setFinishTime(LocalDateTime.now());
        userQuestMapper.updateById(record);

        Map<String, Object> data = new LinkedHashMap<>();
        data.put("recordId", record.getId());
        data.put("questId", quest.getId());
        data.put("questType", quest.getQuestType());
        data.put("rewardContribution", record.getRewardContribution());
        data.put("rewardStones", record.getRewardStones());
        data.put("rewardItem", record.getRewardItem());
        data.put("status", 1);
        data.put("statusText", "已完成");
        return data;
    }

    /** 放弃任务：进行中的记录标记为已放弃并释放名额，不计奖励。 */
    @Transactional
    public Map<String, Object> abandon(String username, Long questId) {
        String name = requireUsername(username);
        Quest quest = requireQuest(questId);

        UserQuest record = userQuestMapper.selectOne(
                new LambdaQueryWrapper<UserQuest>()
                        .eq(UserQuest::getUsername, name)
                        .eq(UserQuest::getQuestId, quest.getId())
                        .eq(UserQuest::getStatus, 0)
                        .orderByDesc(UserQuest::getId)
                        .last("LIMIT 1"));
        if (record == null) {
            throw new IllegalArgumentException("没有进行中的此任务");
        }

        record.setStatus(2);
        record.setRewardContribution(0L);
        record.setRewardStones(0L);
        record.setRewardItem(null);
        record.setFinishTime(LocalDateTime.now());
        userQuestMapper.updateById(record);

        Map<String, Object> data = new LinkedHashMap<>();
        data.put("recordId", record.getId());
        data.put("questId", quest.getId());
        data.put("status", 2);
        data.put("statusText", "已放弃");
        return data;
    }

    /**
     * 我的任务牌（洞府「我的任务」联动）：最近 50 条记录，附带任务牌信息。
     */
    public List<Map<String, Object>> myQuests(String username) {
        String name = requireUsername(username);

        List<UserQuest> records = userQuestMapper.selectList(
                new LambdaQueryWrapper<UserQuest>()
                        .eq(UserQuest::getUsername, name)
                        .orderByDesc(UserQuest::getCreateTime)
                        .orderByDesc(UserQuest::getId)
                        .last("LIMIT " + MAX_LIST));
        if (records == null || records.isEmpty()) {
            return new ArrayList<>();
        }

        // 一次查出涉及的任务牌，避免 N+1
        Set<Long> questIds = records.stream()
                .map(UserQuest::getQuestId)
                .collect(Collectors.toSet());
        Map<Long, Quest> questMap = questIds.isEmpty() ? Map.of()
                : questMapper.selectBatchIds(questIds).stream()
                        .collect(Collectors.toMap(Quest::getId, Function.identity()));

        List<Map<String, Object>> list = new ArrayList<>();
        for (UserQuest r : records) {
            Map<String, Object> item = new LinkedHashMap<>();
            item.put("id", r.getId());
            item.put("questId", r.getQuestId());
            item.put("status", r.getStatus());
            item.put("statusText", STATUS_TEXT.getOrDefault(r.getStatus(), "未知"));
            item.put("rewardContribution", r.getRewardContribution() == null ? 0L : r.getRewardContribution());
            item.put("rewardStones", r.getRewardStones() == null ? 0L : r.getRewardStones());
            item.put("rewardItem", r.getRewardItem());
            item.put("createTime", r.getCreateTime());
            item.put("finishTime", r.getFinishTime());

            Quest q = questMap.get(r.getQuestId());
            if (q != null) {
                item.put("title", q.getTitle());
                item.put("description", q.getDescription());
                item.put("icon", q.getIcon());
                item.put("category", q.getCategory());
                item.put("difficulty", q.getDifficulty());
                item.put("questType", q.getQuestType());
                item.put("publisher", q.getPublisher());
                item.put("questContribution", q.getRewardContribution());
                item.put("questStones", q.getRewardStones());
                item.put("questItem", q.getRewardItem());
            } else {
                item.put("title", "（任务牌已销毁）");
            }
            list.add(item);
        }
        return list;
    }

    /** 占用名额的去重人数（进行中 + 已完成，放弃不算） */
    private Long countUsedQuota(Long questId) {
        List<UserQuest> rows = userQuestMapper.selectList(
                new LambdaQueryWrapper<UserQuest>()
                        .select(UserQuest::getUsername)
                        .eq(UserQuest::getQuestId, questId)
                        .in(UserQuest::getStatus, 0, 1));
        long cnt = rows == null ? 0L
                : rows.stream().map(UserQuest::getUsername).filter(u -> u != null).distinct().count();
        return cnt;
    }

    /** 给列表任务填充名额占用情况 */
    private void fillQuota(List<Quest> quests) {
        if (quests == null || quests.isEmpty()) {
            return;
        }
        Set<Long> ids = quests.stream().map(Quest::getId).collect(Collectors.toSet());
        List<UserQuest> used = userQuestMapper.selectList(
                new LambdaQueryWrapper<UserQuest>()
                        .in(UserQuest::getQuestId, ids)
                        .in(UserQuest::getStatus, 0, 1));
        Map<Long, Long> usedMap = used.stream().collect(Collectors.groupingBy(
                UserQuest::getQuestId, Collectors.mapping(
                        UserQuest::getUsername, Collectors.collectingAndThen(
                                Collectors.toSet(), s -> (long) s.size()))));
        for (Quest q : quests) {
            long u = usedMap.getOrDefault(q.getId(), 0L);
            long quota = q.getMaxAccept() == null ? 0L : q.getMaxAccept();
            q.setCurrentAcceptors(u);
            q.setFull(quota > 0 && u >= quota);
        }
    }

    private Quest requireQuest(Long questId) {
        if (questId == null) {
            throw new IllegalArgumentException("任务 id 不能为空");
        }
        Quest quest = questMapper.selectById(questId);
        if (quest == null || quest.getStatus() == null || quest.getStatus() != 1) {
            throw new IllegalArgumentException("任务不存在或已下架");
        }
        return quest;
    }

    private String requireUsername(String username) {
        if (username == null || username.isBlank()) {
            throw new IllegalArgumentException("用户名不能为空");
        }
        return username.trim();
    }

    /** 去空白 + 截断；blank 时返回 fallback（可为 null） */
    private String normalize(String s, String fallback, int max) {
        if (s == null) {
            return fallback;
        }
        String v = s.trim();
        if (v.isEmpty()) {
            return fallback;
        }
        return v.length() > max ? v.substring(0, max) : v;
    }
}
