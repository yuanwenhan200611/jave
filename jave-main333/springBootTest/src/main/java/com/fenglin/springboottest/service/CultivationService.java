package com.fenglin.springboottest.service;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import com.baomidou.mybatisplus.core.conditions.update.UpdateWrapper;
import com.fenglin.springboottest.entity.CultivationLog;
import com.fenglin.springboottest.entity.ForumIncome;
import com.fenglin.springboottest.entity.UserProfile;
import com.fenglin.springboottest.entity.UserQuest;
import com.fenglin.springboottest.mapper.CultivationLogMapper;
import com.fenglin.springboottest.mapper.ForumIncomeMapper;
import com.fenglin.springboottest.mapper.UserProfileMapper;
import com.fenglin.springboottest.mapper.UserQuestMapper;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Duration;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.concurrent.ThreadLocalRandom;

/**
 * 魔功殿服务：修为体系 + 五种魔宗风格修炼法门。
 *
 * 修为（cultivation）累计于 user_profile，跨过境界门槛时自动晋升境界
 * （只升不降；洞府仍可手动改境界，与修为互不冲突）。
 *
 * 五种法门（魔道无坦途，越是捷径越险）：
 *   mogu    魔窟苦修   免费 · 无险 · 收益低（保底）
 *   xuedan  吞噬血丹   花灵石 · 无险 · 收益稳定
 *   xueji   血祭秘法   花贡献值 · 小概率反噬
 *   duoshe  夺舍夺元   免费 · 高风险高回报（成则暴涨，败则被阵法反噬）
 *   tuntian 吞天魔功   花大量灵石 · 禁忌魔功（大成暴涨 / 小成 / 走火入魔倒退）
 *
 * 经济闭环：任务阁交差赚灵石/贡献 → 魔功殿花灵石/贡献换修为。
 * 可用余额 = 任务累计所得(user_quest) - 修炼已耗(cultivation_log)。
 * （功法阁参悟另扣贡献值，由 ProfileService 一并聚合。）
 */
@Service
public class CultivationService {

    /** 十大境界（由低到高），与 QuestService.REALM_ORDER 保持一致 */
    private static final List<String> REALMS = List.of(
            "炼气", "筑基", "金丹", "元婴", "化神", "炼虚", "合体", "大乘", "渡劫", "魔尊");

    /** 各境界修为门槛（下标对应 REALMS）：达到门槛即晋升该境界 */
    private static final long[] REALM_THRESHOLD = {
            0, 1000, 5000, 15000, 40000, 100000, 250000, 600000, 1500000, 5000000
    };

    private static final int MAX_LIST = 20;

    private final CultivationLogMapper cultivationLogMapper;
    private final UserProfileMapper userProfileMapper;
    private final UserQuestMapper userQuestMapper;
    private final ForumIncomeMapper forumIncomeMapper;

    public CultivationService(CultivationLogMapper cultivationLogMapper,
                              UserProfileMapper userProfileMapper,
                              UserQuestMapper userQuestMapper,
                              ForumIncomeMapper forumIncomeMapper) {
        this.cultivationLogMapper = cultivationLogMapper;
        this.userProfileMapper = userProfileMapper;
        this.userQuestMapper = userQuestMapper;
        this.forumIncomeMapper = forumIncomeMapper;
    }

    // ==========================================================
    // 一、法门定义
    // ==========================================================

    /** 法门元数据 */
    private record MethodDef(String key, String name, String icon, String desc,
                             String riskText, long costStones, long costContribution,
                             int cooldownSeconds) {
    }

    private static final Map<String, MethodDef> METHODS = new LinkedHashMap<>();

    static {
        METHODS.put("mogu", new MethodDef(
                "mogu", "魔窟苦修", "⛰️",
                "入血煞魔窟面壁百日，一口一口吞煞气淬体。慢，但稳——魔道里肯下苦功的，没一个是简单角色。",
                "无险", 0, 0, 20));
        METHODS.put("xuedan", new MethodDef(
                "xuedan", "吞噬血丹", "🩸",
                "炼丹堂秘制血丹，以百年妖血凝丹。一枚下肚，魔气翻江倒海，行功三个周天便化为己用。",
                "无险", 100, 0, 30));
        METHODS.put("xueji", new MethodDef(
                "xueji", "血祭秘法", "🔥",
                "将妖兽精血泼洒魔坛，血祭三日三夜，借外力催涨修为。魔道捷径皆有代价——祭品若不认主，火会烧回来。",
                "小险", 0, 200, 60));
        METHODS.put("duoshe", new MethodDef(
                "duoshe", "夺舍夺元", "👻",
                "趁夜摸进散修洞府，夺其一身修为据为己有。成了名震一方，败了被护山大阵反噬，修为倒跌。",
                "大险", 0, 0, 90));
        METHODS.put("tuntian", new MethodDef(
                "tuntian", "吞天魔功", "🌀",
                "宗主亲传禁忌魔功，吞纳天地魔气于己身。大成者一日千里，小成者略有精进，走火入魔者修为倒退——宗门口碑两极，慎修。",
                "禁忌", 500, 0, 120));
    }

    // ==========================================================
    // 二、修炼异象文案池（{n} 会替换为本次修为增减的绝对值）
    // ==========================================================

    private static final Map<String, Map<String, List<String>>> STORIES = new LinkedHashMap<>();

    private static void putStories(String key, List<String> great, List<String> good, List<String> backlash) {
        Map<String, List<String>> m = new HashMap<>();
        m.put("great", great);
        m.put("good", good);
        m.put("backlash", backlash);
        STORIES.put(key, m);
    }

    static {
        putStories("mogu",
                List.of("魔窟第七层煞气最浓，你盘坐其中如老树盘根。出关那天，看守的师弟差点没认出你——周身魔气凝而不散，修为 +{n}。"),
                List.of(
                        "你在魔窟最深处寻得一处废弃丹室，废丹炉里的残火尚有余温。就着残火吐纳一夜，修为 +{n}。",
                        "魔窟石壁上留有前任看窟人的爪痕与一行小字：「煞气伤身，慢吞为宜」。你依言慢吞，修为 +{n}。",
                        "洞中忽有阴风绕体不走，你顺势引风入体，炼作一缕魔元，修为 +{n}。"),
                List.of());
        putStories("xuedan",
                List.of("血丹入喉即化，一股滚烫热流自丹田炸开。你咬牙运功七个周天，硬生生把这股魔气炼化——修为 +{n}。"),
                List.of(
                        "血丹下肚，眼前血雾弥漫，隐约有百兽哀嚎。三个周天后雾散嚎止，修为 +{n}。",
                        "丹香入鼻，魔气自生。你盘坐到天亮，只觉经脉宽阔了一分，修为 +{n}。"),
                List.of());
        putStories("xueji",
                List.of(
                        "魔坛血火冲天，三日三夜不熄。血祭功成那一刻，你听见无数祭品在耳畔齐声哀鸣——随后尽数化为你的修为，+{n}。",
                        "血祭将成时，坛中精血忽然化作一道赤光钻入你眉心。你福至心灵就地运功，修为暴涨 +{n}。"),
                List.of(
                        "血火猩红，祭品哀鸣，修为缓缓上涨 +{n}。只是收功时你发现，左手无名指多了一道血纹——那是祭品的「收据」。",
                        "魔坛认了你，精血化魔气入体，修为 +{n}。丹堂长老路过看了你一眼，没说话，走了。"),
                List.of(
                        "祭品不甘为祭，血火逆流倒卷！你被自己的魔坛烧了三日，醒来时修为 -{n}，魔坛上也多了一撮灰。",
                        "血祭中途断了香火，坛中怨气趁虚而入，在你经脉里横冲直撞。镇压下去后清点修为，竟 -{n}。"));
        putStories("duoshe",
                List.of(
                        "子夜，散修洞府门户大开，护山大阵早已失效。你夺其金丹，吞其修为，天亮之前功成身退——修为暴涨 +{n}，江湖上只多了一具枯坐的躯壳。",
                        "那散修梦里还在喊「饶命」。你没有应声，只是把他的修为一寸一寸抽了出来。晨钟响起时你已回到宗门，修为 +{n}。"),
                List.of(
                        "洞府主人竟是位炼气散修，你搜刮半天只得了些残功。好歹聊胜于无，修为 +{n}。",
                        "夺舍过半，那散修竟自发残存一道护身符箓。你硬吃下这道反震，修为只涨了 +{n}。"),
                List.of(
                        "护山大阵根本没失效——那是阵眼在装死。你被一道雷符劈出三里地，修为 -{n}，从此江湖多了个笑柄。",
                        "夺舍到一半，那散修睁开眼笑了：「等你很久了。」你落荒而逃，修为 -{n}。"));

        putStories("tuntian",
                List.of(
                        "吞天魔功第七转，天地魔气如百川归海倒灌而入！远处雷云为你翻涌，近处草木为你枯萎。你张开双臂迎接天劫前最后一场魔气暴动——修为暴涨 +{n}。",
                        "魔功大成那刻，你听见宗主隔着千里轻笑了一声。天地魔气为你让路，修为 +{n}。"),
                List.of(
                        "吞天魔功运转周天，只吞得三成魔气便再无寸进。功成收势，修为 +{n}——不算多，但也没烧着自己。",
                        "魔气入体时你打了个喷嚏，一口气没提上来，险些岔了气。好在最终修为 +{n}。"),
                List.of(
                        "魔气逆行，走火入魔！你在血池里泡了整整一日才压住乱窜的魔气，醒来清点：修为 -{n}，头发白了一半。",
                        "吞到一半，天地魔气忽然调头反噬。你死死守住丹田才没爆体，代价是修为 -{n}。宗主说这很正常。"));
    }

    // ==========================================================
    // 三、修炼（核心）
    // ==========================================================

    /**
     * 修炼一门魔功：校验冷却与余额 → 掷结果 → 结算修为 → 判定突破 → 落记录。
     */
    @Transactional
    public Map<String, Object> practice(String username, String methodKey) {
        String name = requireUsername(username);
        MethodDef def = METHODS.get(methodKey);
        if (def == null) {
            throw new IllegalArgumentException("查无此法门");
        }

        UserProfile profile = requireProfile(name);

        // 1. 冷却校验
        long remain = remainSeconds(name, def);
        if (remain > 0) {
            throw new IllegalArgumentException("魔气未复：「" + def.name() + "」还需调息 " + remain + " 秒");
        }

        // 2. 余额校验
        long stonesBalance = stonesBalance(name);
        long contributionBalance = contributionBalance(name);
        if (def.costStones() > 0 && stonesBalance < def.costStones()) {
            throw new IllegalArgumentException("灵石不够：" + def.name() + "需 " + def.costStones()
                    + " 灵石，你只剩 " + stonesBalance + "。先去任务阁接几单悬赏吧。");
        }
        if (def.costContribution() > 0 && contributionBalance < def.costContribution()) {
            throw new IllegalArgumentException("贡献值不够：" + def.name() + "需 " + def.costContribution()
                    + " 贡献值，你只剩 " + contributionBalance + "。宗门的悬赏牌不是摆设。");
        }

        // 3. 掷结果
        String outcome = rollOutcome(def.key());
        long delta = rollDelta(def.key(), outcome);
        String story = pickStory(def.key(), outcome, delta);

        // 4~6. 结算修为 + 境界突破 + 落修炼记录
        Map<String, Object> settled = settle(name, def.key(), def.name(), outcome, delta,
                def.costStones(), def.costContribution(), story);

        // 7. 组装结果
        Map<String, Object> data = new LinkedHashMap<>();
        data.put("methodKey", def.key());
        data.put("methodName", def.name());
        data.put("icon", def.icon());
        data.put("outcome", outcome);
        data.put("outcomeText", outcomeText(outcome));
        data.put("delta", delta);
        data.put("costStones", def.costStones());
        data.put("costContribution", def.costContribution());
        data.put("story", story);
        data.putAll(settled);
        data.put("stonesBalance", stonesBalance(name));
        data.put("contributionBalance", contributionBalance(name));
        data.put("cooldownSeconds", def.cooldownSeconds());
        return data;
    }

    // ==========================================================
    // 三·五、公共结算（魔功殿与血辩台共用）
    // ==========================================================

    /**
     * 通用修为结算：加减速修为（不低于 0）→ 判定境界突破（只升不降）→ 落修炼记录。
     * 血辩台的开坛讲道 / 香火供奉 / 驳道也走这里，消耗与异象自动进入修炼手札与经济账本。
     *
     * @return cultivation / realm / fromRealm / toRealm / breakthrough / nextRealm / nextThreshold
     */
    @Transactional
    public Map<String, Object> settle(String username, String methodKey, String methodName,
                                      String outcome, long delta,
                                      long costStones, long costContribution, String story) {
        String name = requireUsername(username);
        UserProfile profile = requireProfile(name);

        long current = profile.getCultivation() == null ? 0L : profile.getCultivation();
        long after = Math.max(0, current + delta);

        String fromRealm = profile.getRealm() == null ? "炼气" : profile.getRealm();
        int fromIdx = Math.max(0, REALMS.indexOf(fromRealm));
        int finalIdx = Math.max(fromIdx, computedRealmIndex(after));
        boolean breakthrough = finalIdx > fromIdx;
        String toRealm = REALMS.get(finalIdx);

        userProfileMapper.update(null, new UpdateWrapper<UserProfile>()
                .set("cultivation", after)
                .set("realm", toRealm)
                .eq("id", profile.getId()));

        CultivationLog log = new CultivationLog();
        log.setUsername(name);
        log.setMethodKey(methodKey);
        log.setMethodName(methodName);
        log.setOutcome(outcome);
        log.setDelta(delta);
        log.setCostStones(costStones);
        log.setCostContribution(costContribution);
        log.setStory(story);
        log.setCreateTime(LocalDateTime.now());
        cultivationLogMapper.insert(log);

        Map<String, Object> data = new LinkedHashMap<>();
        data.put("cultivation", after);
        data.put("realm", toRealm);
        data.put("breakthrough", breakthrough);
        data.put("fromRealm", fromRealm);
        data.put("toRealm", toRealm);
        data.put("nextRealm", finalIdx < REALMS.size() - 1 ? REALMS.get(finalIdx + 1) : null);
        data.put("nextThreshold", finalIdx < REALMS.size() - 1 ? REALM_THRESHOLD[finalIdx + 1] : -1);
        return data;
    }

    // ==========================================================
    // 四、魔功殿总览（修为 / 余额 / 法门冷却 / 修炼记录）
    // ==========================================================

    /**
     * 魔功殿首页数据：修为进度 + 灵石/贡献余额 + 五法门（含各自调息剩余秒数）+ 最近修炼记录。
     */
    public Map<String, Object> info(String username) {
        String name = requireUsername(username);
        UserProfile profile = requireProfile(name);

        long current = profile.getCultivation() == null ? 0L : profile.getCultivation();
        String realm = profile.getRealm() == null ? "炼气" : profile.getRealm();
        int idx = Math.max(0, REALMS.indexOf(realm));

        long stonesBalance = stonesBalance(name);
        long contributionBalance = contributionBalance(name);

        List<Map<String, Object>> methods = new ArrayList<>();
        for (MethodDef def : METHODS.values()) {
            Map<String, Object> m = new LinkedHashMap<>();
            m.put("key", def.key());
            m.put("name", def.name());
            m.put("icon", def.icon());
            m.put("desc", def.desc());
            m.put("riskText", def.riskText());
            m.put("costStones", def.costStones());
            m.put("costContribution", def.costContribution());
            m.put("cooldownSeconds", def.cooldownSeconds());
            m.put("remainSeconds", remainSeconds(name, def));
            methods.add(m);
        }

        // 最近修炼记录
        List<CultivationLog> logs = cultivationLogMapper.selectList(
                new LambdaQueryWrapper<CultivationLog>()
                        .eq(CultivationLog::getUsername, name)
                        .orderByDesc(CultivationLog::getCreateTime)
                        .orderByDesc(CultivationLog::getId)
                        .last("LIMIT " + MAX_LIST));
        List<Map<String, Object>> logList = new ArrayList<>();
        for (CultivationLog l : logs) {
            Map<String, Object> item = new LinkedHashMap<>();
            item.put("methodName", l.getMethodName());
            item.put("outcome", l.getOutcome());
            item.put("outcomeText", outcomeText(l.getOutcome()));
            item.put("delta", l.getDelta() == null ? 0L : l.getDelta());
            item.put("costStones", l.getCostStones() == null ? 0L : l.getCostStones());
            item.put("costContribution", l.getCostContribution() == null ? 0L : l.getCostContribution());
            item.put("story", l.getStory());
            item.put("createTime", l.getCreateTime());
            logList.add(item);
        }

        Map<String, Object> data = new LinkedHashMap<>();
        data.put("realm", realm);
        data.put("cultivation", current);
        data.put("realmIndex", idx);
        data.put("realmThreshold", REALM_THRESHOLD[idx]);
        data.put("nextRealm", idx < REALMS.size() - 1 ? REALMS.get(idx + 1) : null);
        data.put("nextThreshold", idx < REALMS.size() - 1 ? REALM_THRESHOLD[idx + 1] : null);
        data.put("stonesBalance", stonesBalance);
        data.put("contributionBalance", contributionBalance);
        data.put("methods", methods);
        data.put("logs", logList);
        return data;
    }

    // ==========================================================
    // 五、内部工具
    // ==========================================================

    /** 掷本次修炼结果 */
    private String rollOutcome(String key) {
        ThreadLocalRandom rnd = ThreadLocalRandom.current();
        return switch (key) {
            case "mogu", "xuedan" -> "good";
            case "xueji" -> rnd.nextInt(100) < 20 ? "backlash" : "good";
            case "duoshe" -> rnd.nextInt(100) < 40 ? "backlash" : "great";
            case "tuntian" -> {
                int r = rnd.nextInt(100);
                yield r < 30 ? "great" : (r < 80 ? "good" : "backlash");
            }
            default -> "good";
        };
    }

    /** 掷本次修为增减（反噬为负） */
    private long rollDelta(String key, String outcome) {
        ThreadLocalRandom rnd = ThreadLocalRandom.current();
        return switch (key) {
            case "mogu" -> rnd.nextLong(80, 201);
            case "xuedan" -> rnd.nextLong(150, 351);
            case "xueji" -> outcome.equals("backlash") ? -rnd.nextLong(100, 401) : rnd.nextLong(400, 901);
            case "duoshe" -> outcome.equals("backlash") ? -rnd.nextLong(300, 801) : rnd.nextLong(800, 2001);
            case "tuntian" -> switch (outcome) {
                case "great" -> rnd.nextLong(3000, 6001);
                case "backlash" -> -rnd.nextLong(1000, 2501);
                default -> rnd.nextLong(500, 1501);
            };
            default -> 0;
        };
    }

    /** 抽一段修炼异象文案，{n} 替换为增减绝对值 */
    private String pickStory(String key, String outcome, long delta) {
        List<String> pool = STORIES.getOrDefault(key, Map.of()).getOrDefault(outcome, List.of());
        if (pool.isEmpty()) {
            return outcome.equals("backlash")
                    ? "魔气逆行，修为 -" + Math.abs(delta) + "。"
                    : "魔气入体，修为 +" + delta + "。";
        }
        return pool.get(ThreadLocalRandom.current().nextInt(pool.size()))
                .replace("{n}", String.valueOf(Math.abs(delta)));
    }

    private String outcomeText(String outcome) {
        return switch (outcome) {
            case "great" -> "大成";
            case "backlash" -> "反噬";
            default -> "小成";
        };
    }

    /** 按修为值计算应处境界下标 */
    private int computedRealmIndex(long cultivation) {
        int idx = 0;
        for (int i = 0; i < REALM_THRESHOLD.length; i++) {
            if (cultivation >= REALM_THRESHOLD[i]) {
                idx = i;
            }
        }
        return idx;
    }

    /** 某法门剩余调息秒数（0 = 可修炼） */
    private long remainSeconds(String username, MethodDef def) {
        return remainSecondsOf(username, def.key(), def.cooldownSeconds());
    }

    /** 通用调息：某 methodKey 最近一条记录距今不足 cooldownSeconds 秒，则返回剩余秒数 */
    public long remainSecondsOf(String username, String methodKey, int cooldownSeconds) {
        if (cooldownSeconds <= 0) {
            return 0;
        }
        CultivationLog latest = cultivationLogMapper.selectOne(
                new LambdaQueryWrapper<CultivationLog>()
                        .eq(CultivationLog::getUsername, username)
                        .eq(CultivationLog::getMethodKey, methodKey)
                        .orderByDesc(CultivationLog::getCreateTime)
                        .orderByDesc(CultivationLog::getId)
                        .last("LIMIT 1"));
        if (latest == null || latest.getCreateTime() == null) {
            return 0;
        }
        long passed = Duration.between(latest.getCreateTime(), LocalDateTime.now()).getSeconds();
        return Math.max(0, cooldownSeconds - passed);
    }

    /** 可用灵石 = 任务累计所得 + 血辩台香火分成 - 修炼/论道已耗 */
    public long stonesBalance(String username) {
        List<UserQuest> done = userQuestMapper.selectList(
                new LambdaQueryWrapper<UserQuest>()
                        .eq(UserQuest::getUsername, username)
                        .eq(UserQuest::getStatus, 1));
        long total = done.stream()
                .mapToLong(q -> q.getRewardStones() == null ? 0L : q.getRewardStones())
                .sum();
        Long spent = spentSum(username, "cost_stones");
        return total + forumIncome(username, "stones") - spent;
    }

    /** 可用贡献 = 任务累计所得 + 血辩台香火分成 - 修炼/论道已耗（功法阁参悟另由洞府扣） */
    public long contributionBalance(String username) {
        List<UserQuest> done = userQuestMapper.selectList(
                new LambdaQueryWrapper<UserQuest>()
                        .eq(UserQuest::getUsername, username)
                        .eq(UserQuest::getStatus, 1));
        long total = done.stream()
                .mapToLong(q -> q.getRewardContribution() == null ? 0L : q.getRewardContribution())
                .sum();
        Long spent = spentSum(username, "cost_contribution");
        return total + forumIncome(username, "contribution") - spent;
    }

    /** 血辩台收益合计（论坛_income 表，column 限 stones/contribution） */
    private long forumIncome(String username, String column) {
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

    /** 修炼日志中某消耗列合计（SQL 聚合防溢出） */
    private Long spentSum(String username, String column) {
        // 列名来自内部调用，无注入风险
        Map<String, Object> row = cultivationLogMapper.selectMaps(
                new com.baomidou.mybatisplus.core.conditions.query.QueryWrapper<CultivationLog>()
                        .select("IFNULL(SUM(" + column + "), 0) AS total")
                        .eq("username", username))
                .stream().findFirst().orElse(null);
        if (row == null || row.get("total") == null) {
            return 0L;
        }
        return Long.parseLong(String.valueOf(row.get("total")));
    }

    /** 读取档案，不存在则建默认档案（与洞府规则一致）；血辩台也要用 */
    public UserProfile requireProfile(String username) {
        UserProfile profile = userProfileMapper.selectOne(
                new LambdaQueryWrapper<UserProfile>().eq(UserProfile::getUsername, username));
        if (profile == null) {
            profile = new UserProfile();
            profile.setUsername(username);
            profile.setNickname(username);
            profile.setIcon("🧙");
            profile.setRealm("炼气");
            profile.setHall("血煞堂");
            profile.setBio("初入魔宗，道心未定。");
            profile.setCultivation(0L);
            userProfileMapper.insert(profile);
            profile = userProfileMapper.selectById(profile.getId());
        }
        return profile;
    }

    private String requireUsername(String username) {
        if (username == null || username.isBlank()) {
            throw new IllegalArgumentException("用户名不能为空");
        }
        return username.trim();
    }
}
