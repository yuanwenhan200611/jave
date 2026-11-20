package com.fenglin.springboottest.service;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.core.conditions.update.UpdateWrapper;
import com.fenglin.springboottest.entity.Category;
import com.fenglin.springboottest.entity.ContentItem;
import com.fenglin.springboottest.entity.ForumIncome;
import com.fenglin.springboottest.entity.SecretReward;
import com.fenglin.springboottest.entity.UserSecret;
import com.fenglin.springboottest.entity.UserSkill;
import com.fenglin.springboottest.mapper.CategoryMapper;
import com.fenglin.springboottest.mapper.ContentItemMapper;
import com.fenglin.springboottest.mapper.ForumIncomeMapper;
import com.fenglin.springboottest.mapper.SecretRewardMapper;
import com.fenglin.springboottest.mapper.UserSecretMapper;
import com.fenglin.springboottest.mapper.UserSkillMapper;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.concurrent.ThreadLocalRandom;
import java.util.stream.Collectors;

/**
 * 秘境·破界服务（贡献值经济闭环第二消耗端 + 探索奖励发放端）。
 *
 * 经济规则（与功法阁共用同一本贡献值账）：
 *   累计贡献值 = user_quest（status=1）+ forum_income（含秘境奖励入账）
 *   已耗贡献值 = user_skill.cost（参悟）+ user_secret.cost（破界）+ cultivation_log 血祭/论道所耗
 *   可用贡献值 = 累计 - 已耗
 *
 * 进入规则：
 *   · 指定秘境：门票 = content_item.required_contribution（按品阶定价）
 *   · 随机探秘：固定「天机引路费」ROAM_FEE
 *   · 每人每秘境只可进入一次，进入后免费重游（已开辟）
 *
 * 探索奖励（不固定，按秘境类型 × 品阶掷骰）：
 *   幻境秘境：道心通明（修为暴涨）/ 天赋神通 / 幻境功法（免贡习得）
 *   上古秘境：残篇上古功法 / 法宝 / 极小概率完整上古功法或完整法宝
 *   普通秘境：法宝 / 功法
 *   所有秘境：灵石 / 贡献值 / 修为（保底，随品阶放大）
 */
@Service
@RequiredArgsConstructor
public class SecretService {

    private static final int MAX_LIST = 20;

    /** 随机探秘的「天机引路费」 */
    public static final long ROAM_FEE = 20;

    private final ContentItemMapper contentItemMapper;
    private final CategoryMapper categoryMapper;
    private final UserSecretMapper userSecretMapper;
    private final UserSkillMapper userSkillMapper;
    private final SecretRewardMapper secretRewardMapper;
    private final ForumIncomeMapper forumIncomeMapper;
    private final SkillService skillService;
    private final SectService sectService;
    private final CultivationService cultivationService;
    private final HomeService homeService;

    // ==========================================================
    // 一、状态与进入
    // ==========================================================

    /**
     * 秘境状态总览：{ contributionTotal, skillSpent, secretSpent, contributionAvailable,
     *               enteredIds:[], entered:[], recentRewards:[] }
     */
    public Map<String, Object> status(String username) {
        String name = requireUsername(username);
        Map<String, Object> data = new LinkedHashMap<>();
        data.putAll(skillService.contributionBook(name));
        List<UserSecret> entered = mySecrets(name);
        data.put("secretCount", entered.size());
        data.put("enteredIds", entered.stream().map(UserSecret::getItemId).collect(Collectors.toList()));
        data.put("entered", entered);
        data.put("recentRewards", recentRewards(name, 10));
        return data;
    }

    /**
     * 破界进入指定秘境：门票扣减可用贡献值，首入掷探索奖励。
     * @return { record: UserSecret, rewards: [...] }
     */
    @Transactional
    public Map<String, Object> enter(String username, Long itemId) {
        String name = requireUsername(username);
        if (itemId == null || itemId < 1) {
            throw new IllegalArgumentException("秘境编号不合法");
        }

        ContentItem item = contentItemMapper.selectById(itemId);
        if (item == null) {
            throw new IllegalArgumentException("秘境不存在或已封闭");
        }
        long ticket = item.getRequiredContribution() == null ? 0L : item.getRequiredContribution();

        Long already = userSecretMapper.selectCount(
                new LambdaQueryWrapper<UserSecret>().eq(UserSecret::getUsername, name)
                        .eq(UserSecret::getItemId, itemId));
        if (already != null && already > 0) {
            throw new IllegalArgumentException("此秘境你已开辟过，可免费重游");
        }

        long available = availableContribution(name);
        if (ticket > available) {
            throw new IllegalArgumentException("贡献值不足：破界「" + item.getTitle()
                    + "」需门票 " + ticket + "，你当前可用 " + available
                    + "。去任务阁交差挣贡献值。");
        }

        UserSecret record = new UserSecret();
        record.setUsername(name);
        record.setItemId(itemId);
        record.setCost(Math.max(ticket, 0L));
        record.setTitle(item.getTitle());
        record.setGrade(item.getGrade());
        record.setIcon(item.getIcon());
        userSecretMapper.insert(record);
        record = userSecretMapper.selectById(record.getId());

        // 首入必有收获：至少掷出基础 loot
        List<Map<String, Object>> rewards = rollRewards(name, item, true);

        Map<String, Object> data = new LinkedHashMap<>();
        data.put("record", record);
        data.put("rewards", rewards);
        return data;
    }

    /**
     * 随机探秘（扣费版）：先收「天机引路费」，随机挑一个秘境，
     * 记为一次进入（首入收引路费，已开辟免费重游），并掷探索奖励。
     */
    @Transactional
    public Map<String, Object> roam(String username) {
        String name = requireUsername(username);

        ContentItem item = sectService.pickSecretItem();
        if (item == null) {
            throw new IllegalArgumentException("秘境尚未收录任何洞天");
        }

        Long already = userSecretMapper.selectCount(
                new LambdaQueryWrapper<UserSecret>().eq(UserSecret::getUsername, name)
                        .eq(UserSecret::getItemId, item.getId()));

        // 引路费：首入此秘境收固定引路费；已开辟过的秘境随机到则免费重游
        boolean firstEntry = (already == null || already == 0);
        long fee = firstEntry ? ROAM_FEE : 0L;
        long available = availableContribution(name);
        if (fee > available) {
            throw new IllegalArgumentException("贡献值不足：天机引路需 " + fee
                    + "，你当前可用 " + available + "。去任务阁交差挣贡献值。");
        }

        long viewCount = (item.getViewCount() == null ? 0L : item.getViewCount()) + 1;
        contentItemMapper.update(null, new UpdateWrapper<ContentItem>()
                .setSql("view_count = view_count + 1")
                .eq("id", item.getId()));

        if (fee > 0) {
            UserSecret record = new UserSecret();
            record.setUsername(name);
            record.setItemId(item.getId());
            record.setCost(fee);
            record.setTitle(item.getTitle());
            record.setGrade(item.getGrade());
            record.setIcon(item.getIcon());
            userSecretMapper.insert(record);
        }

        List<Map<String, Object>> rewards = rollRewards(name, item, firstEntry);

        Map<String, Object> data = new LinkedHashMap<>();
        data.put("id", item.getId());
        data.put("title", item.getTitle());
        data.put("description", item.getDescription());
        data.put("grade", item.getGrade());
        data.put("icon", item.getIcon());
        data.put("viewCount", viewCount);
        data.put("encounter", sectService.encounterFor(item));
        data.put("fee", fee);
        data.put("rewards", rewards);
        return data;
    }

    /**
     * 我的已开辟秘境（洞府联动可复用）：最近 20 条，时间倒序。
     */
    public List<UserSecret> mySecrets(String username) {
        String name = requireUsername(username);
        List<UserSecret> list = userSecretMapper.selectList(
                new LambdaQueryWrapper<UserSecret>().eq(UserSecret::getUsername, name)
                        .orderByDesc(UserSecret::getCreateTime)
                        .orderByDesc(UserSecret::getId)
                        .last("LIMIT " + MAX_LIST));
        return list == null ? new ArrayList<>() : list;
    }

    /** 最近探索奖励（洞府「奇遇收获」联动可复用） */
    public List<SecretReward> recentRewards(String username, int limit) {
        String name = requireUsername(username);
        List<SecretReward> list = secretRewardMapper.selectList(
                new LambdaQueryWrapper<SecretReward>().eq(SecretReward::getUsername, name)
                        .orderByDesc(SecretReward::getCreateTime)
                        .orderByDesc(SecretReward::getId)
                        .last("LIMIT " + Math.min(Math.max(limit, 1), 50)));
        return list == null ? new ArrayList<>() : list;
    }

    /**
     * 储物空间（洞府联动）：历次探索获得的法宝 / 上古残篇 / 天赋神通，
     * 时间倒序，最多回看 100 件。储物袋无上限，获得即永久收录。
     */
    public List<SecretReward> storage(String username) {
        String name = requireUsername(username);
        try {
            List<SecretReward> list = secretRewardMapper.selectList(
                    new LambdaQueryWrapper<SecretReward>()
                            .eq(SecretReward::getUsername, name)
                            .in(SecretReward::getRewardType, "artifact", "fragment", "divine_ability")
                            .orderByDesc(SecretReward::getCreateTime)
                            .orderByDesc(SecretReward::getId)
                            .last("LIMIT 100"));
            return list == null ? new ArrayList<>() : list;
        } catch (Exception e) {
            // 储物阵法尚未开辟（secret_reward 表未建）时兜底为空，不让洞府挂掉
            return new ArrayList<>();
        }
    }

    /** 储物空间类型 → 展示图标 */
    private static final Map<String, String> STORAGE_ICONS = Map.of(
            "artifact", "🏺",
            "fragment", "📜",
            "divine_ability", "✨");

    /** 储物空间类型 → 中文标签 */
    private static final Map<String, String> STORAGE_LABELS = Map.of(
            "artifact", "法宝",
            "fragment", "上古残篇",
            "divine_ability", "天赋神通");

    /** 储物空间卡片视图：在奖励记录基础上补图标 / 类型标签，供洞府直接渲染 */
    public List<Map<String, Object>> storageCards(String username) {
        List<SecretReward> items = storage(username);
        List<Map<String, Object>> cards = new ArrayList<>();
        for (SecretReward r : items) {
            Map<String, Object> m = new LinkedHashMap<>();
            m.put("id", r.getId());
            m.put("rewardType", r.getRewardType());
            m.put("typeLabel", STORAGE_LABELS.getOrDefault(r.getRewardType(), "奇物"));
            m.put("icon", STORAGE_ICONS.getOrDefault(r.getRewardType(), "📦"));
            m.put("name", r.getRewardName());
            m.put("rarity", r.getRarity() == null ? "common" : r.getRarity());
            m.put("detail", r.getDetail());
            m.put("createTime", r.getCreateTime());
            cards.add(m);
        }
        return cards;
    }

    // ==========================================================
    // 二、探索奖励（按秘境类型 × 品阶掷骰，奖励不固定）
    // ==========================================================

    /** 法宝名池 */
    private static final String[] ARTIFACT_COMMON = {
            "噬魂幡", "血煞铃", "幽冥骨爪", "玄阴镜", "赤炎珠", "枯荣笛"
    };
    private static final String[] ARTIFACT_LEGEND = {
            "九幽冥王鼎", "太阴炼形图", "万魂血幡", "镇魔玄塔"
    };
    private static final String[] DIVINE_ABILITIES = {
            "鬼目透视", "血遁千里", "噬灵之瞳", "阴风耳", "腐骨毒息"
    };

    /**
     * 掷探索奖励。
     *
     * @param firstEntry 首入（必得基础 loot）；重游只掷奇遇
     * @return 奖励列表，元素 { type, name, rarity, amount, detail, icon }
     */
    private List<Map<String, Object>> rollRewards(String username, ContentItem realm, boolean firstEntry) {
        ThreadLocalRandom rnd = ThreadLocalRandom.current();
        List<Map<String, Object>> rewards = new ArrayList<>();

        // 低端「无主之境」（门票 0）：不设门槛也没人守宝贝，只掉垃圾，无奇遇无传说
        long ticket = realm.getRequiredContribution() == null ? 0L : realm.getRequiredContribution();
        if (ticket <= 0) {
            return rollTrashLoot(username, realm, firstEntry);
        }

        String realmType = realmTypeOf(realm);
        int mult = gradeMultiplier(realm.getGrade());

        // 1. 基础 loot：灵石 / 贡献值（首入必得其一，重游 30% 也给）
        if (firstEntry || rnd.nextInt(100) < 30) {
            boolean stones = rnd.nextInt(100) < 60;
            long amount = stones ? rnd.nextLong(50, 301) * mult : rnd.nextLong(30, 151) * mult;
            grantCurrency(username, realm, stones ? "stones" : "contribution", amount,
                    stones ? "stones" : "contribution");
            rewards.add(reward("stones", stones ? "灵石" : "贡献值",
                    "stones", stones ? "灵石" : "贡献值",
                    mult >= 3 ? "rare" : "common", amount,
                    stones ? "你在秘境深处摸出 " + amount + " 块灵石，成色不错。"
                           : "秘境遗落的供奉盒里有 " + amount + " 贡献值，宗门认账。"));
        }

        // 2. 修为收获（55%）
        if (rnd.nextInt(100) < 55) {
            long amount = rnd.nextLong(200, 601) * mult;
            grantCultivation(username, realm, amount,
                    "秘境魔气驳杂却精纯，你就地吞吐数个周天，修为 +" + amount + "。");
            rewards.add(reward("cultivation", "修为", "cultivation", "修为",
                    "common", amount, "就地吞吐秘境魔气，修为 +" + amount + "。"));
        }

        // 3. 奇遇奖励（普通 25%，幻境/上古 45%）
        int rareChance = "normal".equals(realmType) ? 25 : 45;
        if (rnd.nextInt(100) < rareChance) {
            rewards.addAll(rollEncounter(username, realm, realmType, mult));
        }

        // 4. 传说级大奖（上古秘境独有，6%）
        if ("ancient".equals(realmType) && rnd.nextInt(100) < 6) {
            if (rnd.nextBoolean()) {
                Map<String, Object> tech = grantTechnique(username, realm, "legendary");
                if (tech != null) {
                    rewards.add(tech);
                }
            } else {
                String artifact = ARTIFACT_LEGEND[rnd.nextInt(ARTIFACT_LEGEND.length)];
                rewards.add(saveReward(username, realm, "artifact", artifact, "legendary", 0L,
                        "秘境最深处，" + artifact + "自鸣认主！此等造化，宗门长老听了都要红眼。"));
            }
        }

        if (rewards.isEmpty()) {
            // 兜底：绝不让弟子空手而归
            long amount = rnd.nextLong(20, 81) * mult;
            grantCurrency(username, realm, "contribution", amount, "contribution");
            rewards.add(reward("contribution", "贡献值", "contribution", "贡献值",
                    "common", amount, "秘境只遗下一点残渣，但也值 " + amount + " 贡献值。"));
        }
        return rewards;
    }

    /**
     * 低端「无主之境」的寒酸收获：只掉零碎灵石/贡献值，偶尔一点残渣修为，
     * 没有法宝、没有功法、没有奇遇——门槛都没设，谁会留宝贝？
     */
    private List<Map<String, Object>> rollTrashLoot(String username, ContentItem realm, boolean firstEntry) {
        ThreadLocalRandom rnd = ThreadLocalRandom.current();
        List<Map<String, Object>> rewards = new ArrayList<>();

        boolean stones = rnd.nextBoolean();
        long amount = rnd.nextLong(5, 26);
        grantCurrency(username, realm, stones ? "stones" : "contribution", amount,
                stones ? "stones" : "contribution");
        rewards.add(reward("stones", stones ? "灵石" : "贡献值",
                stones ? "stones" : "contribution", stones ? "灵石" : "贡献值",
                "common", amount,
                stones ? "此境无人看守，你只翻出 " + amount + " 块下品灵石，渣渣。"
                       : "墙角摸出 " + amount + " 贡献值的供奉残渣，宗门勉强认账。"));

        if (firstEntry && rnd.nextInt(100) < 30) {
            long amount2 = rnd.nextLong(30, 101);
            grantCultivation(username, realm, amount2,
                    "无主之境的游离煞气稀薄，你吞吐半日只得修为 +" + amount2 + "，聊胜于无。");
            rewards.add(reward("cultivation", "修为", "cultivation", "修为",
                    "common", amount2, "游离煞气稀薄，修为只涨 +" + amount2 + "。"));
        }
        return rewards;
    }

    /** 按秘境类型掷奇遇（幻境 / 上古 / 普通） */
    private List<Map<String, Object>> rollEncounter(String username, ContentItem realm,
                                                    String realmType, int mult) {
        ThreadLocalRandom rnd = ThreadLocalRandom.current();
        List<Map<String, Object>> out = new ArrayList<>();
        int r = rnd.nextInt(100);

        switch (realmType) {
            case "illusion" -> { // 幻境秘境：道心通明 / 天赋神通 / 幻境功法
                if (r < 30) { // 道心通明：幻境大机缘
                    long amount = rnd.nextLong(1000, 2501) * mult;
                    grantCultivation(username, realm, amount,
                            "幻境中你直面本心魔障，道心通明！桎梏寸寸崩解，修为暴涨 +" + amount + "。");
                    out.add(reward("dao_clarity", "道心通明", "dao_clarity", "道心通明",
                            "epic", amount, "幻境照见本心，道心通明，修为暴涨 +" + amount + "。"));
                } else if (r < 65) { // 天赋神通
                    String ability = DIVINE_ABILITIES[rnd.nextInt(DIVINE_ABILITIES.length)];
                    long amount = rnd.nextLong(400, 901) * mult;
                    grantCultivation(username, realm, amount,
                            "幻境轮回百世，醒来时你多了一门天赋神通「" + ability + "」，修为 +" + amount + "。");
                    out.add(reward("divine_ability", ability, "divine_ability", "天赋神通·" + ability,
                            "rare", amount, "幻境造化：觉醒天赋神通「" + ability + "」，修为 +" + amount + "。"));
                } else { // 幻境功法（免贡习得）
                    Map<String, Object> tech = grantTechnique(username, realm, "rare");
                    if (tech != null) {
                        out.add(tech);
                    }
                }
            }
            case "ancient" -> { // 上古秘境：残篇 / 法宝 / 完整功法
                if (r < 40) { // 残篇上古功法
                    long amount = rnd.nextLong(400, 901) * mult;
                    grantCultivation(username, realm, amount,
                            "你拾得半卷上古残篇，字迹斑驳却隐有大道之音，参悟片刻修为 +" + amount + "。");
                    out.add(reward("fragment", "上古功法残篇", "fragment", "上古功法残篇",
                            "rare", amount, "残篇虽缺，大道犹存：参悟得修为 +" + amount + "。"));
                } else {
                    String artifact = ARTIFACT_COMMON[rnd.nextInt(ARTIFACT_COMMON.length)];
                    out.add(saveReward(username, realm, "artifact", artifact, "uncommon", 0L,
                            "尘封洞府中，" + artifact + "静静浮空。你伸手一握，器灵哼了一声，算是认了你。"));
                }
            }
            default -> { // 普通秘境：法宝 / 功法
                if (r < 55) {
                    String artifact = ARTIFACT_COMMON[rnd.nextInt(ARTIFACT_COMMON.length)];
                    out.add(saveReward(username, realm, "artifact", artifact, "uncommon", 0L,
                            "乱石堆里踢出一件法宝「" + artifact + "」，血气一激便服帖了。"));
                } else {
                    Map<String, Object> tech = grantTechnique(username, realm, "rare");
                    if (tech != null) {
                        out.add(tech);
                    }
                }
            }
        }
        return out;
    }

    // ----------------------------------------------------------
    // 奖励发放实现
    // ----------------------------------------------------------

    /** 灵石 / 贡献值入账：落 forum_income（source=secret），自动计入各处余额口径 */
    private void grantCurrency(String username, ContentItem realm, String rewardType,
                               long amount, String incomeColumn) {
        ForumIncome income = new ForumIncome();
        income.setUsername(username);
        income.setStones("stones".equals(incomeColumn) ? amount : 0L);
        income.setContribution("contribution".equals(incomeColumn) ? amount : 0L);
        income.setSource("secret");
        income.setCreateTime(LocalDateTime.now());
        forumIncomeMapper.insert(income);

        saveReward(username, realm, rewardType,
                "stones".equals(rewardType) ? "灵石" : "贡献值",
                "common", amount, null);
    }

    /** 修为奖励：走魔功殿通用结算（落 cultivation_log，methodKey=secret，修炼手札可见） */
    private void grantCultivation(String username, ContentItem realm, long amount, String story) {
        cultivationService.settle(username, "secret", "秘境探宝", "good", amount, 0, 0, story);
        saveReward(username, realm, "cultivation", "修为", "common", amount, story);
    }

    /**
     * 功法奖励：随机挑一门功法免贡习得（落 user_skill，cost=0，与功法阁/洞府联动）。
     * 功法库为空或已全部习得时返回 null（调用方自行兜底）。
     */
    private Map<String, Object> grantTechnique(String username, ContentItem realm, String rarity) {
        Category root = categoryMapper.selectOne(
                new LambdaQueryWrapper<Category>()
                        .eq(Category::getName, "功法")
                        .eq(Category::getLevel, 1)
                        .last("LIMIT 1"));
        if (root == null) {
            return null;
        }
        List<Long> ids = homeService.descendantIdsIncludingSelf(root.getId());
        ContentItem skill = contentItemMapper.selectList(
                        new LambdaQueryWrapper<ContentItem>()
                                .eq(ContentItem::getStatus, 1)
                                .in(ContentItem::getCategoryId, ids)
                                .last("ORDER BY RAND() LIMIT 1"))
                .stream().findFirst().orElse(null);
        if (skill == null) {
            return null;
        }

        Long learned = userSkillMapper.selectCount(
                new LambdaQueryWrapper<UserSkill>().eq(UserSkill::getUsername, username)
                        .eq(UserSkill::getItemId, skill.getId()));
        if (learned != null && learned > 0) {
            return null; // 已习得，改由修为兜底
        }

        UserSkill record = new UserSkill();
        record.setUsername(username);
        record.setItemId(skill.getId());
        record.setCost(0L);
        record.setTitle(skill.getTitle());
        record.setGrade(skill.getGrade());
        record.setIcon(skill.getIcon());
        userSkillMapper.insert(record);

        return saveReward(username, realm, "technique", skill.getTitle(), rarity, 0L,
                "秘境深处得授功法「" + skill.getTitle() + "」，已免贡收录洞府，可直接参悟温养。");
    }

    /** 落库并组装奖励条目 */
    private Map<String, Object> saveReward(String username, ContentItem realm, String rewardType,
                                           String rewardName, String rarity, long amount, String detail) {
        SecretReward r = new SecretReward();
        r.setUsername(username);
        r.setItemId(realm.getId());
        r.setRewardType(rewardType);
        r.setRewardName(rewardName);
        r.setRarity(rarity);
        r.setAmount(amount);
        r.setDetail(detail);
        r.setCreateTime(LocalDateTime.now());
        secretRewardMapper.insert(r);
        return reward(rewardType, rewardName, rewardType, rewardName, rarity, amount, detail);
    }

    /** 组装返回给前端的奖励条目 */
    private Map<String, Object> reward(String type, String name, String rewardType,
                                       String rewardName, String rarity, long amount, String detail) {
        Map<String, Object> m = new LinkedHashMap<>();
        m.put("type", type);
        m.put("name", name);
        m.put("rewardType", rewardType);
        m.put("rewardName", rewardName);
        m.put("rarity", rarity);
        m.put("amount", amount);
        m.put("detail", detail);
        m.put("icon", rewardIcon(rewardType));
        return m;
    }

    private String rewardIcon(String rewardType) {
        return switch (rewardType) {
            case "stones" -> "💎";
            case "contribution" -> "🎋";
            case "cultivation" -> "🔥";
            case "technique" -> "📜";
            case "fragment" -> "📎";
            case "artifact" -> "⚔️";
            case "divine_ability" -> "👁️";
            case "dao_clarity" -> "🧿";
            default -> "🎁";
        };
    }

    // ----------------------------------------------------------
    // 秘境类型与品阶
    // ----------------------------------------------------------

    /** 秘境类型：幻境 illusion / 上古 ancient / 普通 normal（按秘境名与分类名关键词） */
    private String realmTypeOf(ContentItem realm) {
        Category cat = realm.getCategoryId() == null ? null
                : categoryMapper.selectById(realm.getCategoryId());
        String catName = cat == null ? "" : (cat.getName() == null ? "" : cat.getName());
        String text = (realm.getTitle() == null ? "" : realm.getTitle())
                + (realm.getDescription() == null ? "" : realm.getDescription()) + catName;
        if (text.contains("幻")) {
            return "illusion";
        }
        if (text.contains("上古") || text.contains("远古")) {
            return "ancient";
        }
        return "normal";
    }

    /** 品阶放大系数：神·圣·魔阶 ×5 / 天阶 ×4 / 地·王·皇阶 ×3 / 玄阶 ×2 / 其它 ×1（与门票梯度同向） */
    private int gradeMultiplier(String grade) {
        String g = String.valueOf(grade == null ? "" : grade);
        if (g.contains("神") || g.contains("圣") || g.contains("魔")) {
            return 5;
        }
        if (g.contains("天")) {
            return 4;
        }
        if (g.contains("地") || g.contains("王") || g.contains("皇")) {
            return 3;
        }
        if (g.contains("玄")) {
            return 2;
        }
        return 1;
    }

    private long availableContribution(String name) {
        Object v = skillService.contributionBook(name).get("contributionAvailable");
        return v == null ? 0L : ((Number) v).longValue();
    }

    private String requireUsername(String username) {
        if (username == null || username.isBlank()) {
            throw new IllegalArgumentException("用户名不能为空");
        }
        return username.trim();
    }
}
