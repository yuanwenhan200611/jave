package com.fenglin.springboottest.service;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.core.conditions.update.UpdateWrapper;
import com.fenglin.springboottest.entity.CultivationLog;
import com.fenglin.springboottest.entity.ForumIncome;
import com.fenglin.springboottest.entity.ForumLike;
import com.fenglin.springboottest.entity.ForumPost;
import com.fenglin.springboottest.mapper.CultivationLogMapper;
import com.fenglin.springboottest.mapper.ForumIncomeMapper;
import com.fenglin.springboottest.mapper.ForumLikeMapper;
import com.fenglin.springboottest.mapper.ForumPostMapper;
import com.fenglin.springboottest.vo.PageResult;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.concurrent.ThreadLocalRandom;
import java.util.stream.Collectors;

/**
 * 血辩台服务（原「论道」魔宗化改造）——论道即修炼，每一笔都有真实结算：
 *
 *   开坛讲道  花 20 灵石设坛 → 讲道梳理己身道法，修为 +60~150（60s 调息）
 *   香火供奉  花 10 灵石上香听道 → 自己修为 +15~40，帖主得 5 贡献分成（每人每帖一次）
 *   驳道      押 50 修为上台论剑 → 45% 压服对方吞其道韵 +120~300，败则道心受挫 -50（每人每帖一次）
 *
 * 消耗与修为增减统一落 cultivation_log（复用 CultivationService.settle），
 * 帖主分成落 forum_income，动作记录落 forum_like（UNIQUE 防重）。
 */
@Service
public class ForumService {

    private static final long DEFAULT_PAGE_SIZE = 10L;
    private static final long MAX_PAGE_SIZE = 50L;
    private static final int MAX_TITLE_LENGTH = 100;
    private static final int MAX_CONTENT_LENGTH = 2000;
    private static final int MAX_AUTHOR_LENGTH = 50;

    /** 开坛讲道费用（灵石）与调息（秒） */
    private static final long ALTAR_COST_STONES = 20L;
    private static final int ALTAR_COOLDOWN = 60;
    /** 香火供奉费用（灵石）与帖主分成（贡献值） */
    private static final long INCENSE_COST_STONES = 10L;
    private static final long INCENSE_AUTHOR_CONTRIBUTION = 5L;
    /** 驳道押注修为 / 成功率 / 成功收益区间 */
    private static final long COUNTER_STAKE = 50L;
    private static final int COUNTER_WIN_RATE = 45;

    private final ForumPostMapper forumPostMapper;
    private final ForumLikeMapper forumLikeMapper;
    private final ForumIncomeMapper forumIncomeMapper;
    private final CultivationLogMapper cultivationLogMapper;
    private final CultivationService cultivationService;

    public ForumService(ForumPostMapper forumPostMapper,
                        ForumLikeMapper forumLikeMapper,
                        ForumIncomeMapper forumIncomeMapper,
                        CultivationLogMapper cultivationLogMapper,
                        CultivationService cultivationService) {
        this.forumPostMapper = forumPostMapper;
        this.forumLikeMapper = forumLikeMapper;
        this.forumIncomeMapper = forumIncomeMapper;
        this.cultivationLogMapper = cultivationLogMapper;
        this.cultivationService = cultivationService;
    }

    // ==========================================================
    // 一、帖子列表
    // ==========================================================

    /**
     * 帖子分页列表 + 当前用户在血辩台的动作状态。
     *
     * @param username 当前登录人（可空）；非空时返回 incensedIds / counteredIds 供前端禁用按钮
     * @param sort     new（默认，按发帖时间倒序）/ hot（按道心相印数倒序）
     */
    public Map<String, Object> page(String sort, Integer pageNo, Integer pageSize, String username) {
        long p = pageNo == null || pageNo < 1 ? 1 : pageNo;
        long s = pageSize == null || pageSize < 1 ? DEFAULT_PAGE_SIZE : Math.min(pageSize, MAX_PAGE_SIZE);

        boolean byHot = "hot".equalsIgnoreCase(sort);
        LambdaQueryWrapper<ForumPost> qw = new LambdaQueryWrapper<ForumPost>()
                .eq(ForumPost::getStatus, 1)
                .orderByDesc(byHot ? ForumPost::getLikes : ForumPost::getCreateTime)
                .orderByDesc(ForumPost::getId);

        Long totalObj = forumPostMapper.selectCount(
                new LambdaQueryWrapper<ForumPost>().eq(ForumPost::getStatus, 1));
        long total = totalObj == null ? 0L : totalObj;

        List<ForumPost> list = new java.util.ArrayList<>();
        if (total > 0) {
            long offset = (p - 1) * s;
            if (offset < total) {
                list = forumPostMapper.selectList(qw.last("LIMIT " + s + " OFFSET " + offset));
            }
        }
        PageResult<ForumPost> pageResult = PageResult.of(list, total, p, s);

        Map<String, Object> data = new LinkedHashMap<>();
        data.put("list", pageResult.getList());
        data.put("total", pageResult.getTotal());
        data.put("page", pageResult.getPage());
        data.put("size", pageResult.getSize());
        data.put("pages", pageResult.getPages());

        String name = trimToNull(username);
        if (name != null && !list.isEmpty()) {
            List<Long> ids = list.stream().map(ForumPost::getId).collect(Collectors.toList());
            List<ForumLike> acts = forumLikeMapper.selectList(
                    new LambdaQueryWrapper<ForumLike>()
                            .eq(ForumLike::getUsername, name)
                            .in(ForumLike::getPostId, ids));
            data.put("incensedIds", acts.stream()
                    .filter(a -> "incense".equals(a.getAction()))
                    .map(ForumLike::getPostId).collect(Collectors.toList()));
            data.put("counteredIds", acts.stream()
                    .filter(a -> "counter".equals(a.getAction()))
                    .map(ForumLike::getPostId).collect(Collectors.toList()));
        } else {
            data.put("incensedIds", List.of());
            data.put("counteredIds", List.of());
        }
        return data;
    }

    // ==========================================================
    // 二、开坛讲道（发帖 = 修炼）
    // ==========================================================

    /**
     * 开坛讲道：校验调息与灵石 → 落帖 → 讲道梳理己身道法，修为 +60~150。
     */
    @Transactional
    public Map<String, Object> create(String author, String title, String content) {
        String a = normalize(author, null, MAX_AUTHOR_LENGTH);
        String t = normalize(title, null, MAX_TITLE_LENGTH);
        String c = normalize(content, null, MAX_CONTENT_LENGTH);
        if (a == null) {
            throw new IllegalArgumentException("落款道友不可为空");
        }
        if (t == null) {
            throw new IllegalArgumentException("帖名不能为空");
        }
        if (c == null) {
            throw new IllegalArgumentException("正文不能为空");
        }

        // 1. 调息：60 秒内开过坛，魔音未复
        long remain = cultivationService.remainSecondsOf(a, "forum_post", ALTAR_COOLDOWN);
        if (remain > 0) {
            throw new IllegalArgumentException("魔音未复：开坛讲道还需调息 " + remain + " 秒");
        }

        // 2. 设坛香火：20 灵石
        long stones = cultivationService.stonesBalance(a);
        if (stones < ALTAR_COST_STONES) {
            throw new IllegalArgumentException("灵石不够：设坛需 " + ALTAR_COST_STONES + " 灵石，你只剩 "
                    + stones + "。先去任务阁接几单悬赏吧。");
        }

        // 3. 落帖
        ForumPost post = new ForumPost();
        post.setAuthor(a);
        post.setTitle(t);
        post.setContent(c);
        post.setViews(0L);
        post.setLikes(0L);
        post.setCounters(0L);
        post.setStatus(1);
        post.setCreateTime(LocalDateTime.now());
        forumPostMapper.insert(post);

        // 4. 讲道收益：梳理己身道法，修为 +60~150（消耗记入 cultivation_log）
        long delta = ThreadLocalRandom.current().nextLong(60, 151);
        String story = pickStory(STORIES_ALTAR, "坛开三尺，魔音贯殿。你讲道半个时辰，讲到痛处，自己先悟了三分——修为 +" + delta + "。", delta);
        Map<String, Object> settled = cultivationService.settle(
                a, "forum_post", "开坛讲道", "good", delta, ALTAR_COST_STONES, 0, story);

        Map<String, Object> data = new LinkedHashMap<>();
        data.put("post", post);
        data.put("action", "altar");
        data.put("delta", delta);
        data.put("costStones", ALTAR_COST_STONES);
        data.put("story", story);
        data.putAll(settled);
        return data;
    }

    // ==========================================================
    // 三、香火供奉（原点赞，如今真实入账）
    // ==========================================================

    /**
     * 香火供奉：供奉者花 10 灵石听道，修为 +15~40；帖主得 5 贡献分成。
     * 每人每帖限一次（forum_like UNIQUE 兜底）。
     */
    @Transactional
    public Map<String, Object> incense(Long id, String username) {
        if (id == null) {
            throw new IllegalArgumentException("帖子 id 不能为空");
        }
        String name = trimToNull(username);
        if (name == null) {
            throw new IllegalArgumentException("用户名不能为空");
        }
        ForumPost post = requirePost(id);

        if (name.equals(post.getAuthor())) {
            throw new IllegalArgumentException("自家坛口的香火，自己烧不算数");
        }
        if (hasActed(id, name, "incense")) {
            throw new IllegalArgumentException("此坛你已供奉过，一人一炷香");
        }

        long stones = cultivationService.stonesBalance(name);
        if (stones < INCENSE_COST_STONES) {
            throw new IllegalArgumentException("灵石不够：一炷香火需 " + INCENSE_COST_STONES
                    + " 灵石，你只剩 " + stones + "。");
        }

        // 供奉者：听道有得
        long delta = ThreadLocalRandom.current().nextLong(15, 41);
        String story = pickStory(STORIES_INCENSE, "你焚香拜坛，静听妙法，魔气随香入体——修为 +" + delta + "。", delta);
        Map<String, Object> settled = cultivationService.settle(
                name, "forum_incense", "香火供奉", "good", delta, INCENSE_COST_STONES, 0, story);

        // 记动作 + 赞数
        forumLikeMapper.insert(newLike(id, name, "incense"));
        forumPostMapper.update(null, new UpdateWrapper<ForumPost>()
                .setSql("likes = likes + 1")
                .eq("id", id));

        // 帖主：香火分成 5 贡献（保证其档案存在）
        cultivationService.requireProfile(post.getAuthor());
        forumIncomeMapper.insert(newIncome(post.getAuthor(), INCENSE_AUTHOR_CONTRIBUTION, "incense"));

        Map<String, Object> data = new LinkedHashMap<>();
        data.put("likes", (post.getLikes() == null ? 0L : post.getLikes()) + 1);
        data.put("action", "incense");
        data.put("delta", delta);
        data.put("costStones", INCENSE_COST_STONES);
        data.put("authorContribution", INCENSE_AUTHOR_CONTRIBUTION);
        data.put("story", story);
        data.putAll(settled);
        return data;
    }

    // ==========================================================
    // 四、驳道（押修为上台论剑）
    // ==========================================================

    /**
     * 驳道：押 50 修为上台论剑。45% 压服对方吞其道韵 +120~300，败则道心受挫 -50。
     * 每人每帖限一次；修为不足 50 者没资格上台。
     */
    @Transactional
    public Map<String, Object> counter(Long id, String username) {
        if (id == null) {
            throw new IllegalArgumentException("帖子 id 不能为空");
        }
        String name = trimToNull(username);
        if (name == null) {
            throw new IllegalArgumentException("用户名不能为空");
        }
        ForumPost post = requirePost(id);

        if (name.equals(post.getAuthor())) {
            throw new IllegalArgumentException("自己驳自己的坛，算什么血辩");
        }
        if (hasActed(id, name, "counter")) {
            throw new IllegalArgumentException("此坛你已驳过一次，得饶人处且饶人");
        }

        var profile = cultivationService.requireProfile(name);
        long cultivation = profile.getCultivation() == null ? 0L : profile.getCultivation();
        if (cultivation < COUNTER_STAKE) {
            throw new IllegalArgumentException("修为不足：上台驳道需押 " + COUNTER_STAKE
                    + " 修为，你只有 " + cultivation + "。先去魔功殿苦修吧。");
        }

        // 掷结果
        boolean win = ThreadLocalRandom.current().nextInt(100) < COUNTER_WIN_RATE;
        long delta;
        String outcome;
        String story;
        if (win) {
            delta = ThreadLocalRandom.current().nextLong(120, 301);
            outcome = "great";
            story = pickStory(STORIES_COUNTER_WIN, "台上三个回合，你一句「歪理」砸得对方哑口无言。道韵被你当场吞了一道——修为 +" + delta + "。", delta);
        } else {
            delta = -COUNTER_STAKE;
            outcome = "backlash";
            story = pickStory(STORIES_COUNTER_LOSE, "你登台便放豪言，结果被对方反手引经据典驳得体无完肤。押上的 50 修为当场作废，道心受挫。", delta);
        }

        Map<String, Object> settled = cultivationService.settle(
                name, "forum_counter", "血辩驳道", outcome, delta, 0, 0, story);

        // 记动作 + 被驳次数
        forumLikeMapper.insert(newLike(id, name, "counter"));
        forumPostMapper.update(null, new UpdateWrapper<ForumPost>()
                .setSql("counters = counters + 1")
                .eq("id", id));

        Map<String, Object> data = new LinkedHashMap<>();
        data.put("action", "counter");
        data.put("win", win);
        data.put("outcome", outcome);
        data.put("delta", delta);
        data.put("counters", (post.getCounters() == null ? 0L : post.getCounters()) + 1);
        data.put("story", story);
        data.putAll(settled);
        return data;
    }

    // ==========================================================
    // 五、内部工具
    // ==========================================================

    private ForumPost requirePost(Long id) {
        ForumPost post = forumPostMapper.selectById(id);
        if (post == null || post.getStatus() == null || post.getStatus() != 1) {
            throw new IllegalArgumentException("帖子不存在或已被封禁");
        }
        return post;
    }

    private boolean hasActed(Long postId, String username, String action) {
        return forumLikeMapper.selectCount(new LambdaQueryWrapper<ForumLike>()
                .eq(ForumLike::getPostId, postId)
                .eq(ForumLike::getUsername, username)
                .eq(ForumLike::getAction, action)) > 0;
    }

    private ForumLike newLike(Long postId, String username, String action) {
        ForumLike like = new ForumLike();
        like.setPostId(postId);
        like.setUsername(username);
        like.setAction(action);
        like.setCreateTime(LocalDateTime.now());
        return like;
    }

    private ForumIncome newIncome(String username, long contribution, String source) {
        ForumIncome income = new ForumIncome();
        income.setUsername(username);
        income.setStones(0L);
        income.setContribution(contribution);
        income.setSource(source);
        income.setCreateTime(LocalDateTime.now());
        return income;
    }

    /** 抽一段异象文案池 */
    private String pickStory(List<String> pool, String fallback, long delta) {
        if (pool == null || pool.isEmpty()) {
            return fallback.replace("{n}", String.valueOf(Math.abs(delta)));
        }
        return pool.get(ThreadLocalRandom.current().nextInt(pool.size()))
                .replace("{n}", String.valueOf(Math.abs(delta)));
    }

    /** 去空白 + 截断；blank 返回 null */
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

    private String trimToNull(String s) {
        if (s == null || s.isBlank()) {
            return null;
        }
        String v = s.trim();
        return v.isEmpty() ? null : v;
    }

    // ==========================================================
    // 六、异象文案池（{n} 替换为本次修为增减绝对值）
    // ==========================================================

    private static final List<String> STORIES_ALTAR = List.of(
            "坛开三尺，魔音贯殿。你讲道半个时辰，讲到痛处，自己先悟了三分——修为 +{n}。",
            "台下鸦雀无声，你讲得兴起，把压箱底的魔功门道拆解了一遍。拆到一半自己愣住：原来如此！修为 +{n}。",
            "血月当空，你借月色开坛论法。散场时收坛的手都在抖——不是累的，是悟的。修为 +{n}。",
            "你把自家魔功的破绽当众摊开来讲。讲完破绽，破绽就不再是破绽。修为 +{n}。");

    private static final List<String> STORIES_INCENSE = List.of(
            "你焚香拜坛，静听妙法，魔气随香入体——修为 +{n}。",
            "香火烧到一半，坛上那位讲到关键处。你一个激灵坐直了，这一炷香值回灵石——修为 +{n}。",
            "你跪听了一场讲道，起身时只觉周身魔气凝了一分。香灰落进袖口也没顾上掸。修为 +{n}。",
            "一炷香，一场道。你把听懂的半截反刍了三遍，修为 +{n}。");

    private static final List<String> STORIES_COUNTER_WIN = List.of(
            "台上三个回合，你一句「歪理」砸得对方哑口无言。道韵被你当场吞了一道——修为 +{n}。",
            "你引了三部魔典、两个旧案，把对方的立论拆得片甲不留。台下喝彩声里，你顺手把他的道韵吞了——修为 +{n}。",
            "对方讲到你第三问就变了脸色。你趁势追击，威压之下竟悟出几分门道——修为 +{n}。",
            "这一场赢得干脆。对方拱手认输时，他的道韵已经进了你的肚子。修为 +{n}。");

    private static final List<String> STORIES_COUNTER_LOSE = List.of(
            "你登台便放豪言，结果被对方反手引经据典驳得体无完肤。押上的 {n} 修为当场作废，道心受挫。",
            "三个回合，你被驳得哑口无言。台下一声「下去吧」，你灰溜溜下台——押注 {n} 修为，没了。",
            "你引的魔典记错了半句，被对方当场背出全文。押上的 {n} 修为化作对方坛前的一缕青烟。");

    /** 供日志统计使用（洞府口径一致） */
    public long countByMethod(String username, String methodKey) {
        Long n = cultivationLogMapper.selectCount(new LambdaQueryWrapper<CultivationLog>()
                .eq(CultivationLog::getUsername, username)
                .eq(CultivationLog::getMethodKey, methodKey));
        return n == null ? 0L : n;
    }
}
