package com.fenglin.springboottest.service;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.fenglin.springboottest.entity.Category;
import com.fenglin.springboottest.entity.ContentItem;
import com.fenglin.springboottest.entity.SectMember;
import com.fenglin.springboottest.entity.UserProfile;
import com.fenglin.springboottest.mapper.CategoryMapper;
import com.fenglin.springboottest.mapper.ContentItemMapper;
import com.fenglin.springboottest.mapper.SectMemberMapper;
import com.fenglin.springboottest.util.RealmTier;
import com.fenglin.springboottest.vo.RankEntryVO;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;
import java.util.*;
import java.util.concurrent.ThreadLocalRandom;

/**
 * 宗门模块服务：宗门榜 + 秘境探索。
 */
@Service
@RequiredArgsConstructor
public class SectService {

    /** 秘境探索的奇遇文案池（占位 {name} 会替换为秘境名） */
    private static final String[] ENCOUNTERS = {
            "你踏入{name}，脚下的白骨忽然齐齐睁眼——那是百年前闯关失败的道友，正用眼白向你示警。",
            "雾气在{name}深处散开，一具枯坐的骸骨面前摆着半卷残经，翻开一看，竟是你梦寐以求的功法后半部。",
            "{name}的石壁上血字未干：「勿贪」。你贪了。于是……故事变长了。",
            "忽然阴风四起，{name}尽头传来打斗声——两位化神修士正在争夺一株灵药，你悄悄绕行，捡走了他们忘在洞口的储物袋。",
            "你在{name}迷路三天，饿极之际啃了墙角一株赤色灵草，醒来时修为精进一层，头发全白了。",
            "{name}深处传来钟声，一声更比一声近。你循声而去，只见一口古钟倒扣在地，钟下压着一张字条：「勿掀」。",
            "你在{name}捡到一枚古玉，夜里玉中传来叹息。前半夜它教你功法，后半夜它讲它当年的故事，你听得哭了。",
            "一道黑影从{name}的阴影里掠过，留下八个字：「机缘已尽，速速离开」。你回头看时，影子和字都消失了。"
    };

    private final SectMemberMapper sectMemberMapper;
    private final CategoryMapper categoryMapper;
    private final ContentItemMapper contentItemMapper;
    private final HomeService homeService;
    private final ProfileService profileService;

    /** 玩家战力折算口径（与 AGENTS.md 同步）：修为×10 + 功法×2000 + 任务×1000 + 入宗底薪 */
    private static final long POWER_PER_CULTIVATION = 10L;
    private static final long POWER_PER_SKILL = 2000L;
    private static final long POWER_PER_QUEST = 1000L;
    private static final long POWER_BASE = 10000L;

    // ==========================================================
    // 一、宗门榜
    // ==========================================================

    /**
     * 宗门榜：NPC 弟子（sect_member）+ 当前登录玩家（实时折算）。
     *
     * @param username 登录名，为空则只返回 NPC（兼容旧调用）
     * @param sortBy   power（默认，战力降序）或 contribution（贡献降序）
     * @param tier     elder（长老榜）/ disciple（弟子榜）/ all（默认，全宗）
     */
    public List<RankEntryVO> rankBoard(String username, String sortBy, String tier) {
        List<RankEntryVO> entries = new ArrayList<>();
        for (SectMember m : sectMemberMapper.selectList(null)) {
            entries.add(RankEntryVO.from(m));
        }

        RankEntryVO me = buildMeEntry(username);
        if (me != null) {
            entries.add(me);
        }

        // 辈分分榜：长老榜 = 长老境 + 至尊境；弟子榜 = 弟子境 + 真传境
        if ("elder".equalsIgnoreCase(tier)) {
            entries.removeIf(e -> !e.isElder());
        } else if ("disciple".equalsIgnoreCase(tier)) {
            entries.removeIf(RankEntryVO::isElder);
        }

        Comparator<RankEntryVO> first;
        Comparator<RankEntryVO> second;
        if ("contribution".equalsIgnoreCase(sortBy)) {
            first = Comparator.comparingLong((RankEntryVO e) -> nz(e.getContribution())).reversed();
            second = Comparator.comparingLong((RankEntryVO e) -> nz(e.getPower())).reversed();
        } else {
            first = Comparator.comparingLong((RankEntryVO e) -> nz(e.getPower())).reversed();
            second = Comparator.comparingLong((RankEntryVO e) -> nz(e.getContribution())).reversed();
        }
        entries.sort(first.thenComparing(second).thenComparing(
                e -> e.getName() == null ? "" : e.getName()));
        return entries;
    }

    /** 兼容旧调用：全宗、按战力降序 */
    public List<RankEntryVO> rankBoard() {
        return rankBoard(null, "power", "all");
    }

    /** 兼容旧调用：全宗 */
    public List<RankEntryVO> rankBoard(String username, String sortBy) {
        return rankBoard(username, sortBy, "all");
    }

    /**
     * 把登录玩家折算成一条榜单记录。取数完全复用洞府口径，保证贡献值与修为一致。
     * 玩家不写 sect_member 表，避免污染种子数据；用户不存在/档案异常时静默跳过。
     */
    private RankEntryVO buildMeEntry(String username) {
        if (username == null || username.isBlank()) {
            return null;
        }
        String name = username.trim();
        try {
            Map<String, Object> data = profileService.getProfile(name);
            UserProfile profile = (UserProfile) data.get("profile");
            @SuppressWarnings("unchecked")
            Map<String, Object> stats = (Map<String, Object>) data.get("stats");
            @SuppressWarnings("unchecked")
            Map<String, Object> user = (Map<String, Object>) data.get("user");
            if (profile == null || stats == null) {
                return null;
            }

            long cultivation = nz(stats.get("cultivation"));
            long skillCount = nz(stats.get("skillCount"));
            long questDone = nz(stats.get("questDone"));
            long power = POWER_BASE
                    + cultivation * POWER_PER_CULTIVATION
                    + skillCount * POWER_PER_SKILL
                    + questDone * POWER_PER_QUEST;

            RankEntryVO vo = new RankEntryVO();
            vo.setId(-1L); // 玩家不在 sect_member 表中，用固定 id 便于前端 v-for
            vo.setName(isBlank(profile.getNickname()) ? name : profile.getNickname());
            String realm = isBlank(profile.getRealm()) ? "炼气" : profile.getRealm();
            String stage = RealmTier.stageOf(realm, cultivation);
            vo.setRealm(realm);
            vo.setStage(stage);
            vo.setRealmFull(RealmTier.fullRealm(realm, stage));
            vo.setTitle("本座");
            vo.setHall(isBlank(profile.getHall()) ? "血煞堂" : profile.getHall());
            vo.setPower(power);
            vo.setContribution(nz(stats.get("contributionTotal")));
            vo.setIcon(isBlank(profile.getIcon()) ? "🧙" : profile.getIcon());
            if (user != null && user.get("createdAt") instanceof LocalDateTime) {
                vo.setCreateTime((LocalDateTime) user.get("createdAt"));
            }
            vo.setMe(true);
            vo.setCultivation(cultivation);
            vo.setUsername(name);
            vo.setTier(RealmTier.tierOf(vo.getRealm()));
            vo.setTierLabel(RealmTier.labelOf(vo.getRealm()));
            vo.setElder(RealmTier.isElder(vo.getRealm()));
            return vo;
        } catch (Exception e) {
            // 用户不存在 / 表未就绪，不应拖垮整张榜单
            return null;
        }
    }

    /**
     * 各堂口及其人数（供前端堂口筛选 chips），包含当前玩家所在堂口。
     *
     * @param tier elder / disciple / all，与榜单保持一致
     */
    public Map<String, Long> hallStats(String username, String tier) {
        Map<String, Long> stats = new LinkedHashMap<>();
        for (RankEntryVO m : rankBoard(username, "power", tier)) {
            String hall = (m.getHall() == null || m.getHall().isBlank()) ? "无堂口" : m.getHall().trim();
            stats.merge(hall, 1L, Long::sum);
        }
        return stats;
    }

    /** 兼容旧调用：全宗堂口统计 */
    public Map<String, Long> hallStats(String username) {
        return hallStats(username, "all");
    }

    /** 兼容旧调用：仅 NPC 堂口统计 */
    public Map<String, Long> hallStats() {
        return hallStats(null, "all");
    }

    private static boolean isBlank(String s) {
        return s == null || s.isBlank();
    }

    /** Object → long，容忍 null / String / Number */
    private static long nz(Object v) {
        if (v == null) {
            return 0L;
        }
        if (v instanceof Number) {
            return ((Number) v).longValue();
        }
        try {
            return Long.parseLong(String.valueOf(v));
        } catch (NumberFormatException e) {
            return 0L;
        }
    }

    // ==========================================================
    // 二、秘境支持（pickSecretItem / encounterFor 供 SecretService 扣费探索复用；
    //     免费的 explore 已下线——探索秘境一律走 SecretService.roam，必收引路费）
    // ==========================================================

    /**
     * 随机挑选一个上架秘境条目（供随机探秘/扣费探索复用）。
     * 找不到顶级「秘境」分类或条目时返回 null。
     */
    public ContentItem pickSecretItem() {
        Category root = categoryMapper.selectOne(
                new LambdaQueryWrapper<Category>()
                        .eq(Category::getName, "秘境")
                        .eq(Category::getLevel, 1)
                        .last("LIMIT 1"));
        if (root == null) {
            return null;
        }
        List<Long> ids = homeService.descendantIdsIncludingSelf(root.getId());
        return contentItemMapper.selectList(
                        new LambdaQueryWrapper<ContentItem>()
                                .eq(ContentItem::getStatus, 1)
                                .in(ContentItem::getCategoryId, ids)
                                .last("ORDER BY RAND() LIMIT 1"))
                .stream().findFirst().orElse(null);
    }

    /** 随机奇遇文案（{name} 替换为秘境名） */
    public String encounterFor(ContentItem item) {
        return ENCOUNTERS[ThreadLocalRandom.current().nextInt(ENCOUNTERS.length)]
                .replace("{name}", item.getTitle() == null ? "秘境" : item.getTitle());
    }
}
