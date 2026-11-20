package com.fenglin.springboottest.service;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.fenglin.springboottest.entity.ContentItem;
import com.fenglin.springboottest.entity.ForumIncome;
import com.fenglin.springboottest.entity.UserQuest;
import com.fenglin.springboottest.entity.UserSecret;
import com.fenglin.springboottest.entity.UserSkill;
import com.fenglin.springboottest.mapper.ContentItemMapper;
import com.fenglin.springboottest.mapper.ForumIncomeMapper;
import com.fenglin.springboottest.mapper.UserQuestMapper;
import com.fenglin.springboottest.mapper.UserSecretMapper;
import com.fenglin.springboottest.mapper.UserSkillMapper;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

/**
 * 功法阁·参悟服务（贡献值经济闭环的消耗端）。
 *
 * 经济规则：
 *   累计贡献值 = user_quest（status=1 已完成任务）reward_contribution 之和
 *   已耗贡献值 = user_skill.cost 之和
 *   可用贡献值 = 累计 - 已耗
 *
 * 参悟规则：
 *   · 仅功法类条目（required_contribution > 0）可参悟，其余条目免费浏览
 *   · 功法定价按品阶高深程度（天阶 > 地阶 > 玄阶 > 黄阶）
 *   · 可用贡献值不足则拒绝；同一功法每人只可参悟一次
 */
@Service
@RequiredArgsConstructor
public class SkillService {

    private static final int MAX_LIST = 20;

    private final ContentItemMapper contentItemMapper;
    private final UserQuestMapper userQuestMapper;
    private final UserSkillMapper userSkillMapper;
    private final UserSecretMapper userSecretMapper;
    private final ForumIncomeMapper forumIncomeMapper;

    /**
     * 参悟状态总览：{ contributionTotal, skillSpent, contributionAvailable,
     *               skillCount, learnedIds:[], learned:[] }
     * 供功法阁页面渲染按钮状态与余额，洞府统计亦可复用同口径。
     */
    public Map<String, Object> status(String username) {
        String name = requireUsername(username);
        Map<String, Object> data = new LinkedHashMap<>();
        data.putAll(contributionBook(name));
        List<UserSkill> learned = mySkills(name);
        data.put("skillCount", learned.size());
        data.put("learnedIds", learned.stream().map(UserSkill::getItemId).collect(Collectors.toList()));
        data.put("learned", learned);
        return data;
    }

    /**
     * 参悟（习得）功法：扣减可用贡献值（落 user_skill 记录即完成扣减）。
     * 返回最新一条参悟记录。
     */
    public UserSkill learn(String username, Long itemId) {
        String name = requireUsername(username);
        if (itemId == null || itemId < 1) {
            throw new IllegalArgumentException("功法编号不合法");
        }

        ContentItem item = contentItemMapper.selectById(itemId);
        if (item == null) {
            throw new IllegalArgumentException("功法不存在或已下架");
        }
        long cost = item.getRequiredContribution() == null ? 0L : item.getRequiredContribution();
        if (cost <= 0) {
            throw new IllegalArgumentException("此条目并非功法，无需参悟");
        }

        Long already = userSkillMapper.selectCount(
                new LambdaQueryWrapper<UserSkill>().eq(UserSkill::getUsername, name)
                        .eq(UserSkill::getItemId, itemId));
        if (already != null && already > 0) {
            throw new IllegalArgumentException("此功法你已参悟，不必重复破费");
        }

        long available = availableContribution(name);
        if (available < cost) {
            throw new IllegalArgumentException("贡献值不足：参悟「" + item.getTitle()
                    + "」需 " + cost + "，你当前可用 " + available
                    + "。去任务阁交差挣贡献值。");
        }

        UserSkill record = new UserSkill();
        record.setUsername(name);
        record.setItemId(itemId);
        record.setCost(cost);
        record.setTitle(item.getTitle());
        record.setGrade(item.getGrade());
        record.setIcon(item.getIcon());
        userSkillMapper.insert(record);
        return userSkillMapper.selectById(record.getId());
    }

    /**
     * 我的已参悟功法（洞府联动）：最近 20 条，时间倒序。
     */
    public List<UserSkill> mySkills(String username) {
        String name = requireUsername(username);
        List<UserSkill> list = userSkillMapper.selectList(
                new LambdaQueryWrapper<UserSkill>().eq(UserSkill::getUsername, name)
                        .orderByDesc(UserSkill::getCreateTime)
                        .orderByDesc(UserSkill::getId)
                        .last("LIMIT " + MAX_LIST));
        return list == null ? new ArrayList<>() : list;
    }

    /** 贡献值账本：{ contributionTotal, skillSpent, secretSpent, contributionAvailable } */
    public Map<String, Object> contributionBook(String name) {
        List<UserQuest> doneQuests = userQuestMapper.selectList(
                new LambdaQueryWrapper<UserQuest>().eq(UserQuest::getUsername, name)
                        .eq(UserQuest::getStatus, 1));
        long contributionTotal = doneQuests.stream()
                .mapToLong(q -> q.getRewardContribution() == null ? 0L : q.getRewardContribution())
                .sum();

        // 血辩台香火分成 + 秘境探索奖励入账（forum_income，source 含 incense/secret）
        contributionTotal += forumIncomeSum(name, "contribution");

        List<UserSkill> skills = userSkillMapper.selectList(
                new LambdaQueryWrapper<UserSkill>().eq(UserSkill::getUsername, name));
        long skillSpent = skills.stream()
                .mapToLong(s -> s.getCost() == null ? 0L : s.getCost())
                .sum();

        // 秘境破界同样从同一本贡献值账上扣（功法 + 秘境共用可用额度）；表未建时容错为 0
        long secretSpent;
        try {
            List<UserSecret> secrets = userSecretMapper.selectList(
                    new LambdaQueryWrapper<UserSecret>().eq(UserSecret::getUsername, name));
            secretSpent = secrets.stream()
                    .mapToLong(s -> s.getCost() == null ? 0L : s.getCost())
                    .sum();
        } catch (Exception e) {
            secretSpent = 0L;
        }

        Map<String, Object> book = new HashMap<>();
        book.put("contributionTotal", contributionTotal);
        book.put("skillSpent", skillSpent);
        book.put("secretSpent", secretSpent);
        book.put("contributionAvailable", contributionTotal - skillSpent - secretSpent);
        return book;
    }

    /** forum_income 某列合计（秘境奖励 / 香火分成入账） */
    private long forumIncomeSum(String name, String column) {
        Map<String, Object> row = forumIncomeMapper.selectMaps(
                new com.baomidou.mybatisplus.core.conditions.query.QueryWrapper<ForumIncome>()
                        .select("IFNULL(SUM(" + column + "), 0) AS total")
                        .eq("username", name))
                .stream().findFirst().orElse(null);
        if (row == null || row.get("total") == null) {
            return 0L;
        }
        return Long.parseLong(String.valueOf(row.get("total")));
    }

    private long availableContribution(String name) {
        Object v = contributionBook(name).get("contributionAvailable");
        return v == null ? 0L : ((Number) v).longValue();
    }

    private String requireUsername(String username) {
        if (username == null || username.isBlank()) {
            throw new IllegalArgumentException("用户名不能为空");
        }
        return username.trim();
    }
}
