package com.fenglin.springboottest.util;

import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

/**
 * 境界唯一口径：十大境界 + 境界层次 + 四层辈分。
 *
 * <p>分层（由低到高）：</p>
 * <ul>
 *   <li>弟子境 disciple：炼气 / 筑基 / 金丹</li>
 *   <li>真传境 trueDisciple：元婴 / 化神</li>
 *   <li>长老境 elder：炼虚 / 合体 / 大乘 / 渡劫</li>
 *   <li>至尊境 supreme：魔尊</li>
 * </ul>
 *
 * <p>分榜：长老境 + 至尊境 → 长老榜；弟子境 + 真传境 → 弟子榜。
 * 每个大境界再分小层次（炼气一层~九层、筑基初期~巅峰、炼虚小成~巅峰、魔尊一重~九重…），
 * 玩家按修为在区间内折算层次。修炼突破、任务门槛、档案校验、榜单展示统一引用这里。</p>
 */
public final class RealmTier {

    /** 十大境界，由低到高（唯一顺序来源） */
    public static final List<String> REALMS = List.of(
            "炼气", "筑基", "金丹", "元婴", "化神", "炼虚", "合体", "大乘", "渡劫", "魔尊");

    /** 各境界修为门槛（下标对应 REALMS）：达到门槛即晋升该境界 */
    public static final long[] REALM_THRESHOLD = {
            0, 1000, 5000, 15000, 40000, 100000, 250000, 600000, 1500000, 5000000
    };

    public static final String DISCIPLE = "disciple";
    public static final String TRUE_DISCIPLE = "trueDisciple";
    public static final String ELDER = "elder";
    public static final String SUPREME = "supreme";

    /** 入长老榜的最低境界（用于前端「突破至 X 即可升榜」提示） */
    public static final String ELDER_MIN_REALM = "炼虚";

    /** 每个大境界内部的小层次，由低到高 */
    public static final Map<String, List<String>> STAGES = new LinkedHashMap<>();
    static {
        STAGES.put("炼气", List.of("一层", "二层", "三层", "四层", "五层", "六层", "七层", "八层", "九层"));
        STAGES.put("筑基", List.of("初期", "中期", "后期", "巅峰"));
        STAGES.put("金丹", List.of("初期", "中期", "后期", "巅峰"));
        STAGES.put("元婴", List.of("初期", "中期", "后期", "巅峰"));
        STAGES.put("化神", List.of("初期", "中期", "后期", "巅峰"));
        STAGES.put("炼虚", List.of("小成", "大成", "圆满", "巅峰"));
        STAGES.put("合体", List.of("初期", "中期", "后期", "巅峰"));
        STAGES.put("大乘", List.of("初期", "中期", "后期", "巅峰"));
        STAGES.put("渡劫", List.of("一劫", "三劫", "五劫", "七劫", "九劫"));
        STAGES.put("魔尊", List.of("一重", "三重", "五重", "七重", "九重"));
    }

    private static final Map<String, String> TIER_OF = Map.ofEntries(
            Map.entry("炼气", DISCIPLE),
            Map.entry("筑基", DISCIPLE),
            Map.entry("金丹", DISCIPLE),
            Map.entry("元婴", TRUE_DISCIPLE),
            Map.entry("化神", TRUE_DISCIPLE),
            Map.entry("炼虚", ELDER),
            Map.entry("合体", ELDER),
            Map.entry("大乘", ELDER),
            Map.entry("渡劫", ELDER),
            Map.entry("魔尊", SUPREME));

    private static final Map<String, String> LABEL_OF = Map.of(
            DISCIPLE, "弟子境",
            TRUE_DISCIPLE, "真传境",
            ELDER, "长老境",
            SUPREME, "至尊境");

    private RealmTier() {
    }

    /** 境界 → 辈分层 key；未知境界按弟子境兜底 */
    public static String tierOf(String realm) {
        String tier = TIER_OF.get(realm == null ? "" : realm.trim());
        return tier == null ? DISCIPLE : tier;
    }

    /** 境界 → 辈分层中文标签 */
    public static String labelOf(String realm) {
        return label(tierOf(realm));
    }

    /** 辈分 key → 中文标签 */
    public static String label(String tier) {
        return LABEL_OF.getOrDefault(tier, "弟子境");
    }

    /** 是否属于长老榜（长老境 + 至尊境） */
    public static boolean isElder(String realm) {
        String tier = tierOf(realm);
        return ELDER.equals(tier) || SUPREME.equals(tier);
    }

    /** 境界下标，未知返回 0 */
    public static int ordinal(String realm) {
        int idx = REALMS.indexOf(realm == null ? "" : realm.trim());
        return idx < 0 ? 0 : idx;
    }

    /** 是否十大境界之一 */
    public static boolean valid(String realm) {
        return realm != null && REALMS.contains(realm.trim());
    }

    /** 某境界的小层次列表（未知境界返回空） */
    public static List<String> stagesOf(String realm) {
        return STAGES.getOrDefault(realm == null ? "" : realm.trim(), List.of());
    }

    /**
     * 按修为在当前大境界区间内折算小层次。
     * 末境界（魔尊）以上按固定 100 万一重递进，九重封顶。
     */
    public static String stageOf(String realm, long cultivation) {
        int idx = ordinal(realm);
        List<String> stages = stagesOf(realm);
        if (stages.isEmpty()) {
            return "";
        }
        long lo = REALM_THRESHOLD[idx];
        long hi = idx + 1 < REALM_THRESHOLD.length ? REALM_THRESHOLD[idx + 1] : -1L;
        int seg;
        if (hi < 0) {
            seg = (int) ((cultivation - lo) / 1_000_000L);
        } else {
            long span = Math.max(1L, hi - lo);
            seg = (int) ((cultivation - lo) * stages.size() / span);
        }
        seg = Math.max(0, Math.min(stages.size() - 1, seg));
        return stages.get(seg);
    }

    /** 完整境界展示：境界 + 层次，如「炼气七层」「炼虚小成」「魔尊九重」 */
    public static String fullRealm(String realm, String stage) {
        String r = realm == null || realm.isBlank() ? "炼气" : realm.trim();
        return stage == null || stage.isBlank() ? r : r + stage;
    }

    /** 按修为折算完整境界 */
    public static String fullRealm(String realm, long cultivation) {
        return fullRealm(realm, stageOf(realm, cultivation));
    }

    /**
     * 「境界+层次」可比权重：大境界序号×100 + 层次序号。
     * 用于任务门槛比较：纯大境界（如「筑基」）按该境界第 0 层计，兼容旧数据。
     */
    public static int realmWeight(String realmWithStage) {
        if (realmWithStage == null || realmWithStage.isBlank()) {
            return 0;
        }
        String s = realmWithStage.trim();
        // 优先匹配最长的境界名（避免「元婴」被「元」之类前缀干扰）
        String realm = null;
        for (String r : REALMS) {
            if (s.startsWith(r)) {
                realm = r; // REALMS 由短到长，后者覆盖前者
            }
        }
        if (realm == null) {
            return 0;
        }
        int stageIdx = 0;
        String suffix = s.substring(realm.length()).trim();
        if (!suffix.isEmpty()) {
            List<String> stages = stagesOf(realm);
            int idx = stages.indexOf(suffix);
            stageIdx = idx < 0 ? 0 : idx;
        }
        return ordinal(realm) * 100 + stageIdx;
    }
}
