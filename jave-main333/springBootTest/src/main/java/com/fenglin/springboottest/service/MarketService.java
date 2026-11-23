package com.fenglin.springboottest.service;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.core.conditions.update.UpdateWrapper;
import com.fenglin.springboottest.entity.ForumIncome;
import com.fenglin.springboottest.entity.MarketItem;
import com.fenglin.springboottest.entity.MarketOrder;
import com.fenglin.springboottest.entity.SecretReward;
import com.fenglin.springboottest.entity.UserSkill;
import com.fenglin.springboottest.mapper.ForumIncomeMapper;
import com.fenglin.springboottest.mapper.MarketItemMapper;
import com.fenglin.springboottest.mapper.MarketOrderMapper;
import com.fenglin.springboottest.mapper.SecretRewardMapper;
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

/**
 * 坊市·交易市场服务（灵石经济的第三极：买 / 卖双向流动）。
 *
 * 经济规则（灵石账本与魔功殿共用，靠 forum_income source=market 记账）：
 *   买货：可用灵石 ≥ 售价 → forum_income 记 -price（负入账即支出）
 *         法宝 / 残篇 / 神通 → 入储物空间（secret_reward, status=0）
 *         功法 → 免贡收录（user_skill, cost=0，不含贡献值消耗）
 *         丹药 → 当场服用（cultivationService.settle, methodKey=market）
 *   卖货：储物空间里的法宝 / 残篇 / 神通按品阶估价回购 → forum_income 记 +price
 *         卖出后 secret_reward.status=1，物品从储物空间消失（回购即离手）
 *
 * 货架维持：在售货品少于 MIN_STOCK 时自动生成 NPC 货源补货，坊市永不冷清。
 * 价格随品阶放大：黄阶最贱、天阶天价；炼气弟子只买得起黄阶，想买天阶得先发财。
 */
@Service
@RequiredArgsConstructor
public class MarketService {

    /** 在售货品低于此数即自动补货 */
    private static final int MIN_STOCK = 10;

    /** 一次最多返回的货品数 */
    private static final int MAX_LIST = 60;

    private final MarketItemMapper marketItemMapper;
    private final MarketOrderMapper marketOrderMapper;
    private final SecretRewardMapper secretRewardMapper;
    private final UserSkillMapper userSkillMapper;
    private final ForumIncomeMapper forumIncomeMapper;
    private final CultivationService cultivationService;

    // ==========================================================
    // 一、货架与行情
    // ==========================================================

    /**
     * 坊市总览：灵石余额 + 在售货品（NPC 摊 + 道友私摊）+ 我的摊位 + 可寄售藏品 + 分类统计。
     *
     * @param category 货品类型过滤（artifact/technique/divine_ability/pill），null 或 all 为全部
     */
    @Transactional
    public Map<String, Object> list(String username, String category) {
        String name = requireUsername(username);
        restock();
        drifterVisit(); // 游方散修偶来捡漏，替玩家私摊制造成交

        LambdaQueryWrapper<MarketItem> qw = new LambdaQueryWrapper<MarketItem>()
                .eq(MarketItem::getStatus, 0)
                .orderByAsc(MarketItem::getPrice)
                .orderByDesc(MarketItem::getId)
                .last("LIMIT " + MAX_LIST);
        if (category != null && !category.isBlank() && !"all".equalsIgnoreCase(category)) {
            if ("artifact".equalsIgnoreCase(category.trim())) {
                qw.in(MarketItem::getItemType, "artifact", "fragment"); // 残篇也归法宝摊
            } else {
                qw.eq(MarketItem::getItemType, category.trim());
            }
        }
        List<MarketItem> items = marketItemMapper.selectList(qw);

        List<Map<String, Object>> cards = new ArrayList<>();
        if (items != null) {
            for (MarketItem it : items) {
                cards.add(itemCard(it, name));
            }
        }

        Map<String, Object> data = new LinkedHashMap<>();
        data.put("stonesAvailable", cultivationService.stonesBalance(name));
        data.put("items", cards);
        data.put("myListings", myListings(name));
        data.put("categories", categoriesWithCount());
        data.put("sellable", sellableCards(name));
        return data;
    }

    /** 货品卡片视图：补「是否自家摊位」标记，供前端禁买 / 撤单 */
    private Map<String, Object> itemCard(MarketItem it, String viewer) {
        Map<String, Object> m = new LinkedHashMap<>();
        m.put("id", it.getId());
        m.put("seller", it.getSeller());
        m.put("sellerType", it.getSellerType());
        m.put("title", it.getTitle());
        m.put("description", it.getDescription());
        m.put("itemType", it.getItemType());
        m.put("grade", it.getGrade());
        m.put("rarity", it.getRarity());
        m.put("icon", it.getIcon());
        m.put("price", it.getPrice());
        m.put("mine", viewer != null && viewer.equals(it.getSeller())
                && "user".equals(it.getSellerType()));
        return m;
    }

    /** 我的摊位：本人仍在售的私摊 */
    private List<Map<String, Object>> myListings(String name) {
        List<MarketItem> list = marketItemMapper.selectList(
                new LambdaQueryWrapper<MarketItem>()
                        .eq(MarketItem::getSeller, name)
                        .eq(MarketItem::getSellerType, "user")
                        .eq(MarketItem::getStatus, 0)
                        .orderByDesc(MarketItem::getId)
                        .last("LIMIT 30"));
        List<Map<String, Object>> out = new ArrayList<>();
        if (list == null) {
            return out;
        }
        for (MarketItem it : list) {
            Map<String, Object> m = itemCard(it, name);
            m.put("estimate", appraise(it.getRarity(), it.getItemType()));
            out.add(m);
        }
        return out;
    }

    /** 分类统计（用于 tab 角标） */
    private List<Map<String, Object>> categoriesWithCount() {
        List<MarketItem> all = marketItemMapper.selectList(
                new LambdaQueryWrapper<MarketItem>().eq(MarketItem::getStatus, 0));
        Map<String, Long> counts = new LinkedHashMap<>();
        if (all != null) {
            for (MarketItem it : all) {
                String key = it.getItemType() == null ? "artifact" : it.getItemType();
                if ("fragment".equals(key)) {
                    key = "artifact"; // 残篇并入法宝摊统计
                }
                counts.merge(key, 1L, Long::sum);
            }
        }
        List<Map<String, Object>> out = new ArrayList<>();
        out.add(categoryCard("all", "全部货架", "🏮", counts.values().stream().mapToLong(Long::longValue).sum()));
        for (String key : List.of("artifact", "technique", "divine_ability", "pill")) {
            out.add(categoryCard(key, typeLabel(key), typeIcon(key), counts.getOrDefault(key, 0L)));
        }
        return out;
    }

    private Map<String, Object> categoryCard(String key, String label, String icon, long count) {
        Map<String, Object> m = new LinkedHashMap<>();
        m.put("key", key);
        m.put("label", label);
        m.put("icon", icon);
        m.put("count", count);
        return m;
    }

    // ==========================================================
    // 二、买货
    // ==========================================================

    /**
     * 买入一件货品：扣灵石 → 货入储物空间 / 功法收录 / 丹药当场服用。
     */
    @Transactional
    public Map<String, Object> buy(String username, Long itemId) {
        String name = requireUsername(username);
        if (itemId == null || itemId < 1) {
            throw new IllegalArgumentException("货品编号不合法");
        }
        MarketItem item = marketItemMapper.selectById(itemId);
        if (item == null) {
            throw new IllegalArgumentException("此货已被搬空，摊主不认账");
        }
        if (item.getStatus() != null && item.getStatus() != 0) {
            throw new IllegalArgumentException("手慢了 —— 「" + item.getTitle() + "」已被别的道友买走");
        }
        String seller = item.getSeller();
        boolean privateStall = "user".equals(item.getSellerType()) && seller != null;
        if (privateStall && seller.equals(name)) {
            throw new IllegalArgumentException("自家的摊位，不必自买自卖；想收回就撤单");
        }
        long price = item.getPrice() == null ? 0L : item.getPrice();
        long balance = cultivationService.stonesBalance(name);
        if (balance < price) {
            throw new IllegalArgumentException("灵石不够：「" + item.getTitle() + "」开价 " + price
                    + "，你囊中仅有 " + balance + "。去任务阁交差或者卖掉点存货吧。");
        }

        // 抢占货品（status 仍为 0 才成交，防并发重复购买）
        int updated = marketItemMapper.update(null, new UpdateWrapper<MarketItem>()
                .set("status", 1)
                .set("buyer", name)
                .set("buy_time", LocalDateTime.now())
                .eq("id", itemId)
                .eq("status", 0));
        if (updated == 0) {
            throw new IllegalArgumentException("手慢了 —— 「" + item.getTitle() + "」刚被买走");
        }

        // 灵石支出：forum_income 记负入账（stonesBalance / 洞府余额口径自动扣减）
        ForumIncome income = new ForumIncome();
        income.setUsername(name);
        income.setStones(-price);
        income.setContribution(0L);
        income.setSource("market");
        income.setCreateTime(LocalDateTime.now());
        forumIncomeMapper.insert(income);

        String type = item.getItemType() == null ? "artifact" : item.getItemType();
        Map<String, Object> effect;
        if (privateStall) {
            // 道友私摊：卖家得灵石、原物离手，买家得一件同源藏品
            credit(seller, price);
            saveOrder(seller, "sell", item.getTitle(), type, item.getRarity(), price, name);
            if (item.getRewardId() != null) {
                secretRewardMapper.update(null, new UpdateWrapper<SecretReward>()
                        .set("status", 1)
                        .eq("id", item.getRewardId()));
            }
            effect = deliverPrivate(name, item, type);
        } else {
            effect = deliver(name, item, type);
        }
        saveOrder(name, "buy", item.getTitle(), type, item.getRarity(), price, seller);

        Map<String, Object> data = new LinkedHashMap<>();
        data.put("title", item.getTitle());
        data.put("itemType", type);
        data.put("price", price);
        data.put("privateStall", privateStall);
        data.put("effect", effect);
        data.put("message", effect.get("message"));
        data.put("stonesBalance", cultivationService.stonesBalance(name));
        return data;
    }

    /** 私摊成交：把卖家藏品复制一份给买家（原物归卖家、已标售出） */
    private Map<String, Object> deliverPrivate(String buyer, MarketItem item, String type) {
        Map<String, Object> effect = new LinkedHashMap<>();
        SecretReward origin = item.getRewardId() == null ? null
                : secretRewardMapper.selectById(item.getRewardId());
        String name = origin == null ? item.getTitle() : origin.getRewardName();
        String rarity = origin == null ? item.getRarity() : origin.getRarity();
        String detail = origin == null || origin.getDetail() == null
                ? "自「" + item.getSeller() + "」的私摊购得「" + item.getTitle() + "」。"
                : (origin.getDetail().length() > 240
                    ? origin.getDetail().substring(0, 240) : origin.getDetail());

        SecretReward r = new SecretReward();
        r.setUsername(buyer);
        r.setItemId(item.getId());
        r.setRewardType(type);
        r.setRewardName(name);
        r.setRarity(rarity);
        r.setAmount(0L);
        r.setStatus(0);
        r.setDetail("自道友「" + item.getSeller() + "」私摊购得此物。 " + detail);
        r.setCreateTime(LocalDateTime.now());
        secretRewardMapper.insert(r);

        effect.put("into", "storage");
        effect.put("message", "「" + name + "」已从「" + item.getSeller() + "」私摊收入储物空间");
        return effect;
    }

    /** 灵石入账（卖出 / 私摊成交给卖家，正入账） */
    private void credit(String username, long amount) {
        ForumIncome income = new ForumIncome();
        income.setUsername(username);
        income.setStones(amount);
        income.setContribution(0L);
        income.setSource("market");
        income.setCreateTime(LocalDateTime.now());
        forumIncomeMapper.insert(income);
    }

    /** 发货：按货品类型分别入账，返回给前端的展示信息 */
    private Map<String, Object> deliver(String name, MarketItem item, String type) {
        Map<String, Object> effect = new LinkedHashMap<>();
        String title = item.getTitle();
        switch (type) {
            case "technique" -> {
                boolean learned = userSkillMapper.selectCount(
                        new LambdaQueryWrapper<UserSkill>().eq(UserSkill::getUsername, name)
                                .eq(UserSkill::getTitle, title)) == 0;
                if (learned) {
                    UserSkill skill = new UserSkill();
                    skill.setUsername(name);
                    // 坊市货品与 content_item 是两套 id，这里用 0 作哨兵，
                    // 避免 id 撞号导致功法阁把某本册子误判为「已参悟」
                    skill.setItemId(0L);
                    skill.setCost(0L); // 灵石已在坊市付讫，不再记贡献值消耗
                    skill.setTitle(title);
                    skill.setGrade(item.getGrade());
                    skill.setIcon(item.getIcon());
                    userSkillMapper.insert(skill);
                }
                saveReward(name, item, "technique", title, item.getRarity(),
                        "坊市淘得功法「" + title + "」，灵气一激自行认主，可去功法阁参悟温养。");
                effect.put("into", "skill");
                effect.put("message", "功法「" + title + "」已收录，去功法阁即可参悟");
            }
            case "pill" -> {
                long gain = pillGain(item.getGrade());
                cultivationService.settle(name, "market", "坊市丹药", "good", gain, 0, 0,
                        "你在坊市吞下「" + title + "」，药力霸道直冲丹田。疼得眼前发黑，但修为 +" + gain + "。");
                effect.put("into", "cultivation");
                effect.put("gain", gain);
                effect.put("message", "丹药入腹，「" + title + "」药力化开，修为 +" + gain);
            }
            default -> {
                saveReward(name, item, type, title, item.getRarity(),
                        "自坊市购得「" + title + "」，摊主" + item.getSeller() + "交货时笑得意味深长。已收入储物空间。");
                effect.put("into", "storage");
                effect.put("message", "「" + title + "」已收入储物空间");
            }
        }
        return effect;
    }

    /** 丹药修为收益：按品阶 */
    private long pillGain(String grade) {
        String g = String.valueOf(grade == null ? "" : grade);
        ThreadLocalRandom rnd = ThreadLocalRandom.current();
        if (g.contains("天")) {
            return rnd.nextLong(1800, 3801);
        }
        if (g.contains("地")) {
            return rnd.nextLong(800, 1801);
        }
        if (g.contains("玄")) {
            return rnd.nextLong(350, 801);
        }
        return rnd.nextLong(120, 351);
    }

    // ==========================================================
    // 三、卖货（坊市回购）
    // ==========================================================

    /**
     * 寄售回购：把储物空间里的法宝 / 残篇 / 神通卖给坊市牙人，按品阶估价换灵石。
     * 卖出后物品从储物空间消失（status=1），不可再卖。
     */
    @Transactional
    public Map<String, Object> sell(String username, Long rewardId) {
        String name = requireUsername(username);
        if (rewardId == null || rewardId < 1) {
            throw new IllegalArgumentException("藏品编号不合法");
        }
        SecretReward reward = secretRewardMapper.selectById(rewardId);
        if (reward == null || !name.equals(reward.getUsername())) {
            throw new IllegalArgumentException("此物不在你的储物袋里");
        }
        String type = reward.getRewardType() == null ? "" : reward.getRewardType();
        if (!List.of("artifact", "fragment", "divine_ability").contains(type)) {
            throw new IllegalArgumentException("坊市牙人只收法宝、残篇与神通");
        }
        if (reward.getStatus() != null && reward.getStatus() != 0) {
            throw new IllegalArgumentException(reward.getStatus() == 2
                    ? "此物正在你的私摊上寄售，先撤单才能卖给牙人"
                    : "此物已离手，牙人不收第二回");
        }

        long price = appraise(reward.getRarity(), type);
        int updated = secretRewardMapper.update(null, new UpdateWrapper<SecretReward>()
                .set("status", 1)
                .eq("id", rewardId)
                .eq("status", 0));
        if (updated == 0) {
            throw new IllegalArgumentException("此物刚被卖出，手慢了");
        }

        credit(name, price);

        saveOrder(name, "sell", reward.getRewardName(), type, reward.getRarity(), price, "坊市牙人");

        Map<String, Object> data = new LinkedHashMap<>();
        data.put("title", reward.getRewardName());
        data.put("price", price);
        data.put("message", "牙人捏着「" + reward.getRewardName() + "」端详半晌，丢了 " + price + " 块灵石给你");
        data.put("stonesBalance", cultivationService.stonesBalance(name));
        return data;
    }

    // ==========================================================
    // 三·五、玩家私摊（自由标价 / 撤单 / 散修捡漏）
    // ==========================================================

    /**
     * 自行挂单：把储物空间里的藏品摆上私摊，价格由玩家定（限估价 0.5~3 倍）。
     * 挂单期间藏品状态 = 2（寄售中），不在储物空间、也不能再卖给牙人；
     * 撤单后物归原主，售出后双向结算灵石。
     */
    @Transactional
    public Map<String, Object> listItem(String username, Long rewardId, Long price) {
        String name = requireUsername(username);
        if (rewardId == null || rewardId < 1) {
            throw new IllegalArgumentException("藏品编号不合法");
        }
        SecretReward reward = secretRewardMapper.selectById(rewardId);
        if (reward == null || !name.equals(reward.getUsername())) {
            throw new IllegalArgumentException("此物不在你的储物袋里");
        }
        String type = reward.getRewardType() == null ? "" : reward.getRewardType();
        if (!List.of("artifact", "fragment", "divine_ability").contains(type)) {
            throw new IllegalArgumentException("私摊只寄售法宝、残篇与神通");
        }
        if (reward.getStatus() != null && reward.getStatus() != 0) {
            throw new IllegalArgumentException(reward.getStatus() == 2
                    ? "此物已在私摊寄售，先撤单再改价"
                    : "此物已离手，不能再摆摊");
        }
        if (price == null || price < 1) {
            throw new IllegalArgumentException("请报个价，白送可不是魔宗作风");
        }

        long estimate = appraise(reward.getRarity(), type);
        long min = Math.max(10L, Math.round(estimate * 0.5));
        long max = Math.round(estimate * 3.0);
        if (price < min || price > max) {
            throw new IllegalArgumentException("标价越界：牙人估价 " + estimate
                    + " 灵石，本坊只准标 " + min + " ~ " + max + " 灵石（漫天要价没人接）");
        }

        int updated = secretRewardMapper.update(null, new UpdateWrapper<SecretReward>()
                .set("status", 2)
                .eq("id", rewardId)
                .eq("status", 0));
        if (updated == 0) {
            throw new IllegalArgumentException("此物刚被摆上摊，手慢了");
        }

        MarketItem stall = new MarketItem();
        stall.setSeller(name);
        stall.setSellerType("user");
        stall.setTitle(reward.getRewardName());
        stall.setDescription("道友私摊 · 自秘境所得，售出不退。标价 " + price + " 灵石，议价免谈。");
        stall.setItemType(type);
        stall.setGrade(null);
        stall.setRarity(reward.getRarity() == null ? "common" : reward.getRarity());
        stall.setIcon(rewardIcon(type));
        stall.setRewardId(rewardId);
        stall.setPrice(price);
        stall.setStatus(0);
        stall.setCreateTime(LocalDateTime.now());
        marketItemMapper.insert(stall);

        Map<String, Object> data = new LinkedHashMap<>();
        data.put("itemId", stall.getId());
        data.put("price", price);
        data.put("estimate", estimate);
        data.put("message", "「" + reward.getRewardName() + "」已摆上私摊，开价 " + price + " 灵石，待人识货");
        return data;
    }

    /** 撤单：未售出的私摊货收回储物空间 */
    @Transactional
    public Map<String, Object> cancel(String username, Long itemId) {
        String name = requireUsername(username);
        if (itemId == null || itemId < 1) {
            throw new IllegalArgumentException("货品编号不合法");
        }
        MarketItem item = marketItemMapper.selectById(itemId);
        if (item == null || !"user".equals(item.getSellerType()) || !name.equals(item.getSeller())) {
            throw new IllegalArgumentException("这不是你的私摊");
        }
        if (item.getStatus() != null && item.getStatus() != 0) {
            throw new IllegalArgumentException(item.getStatus() == 1
                    ? "此货已成交，撤不了了" : "此单已撤过");
        }
        int updated = marketItemMapper.update(null, new UpdateWrapper<MarketItem>()
                .set("status", 2)
                .eq("id", itemId)
                .eq("status", 0));
        if (updated == 0) {
            throw new IllegalArgumentException("手慢了 —— 此货刚被买走");
        }
        if (item.getRewardId() != null) {
            secretRewardMapper.update(null, new UpdateWrapper<SecretReward>()
                    .set("status", 0)
                    .eq("id", item.getRewardId()));
        }

        Map<String, Object> data = new LinkedHashMap<>();
        data.put("title", item.getTitle());
        data.put("message", "「" + item.getTitle() + "」已收回储物空间，摊位撤了");
        return data;
    }

    /**
     * 游方散修逛坊市：每次刷新有 18% 概率挑一件「价格合理」的玩家私摊买走，
     * 让单人玩家也有成交机会。价格 ≤ 牙人估价 × 1.5 才算合理（漫天要价的摊子没人接）。
     */
    private void drifterVisit() {
        if (ThreadLocalRandom.current().nextInt(100) >= 18) {
            return;
        }
        List<MarketItem> stalls = marketItemMapper.selectList(
                new LambdaQueryWrapper<MarketItem>()
                        .eq(MarketItem::getStatus, 0)
                        .eq(MarketItem::getSellerType, "user")
                        .orderByAsc(MarketItem::getPrice)
                        .last("LIMIT 20"));
        if (stalls == null || stalls.isEmpty()) {
            return;
        }
        for (MarketItem stall : stalls) {
            long estimate = appraise(stall.getRarity(), stall.getItemType());
            if (stall.getPrice() == null || stall.getPrice() > estimate * 1.5) {
                continue; // 太贵，散修绕着走
            }
            String seller = stall.getSeller();
            if (seller == null) {
                continue;
            }
            int updated = marketItemMapper.update(null, new UpdateWrapper<MarketItem>()
                    .set("status", 1)
                    .set("buyer", "游方散修")
                    .set("buy_time", LocalDateTime.now())
                    .eq("id", stall.getId())
                    .eq("status", 0));
            if (updated == 0) {
                continue;
            }
            credit(seller, stall.getPrice());
            saveOrder(seller, "sell", stall.getTitle(), stall.getItemType(),
                    stall.getRarity(), stall.getPrice(), "游方散修");
            if (stall.getRewardId() != null) {
                secretRewardMapper.update(null, new UpdateWrapper<SecretReward>()
                        .set("status", 1)
                        .eq("id", stall.getRewardId()));
            }
            return; // 一位散修一次只收一件
        }
    }

    private String rewardIcon(String type) {
        return switch (type) {
            case "fragment" -> "📜";
            case "divine_ability" -> "✨";
            default -> "🏺";
        };
    }

    /**
     * 牙人估价：稀有度基准价 × 类型系数（确定性，保证前端展示与后端校验一致，
     * 玩家填的标价不会因每次重算浮动而被误判越界）。
     */
    private long appraise(String rarity, String type) {
        long base = switch (String.valueOf(rarity == null ? "" : rarity)) {
            case "legendary" -> 2400L;
            case "epic" -> 900L;
            case "rare" -> 340L;
            case "uncommon" -> 130L;
            default -> 45L;
        };
        double factor = switch (type) {
            case "divine_ability" -> 1.3;
            case "fragment" -> 0.8;
            default -> 1.0;
        };
        return Math.max(10L, Math.round(base * factor));
    }

    /** 可寄售列表（含估价），供前端「寄售回购」面板渲染 */
    private List<Map<String, Object>> sellableCards(String name) {
        List<SecretReward> list;
        try {
            list = secretRewardMapper.selectList(new LambdaQueryWrapper<SecretReward>()
                    .eq(SecretReward::getUsername, name)
                    .eq(SecretReward::getStatus, 0)
                    .in(SecretReward::getRewardType, "artifact", "fragment", "divine_ability")
                    .orderByDesc(SecretReward::getCreateTime)
                    .orderByDesc(SecretReward::getId)
                    .last("LIMIT 40"));
        } catch (Exception e) {
            return new ArrayList<>();
        }
        List<Map<String, Object>> out = new ArrayList<>();
        if (list == null) {
            return out;
        }
        for (SecretReward r : list) {
            Map<String, Object> m = new LinkedHashMap<>();
            m.put("id", r.getId());
            m.put("name", r.getRewardName());
            m.put("rewardType", r.getRewardType());
            m.put("typeLabel", switch (r.getRewardType() == null ? "" : r.getRewardType()) {
                case "artifact" -> "法宝";
                case "fragment" -> "上古残篇";
                case "divine_ability" -> "天赋神通";
                default -> "奇物";
            });
            m.put("icon", switch (r.getRewardType() == null ? "" : r.getRewardType()) {
                case "artifact" -> "🏺";
                case "fragment" -> "📜";
                case "divine_ability" -> "✨";
                default -> "📦";
            });
            m.put("rarity", r.getRarity() == null ? "common" : r.getRarity());
            m.put("estimate", appraise(r.getRarity(), r.getRewardType()));
            out.add(m);
        }
        return out;
    }

    // ==========================================================
    // 四、交易手札 & 自动补货
    // ==========================================================

    /** 我的交易手札：最近 20 条买卖流水，时间倒序 */
    public List<MarketOrder> orders(String username, int limit) {
        String name = requireUsername(username);
        List<MarketOrder> list = marketOrderMapper.selectList(
                new LambdaQueryWrapper<MarketOrder>().eq(MarketOrder::getUsername, name)
                        .orderByDesc(MarketOrder::getCreateTime)
                        .orderByDesc(MarketOrder::getId)
                        .last("LIMIT " + Math.min(Math.max(limit, 1), 50)));
        return list == null ? new ArrayList<>() : list;
    }

    /** 自动补货：NPC 在售货品不足 MIN_STOCK 时补货（玩家私摊不计入，不占摊位额度） */
    private void restock() {
        Long onSale = marketItemMapper.selectCount(
                new LambdaQueryWrapper<MarketItem>()
                        .eq(MarketItem::getStatus, 0)
                        .eq(MarketItem::getSellerType, "npc"));
        long need = MIN_STOCK - (onSale == null ? 0 : onSale);
        for (long i = 0; i < need; i++) {
            marketItemMapper.insert(randomGoods());
        }
    }

    /** NPC 摊主名池 */
    private static final String[] NPC_SELLERS = {
            "噬魂老魔", "白骨夫人", "赤炎老祖", "玄阴子", "鬼手药王", "幽冥牙人", "血衣楼主"
    };

    /** 货名池：{类型, 品阶权重外的名字候选} */
    private static final Map<String, String[]> NAME_POOL = Map.of(
            "artifact", new String[]{"噬魂幡", "血煞铃", "幽冥骨爪", "玄阴镜", "赤炎珠", "枯荣笛", "万魂血幡", "九幽冥王鼎"},
            "fragment", new String[]{"残卷·血煞引", "残卷·幽冥骨典", "残卷·焚天诀", "残卷·噬灵篇", "残卷·枯骨禅"},
            "divine_ability", new String[]{"鬼目透视", "血遁千里", "噬灵之瞳", "阴风耳", "腐骨毒息"},
            "pill", new String[]{"淬体血丹", "九转噬魂丹", "蚀骨散", "续命黑丹", "凝血丸"},
            "technique", new String[]{"血煞炼骨术", "幽冥引气诀", "噬魂大法", "枯骨禅", "血河真经"});

    /** 随机生成一件 NPC 货品（品阶权重：黄 50% / 玄 30% / 地 15% / 天 5%） */
    private MarketItem randomGoods() {
        ThreadLocalRandom rnd = ThreadLocalRandom.current();
        String[] types = {"artifact", "artifact", "artifact", "technique", "divine_ability", "pill", "fragment"};
        String type = types[rnd.nextInt(types.length)];
        String[] names = NAME_POOL.getOrDefault(type, NAME_POOL.get("artifact"));
        String title = names[rnd.nextInt(names.length)];

        int roll = rnd.nextInt(100);
        String grade;
        String rarity;
        long base;
        if (roll < 50) {
            grade = "黄阶"; rarity = "common";   base = rnd.nextLong(120, 321);
        } else if (roll < 80) {
            grade = "玄阶"; rarity = "uncommon"; base = rnd.nextLong(380, 901);
        } else if (roll < 95) {
            grade = "地阶"; rarity = "rare";     base = rnd.nextLong(1200, 2801);
        } else {
            grade = "天阶"; rarity = "epic";     base = rnd.nextLong(2600, 6501);
        }
        double factor = switch (type) {
            case "technique" -> 1.1;
            case "divine_ability" -> 1.3;
            case "pill" -> 0.5;
            case "fragment" -> 0.7;
            default -> 1.0;
        };

        MarketItem item = new MarketItem();
        item.setSeller(NPC_SELLERS[rnd.nextInt(NPC_SELLERS.length)]);
        item.setSellerType("npc");
        item.setTitle(title);
        item.setDescription(flavor(type, grade));
        item.setItemType(type);
        item.setGrade(grade);
        item.setRarity(rarity);
        item.setIcon(typeIcon(type));
        item.setPrice(Math.max(20L, Math.round(base * factor)));
        item.setStatus(0);
        item.setCreateTime(LocalDateTime.now());
        return item;
    }

    /** 摊主吆喝文案（魔宗口吻） */
    private String flavor(String type, String grade) {
        return switch (type) {
            case "technique" -> grade + "功法一册，字迹潦草，来历不便细说。练岔了别来找我。";
            case "divine_ability" -> grade + "神通，取自某位不愿具名的前辈。装上之后夜里会有点动静，正常。";
            case "pill" -> grade + "丹药，药王亲手炼的。药效猛烈，服用前请坐稳。";
            case "fragment" -> grade + "残篇，缺的那半卷谁都找不到。练一半也够吓人了。";
            default -> grade + "法宝，认主与否看缘分。不认主的，自己想办法。";
        };
    }

    private String typeIcon(String type) {
        return switch (type) {
            case "technique" -> "📕";
            case "divine_ability" -> "👁️";
            case "pill" -> "💊";
            case "fragment" -> "📜";
            default -> "⚔️";
        };
    }

    private String typeLabel(String key) {
        return switch (key) {
            case "technique" -> "功法";
            case "divine_ability" -> "神通";
            case "pill" -> "丹药";
            default -> "法宝";
        };
    }

    // ----------------------------------------------------------
    // 落库辅助
    // ----------------------------------------------------------

    /** 落一条交易流水 */
    private void saveOrder(String username, String tradeType, String title, String itemType,
                           String rarity, long price, String counterparty) {
        MarketOrder order = new MarketOrder();
        order.setUsername(username);
        order.setTradeType(tradeType);
        order.setTitle(title);
        order.setItemType(itemType);
        order.setRarity(rarity);
        order.setPrice(price);
        order.setCounterparty(counterparty);
        order.setCreateTime(LocalDateTime.now());
        marketOrderMapper.insert(order);
    }

    /** 货入储物空间（法宝 / 残篇 / 神通 / 功法留档） */
    private void saveReward(String username, MarketItem item, String rewardType,
                            String rewardName, String rarity, String detail) {
        SecretReward r = new SecretReward();
        r.setUsername(username);
        r.setItemId(item.getId()); // 坊市货品 id（item_id 仅作溯源）
        r.setRewardType(rewardType);
        r.setRewardName(rewardName);
        r.setRarity(rarity);
        r.setAmount(0L);
        r.setStatus(0);
        r.setDetail(detail);
        r.setCreateTime(LocalDateTime.now());
        secretRewardMapper.insert(r);
    }

    private String requireUsername(String username) {
        if (username == null || username.isBlank()) {
            throw new IllegalArgumentException("用户名不能为空");
        }
        return username.trim();
    }
}
