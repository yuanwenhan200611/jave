package com.fenglin.springboottest.service;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import com.fenglin.springboottest.entity.CultivationLog;
import com.fenglin.springboottest.entity.ForumIncome;
import com.fenglin.springboottest.entity.ForumPost;
import com.fenglin.springboottest.entity.MarketOrder;
import com.fenglin.springboottest.entity.SearchLog;
import com.fenglin.springboottest.entity.User;
import com.fenglin.springboottest.entity.UserProfile;
import com.fenglin.springboottest.entity.UserQuest;
import com.fenglin.springboottest.entity.UserSecret;
import com.fenglin.springboottest.entity.UserSkill;
import com.fenglin.springboottest.mapper.CultivationLogMapper;
import com.fenglin.springboottest.mapper.ForumIncomeMapper;
import com.fenglin.springboottest.mapper.ForumPostMapper;
import com.fenglin.springboottest.mapper.MarketOrderMapper;
import com.fenglin.springboottest.mapper.SearchLogMapper;
import com.fenglin.springboottest.mapper.UserMapper;
import com.fenglin.springboottest.mapper.UserProfileMapper;
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
import java.util.Set;

/**
 * 洞府（个人页）服务：档案读取 / 保存，以及跨模块联动数据聚合。
 *
 * 联动关系：
 *   · 论道 forum_post —— 以 author = username 统计发帖数、获赞数、我的帖子列表
 *   · 首页 search_log —— 以 username 统计搜索次数、最近搜索足迹
 *   · 用户 user       —— 入宗时间（注册时间）
 */
@Service
@RequiredArgsConstructor
public class ProfileService {

    private static final Set<String> REALMS = Set.of(
            "炼气", "筑基", "金丹", "元婴", "化神", "炼虚", "合体", "大乘", "渡劫", "魔尊");
    private static final Set<String> HALLS = Set.of(
            "主殿", "血煞堂", "幽冥堂", "千机堂", "执法堂", "炼丹堂");
    private static final int MAX_NICKNAME = 20;
    private static final int MAX_BIO = 100;
    private static final int MAX_ICON = 8;
    private static final int MAX_LIST = 20;

    private final UserMapper userMapper;
    private final UserProfileMapper userProfileMapper;
    private final ForumPostMapper forumPostMapper;
    private final ForumIncomeMapper forumIncomeMapper;
    private final SearchLogMapper searchLogMapper;
    private final UserQuestMapper userQuestMapper;
    private final UserSkillMapper userSkillMapper;
    private final UserSecretMapper userSecretMapper;
    private final CultivationLogMapper cultivationLogMapper;
    private final MarketOrderMapper marketOrderMapper;

    /**
     * 读取个人档案（不存在则自动创建默认档案）+ 跨模块统计。
     * 返回：{ profile, user:{ username, createdAt }, stats:{ postCount, likeCount, searchCount } }
     */
    public Map<String, Object> getProfile(String username) {
        String name = requireUsername(username);

        User user = userMapper.selectOne(
                new LambdaQueryWrapper<User>().eq(User::getUsername, name));
        if (user == null) {
            throw new IllegalArgumentException("用户不存在");
        }

        UserProfile profile = userProfileMapper.selectOne(
                new LambdaQueryWrapper<UserProfile>().eq(UserProfile::getUsername, name));
        if (profile == null) {
            profile = createDefaultProfile(name);
        }

        // 跨模块统计：论道发帖 / 获赞 / 首页搜索
        Long postCount = forumPostMapper.selectCount(
                new LambdaQueryWrapper<ForumPost>().eq(ForumPost::getAuthor, name)
                        .eq(ForumPost::getStatus, 1));
        List<ForumPost> myPosts = forumPostMapper.selectList(
                new LambdaQueryWrapper<ForumPost>().eq(ForumPost::getAuthor, name)
                        .eq(ForumPost::getStatus, 1)
                        .orderByDesc(ForumPost::getCreateTime)
                        .orderByDesc(ForumPost::getId)
                        .last("LIMIT " + MAX_LIST));
        long likeCount = myPosts.stream()
                .mapToLong(p -> p.getLikes() == null ? 0L : p.getLikes())
                .sum();

        Long searchCount = searchLogMapper.selectCount(
                new LambdaQueryWrapper<SearchLog>().eq(SearchLog::getUsername, name));

        // 任务阁联动：进行中任务 / 已完成任务 / 累计贡献值与灵石
        Long questActive = userQuestMapper.selectCount(
                new LambdaQueryWrapper<UserQuest>().eq(UserQuest::getUsername, name)
                        .eq(UserQuest::getStatus, 0));
        Long questDone = userQuestMapper.selectCount(
                new LambdaQueryWrapper<UserQuest>().eq(UserQuest::getUsername, name)
                        .eq(UserQuest::getStatus, 1));
        List<UserQuest> doneQuests = userQuestMapper.selectList(
                new LambdaQueryWrapper<UserQuest>().eq(UserQuest::getUsername, name)
                        .eq(UserQuest::getStatus, 1));
        long contributionTotal = doneQuests.stream()
                .mapToLong(q -> q.getRewardContribution() == null ? 0L : q.getRewardContribution())
                .sum();
        long stonesTotal = doneQuests.stream()
                .mapToLong(q -> q.getRewardStones() == null ? 0L : q.getRewardStones())
                .sum();

        // 血辩台联动：香火分成（帖主收益）计入累计所得
        contributionTotal += forumIncomeSum(name, "contribution");
        stonesTotal += forumIncomeSum(name, "stones");

        // 功法阁联动：已参悟功法 / 参悟消耗贡献值 / 可用贡献值（累计所得 - 参悟所耗 - 魔功殿血祭所耗 - 秘境破界所耗）
        List<UserSkill> mySkills = userSkillMapper.selectList(
                new LambdaQueryWrapper<UserSkill>().eq(UserSkill::getUsername, name));
        long skillSpent = mySkills.stream()
                .mapToLong(s -> s.getCost() == null ? 0L : s.getCost())
                .sum();

        // 秘境联动：破界次数 / 破界消耗贡献值（引路费 + 门票）；表未建时容错为 0，洞府照常打开
        List<UserSecret> mySecrets = safeSecrets(name);
        long secretSpent = mySecrets.stream()
                .mapToLong(s -> s.getCost() == null ? 0L : s.getCost())
                .sum();

        // 魔功殿联动：修炼次数 / 修炼所得修为 / 修炼消耗的灵石与贡献值
        List<CultivationLog> cultivationLogs = cultivationLogMapper.selectList(
                new LambdaQueryWrapper<CultivationLog>().eq(CultivationLog::getUsername, name));
        long cultivationGain = cultivationLogs.stream()
                .mapToLong(l -> l.getDelta() == null ? 0L : Math.max(0, l.getDelta()))
                .sum();
        long cultStonesSpent = cultivationLogs.stream()
                .mapToLong(l -> l.getCostStones() == null ? 0L : l.getCostStones())
                .sum();
        long cultContributionSpent = cultivationLogs.stream()
                .mapToLong(l -> l.getCostContribution() == null ? 0L : l.getCostContribution())
                .sum();

        // 坊市联动：交易笔数 / 买入所耗灵石 / 卖出所得灵石（表未建时容错为 0）
        List<MarketOrder> marketOrders = safeMarketOrders(name);
        long marketSpent = marketOrders.stream()
                .filter(o -> "buy".equals(o.getTradeType()))
                .mapToLong(o -> o.getPrice() == null ? 0L : o.getPrice())
                .sum();
        long marketEarned = marketOrders.stream()
                .filter(o -> "sell".equals(o.getTradeType()))
                .mapToLong(o -> o.getPrice() == null ? 0L : o.getPrice())
                .sum();

        Map<String, Object> stats = new HashMap<>();
        stats.put("postCount", postCount == null ? 0L : postCount);
        stats.put("likeCount", likeCount);
        stats.put("searchCount", searchCount == null ? 0L : searchCount);
        stats.put("questActive", questActive == null ? 0L : questActive);
        stats.put("questDone", questDone == null ? 0L : questDone);
        stats.put("contributionTotal", contributionTotal);
        stats.put("stonesTotal", stonesTotal);
        stats.put("skillCount", mySkills.size());
        stats.put("skillSpent", skillSpent);
        stats.put("secretCount", mySecrets.size());
        stats.put("secretSpent", secretSpent);
        stats.put("cultivationPractice", cultivationLogs.size());
        stats.put("cultivationGain", cultivationGain);
        stats.put("cultivation", profile.getCultivation() == null ? 0L : profile.getCultivation());
        stats.put("stonesSpent", cultStonesSpent);
        stats.put("stonesAvailable", stonesTotal - cultStonesSpent);
        stats.put("marketTradeCount", marketOrders.size());
        stats.put("marketSpent", marketSpent);
        stats.put("marketEarned", marketEarned);
        stats.put("contributionAvailable", contributionTotal - skillSpent - secretSpent - cultContributionSpent);

        Map<String, Object> userBrief = new HashMap<>();
        userBrief.put("username", user.getUsername());
        userBrief.put("createdAt", user.getCreateTime());

        Map<String, Object> data = new LinkedHashMap<>();
        data.put("profile", profile);
        data.put("user", userBrief);
        data.put("stats", stats);
        return data;
    }

    /**
     * 保存个人档案（upsert）：道号 / 头像 / 境界 / 堂口 / 签名。
     */
    public UserProfile updateProfile(String username, String nickname, String icon,
                                     String realm, String hall, String bio) {
        String name = requireUsername(username);

        UserProfile profile = userProfileMapper.selectOne(
                new LambdaQueryWrapper<UserProfile>().eq(UserProfile::getUsername, name));
        if (profile == null) {
            profile = createDefaultProfile(name);
        }

        String nick = normalize(nickname, null, MAX_NICKNAME);
        if (nick != null) {
            profile.setNickname(nick);
        }
        String ic = normalize(icon, null, MAX_ICON);
        if (ic != null) {
            profile.setIcon(ic);
        }
        String r = normalize(realm, null, 10);
        if (r != null) {
            if (!REALMS.contains(r)) {
                throw new IllegalArgumentException("境界不在十大境界之内");
            }
            profile.setRealm(r);
        }
        String h = normalize(hall, null, 10);
        if (h != null) {
            if (!HALLS.contains(h)) {
                throw new IllegalArgumentException("堂口不存在");
            }
            profile.setHall(h);
        }
        String b = normalize(bio, "", MAX_BIO);
        if (b != null) {
            profile.setBio(b);
        }

        userProfileMapper.updateById(profile);
        // 回读，拿到数据库 ON UPDATE 维护的 update_time
        return userProfileMapper.selectById(profile.getId());
    }

    /**
     * 我的帖子（论道联动）：最近 20 条，时间倒序。
     */
    public List<ForumPost> myPosts(String username) {
        String name = requireUsername(username);
        List<ForumPost> list = forumPostMapper.selectList(
                new LambdaQueryWrapper<ForumPost>().eq(ForumPost::getAuthor, name)
                        .eq(ForumPost::getStatus, 1)
                        .orderByDesc(ForumPost::getCreateTime)
                        .orderByDesc(ForumPost::getId)
                        .last("LIMIT " + MAX_LIST));
        return list == null ? new ArrayList<>() : list;
    }

    /**
     * 搜索足迹（首页联动）：最近 20 条搜索记录，时间倒序。
     */
    public List<SearchLog> mySearches(String username) {
        String name = requireUsername(username);
        List<SearchLog> list = searchLogMapper.selectList(
                new LambdaQueryWrapper<SearchLog>().eq(SearchLog::getUsername, name)
                        .orderByDesc(SearchLog::getCreateTime)
                        .orderByDesc(SearchLog::getId)
                        .last("LIMIT " + MAX_LIST));
        return list == null ? new ArrayList<>() : list;
    }

    /**
     * 秘境破界记录查询（容错）：user_secret 表尚未创建（未跑 ensure_db.sql）时
     * 兜底为空列表，保证洞府接口不因新表缺失而整体挂掉。
     */
    private List<UserSecret> safeSecrets(String name) {
        try {
            return userSecretMapper.selectList(
                    new LambdaQueryWrapper<UserSecret>().eq(UserSecret::getUsername, name));
        } catch (Exception e) {
            return new ArrayList<>();
        }
    }

    /** 坊市交易手札（表未建时容错为空，不让洞府挂掉） */
    private List<MarketOrder> safeMarketOrders(String name) {
        try {
            List<MarketOrder> list = marketOrderMapper.selectList(
                    new LambdaQueryWrapper<MarketOrder>().eq(MarketOrder::getUsername, name));
            return list == null ? new ArrayList<>() : list;
        } catch (Exception e) {
            return new ArrayList<>();
        }
    }

    /** 血辩台收益合计（forum_income 表，column 限 stones/contribution） */
    private long forumIncomeSum(String username, String column) {
        Map<String, Object> row = forumIncomeMapper.selectMaps(
                new QueryWrapper<ForumIncome>()
                        .select("IFNULL(SUM(" + column + "), 0) AS total")
                        .eq("username", username))
                .stream().findFirst().orElse(null);
        if (row == null || row.get("total") == null) {
            return 0L;
        }
        return Long.parseLong(String.valueOf(row.get("total")));
    }

    /** 首次进入洞府：生成一份默认档案 */
    private UserProfile createDefaultProfile(String username) {
        UserProfile profile = new UserProfile();
        profile.setUsername(username);
        profile.setNickname(username);
        // 单个码位的 emoji，避免组合 emoji（如 🧑‍🦲）在部分字体下拆成两个字形溢出头像框
        profile.setIcon("🧙");
        profile.setRealm("炼气");
        profile.setHall("血煞堂");
        profile.setBio("初入魔宗，道心未定。");
        profile.setCultivation(0L);
        userProfileMapper.insert(profile);
        return userProfileMapper.selectById(profile.getId());
    }

    private String requireUsername(String username) {
        if (username == null || username.isBlank()) {
            throw new IllegalArgumentException("用户名不能为空");
        }
        return username.trim();
    }

    /** 去空白 + 截断；null 原样返回 null（表示不修改该字段） */
    private String normalize(String s, String emptyFallback, int max) {
        if (s == null) {
            return null;
        }
        String v = s.trim();
        if (v.isEmpty()) {
            return emptyFallback;
        }
        return v.length() > max ? v.substring(0, max) : v;
    }
}
