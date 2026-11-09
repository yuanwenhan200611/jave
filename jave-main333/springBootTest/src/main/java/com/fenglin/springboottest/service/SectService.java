package com.fenglin.springboottest.service;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.core.conditions.update.UpdateWrapper;
import com.fenglin.springboottest.entity.Category;
import com.fenglin.springboottest.entity.ContentItem;
import com.fenglin.springboottest.entity.SectMember;
import com.fenglin.springboottest.mapper.CategoryMapper;
import com.fenglin.springboottest.mapper.ContentItemMapper;
import com.fenglin.springboottest.mapper.SectMemberMapper;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

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

    // ==========================================================
    // 一、宗门榜
    // ==========================================================

    /**
     * 宗门榜：全体弟子按战力降序，并列时按贡献降序。
     */
    public List<SectMember> rankBoard() {
        return sectMemberMapper.selectList(
                new LambdaQueryWrapper<SectMember>()
                        .orderByDesc(SectMember::getPower)
                        .orderByDesc(SectMember::getContribution));
    }

    /**
     * 各堂口及其人数（供前端堂口筛选 chips）。
     */
    public Map<String, Long> hallStats() {
        List<SectMember> all = sectMemberMapper.selectList(null);
        Map<String, Long> stats = new LinkedHashMap<>();
        for (SectMember m : all) {
            String hall = (m.getHall() == null || m.getHall().isBlank()) ? "无堂口" : m.getHall().trim();
            stats.merge(hall, 1L, Long::sum);
        }
        return stats;
    }

    // ==========================================================
    // 二、秘境探索
    // ==========================================================

    /**
     * 秘境探索：从「秘境」顶级分类的全部子孙分类中随机抽一个秘境条目，
     * 浏览量 +1，并附一段随机奇遇文案。
     */
    public Map<String, Object> explore() {
        // 1. 找到顶级「秘境」分类
        Category root = categoryMapper.selectOne(
                new LambdaQueryWrapper<Category>()
                        .eq(Category::getName, "秘境")
                        .eq(Category::getLevel, 1)
                        .last("LIMIT 1"));
        if (root == null) {
            throw new IllegalArgumentException("宗门尚未开辟秘境");
        }

        // 2. 子孙分类范围内随机取一个上架秘境
        List<Long> ids = homeService.descendantIdsIncludingSelf(root.getId());
        ContentItem item = contentItemMapper.selectList(
                new LambdaQueryWrapper<ContentItem>()
                        .eq(ContentItem::getStatus, 1)
                        .in(ContentItem::getCategoryId, ids)
                        .last("ORDER BY RAND() LIMIT 1"))
                .stream().findFirst().orElse(null);
        if (item == null) {
            throw new IllegalArgumentException("秘境尚未收录任何洞天");
        }

        // 3. 浏览量 +1（SQL 自增防并发丢失）
        contentItemMapper.update(null, new UpdateWrapper<ContentItem>()
                .setSql("view_count = view_count + 1")
                .eq("id", item.getId()));

        // 4. 组装返回：条目信息 + 分类名 + 奇遇文案
        Map<Long, String> nameMap = new HashMap<>();
        for (Category c : categoryMapper.selectList(null)) {
            nameMap.put(c.getId(), c.getName());
        }
        String catName = nameMap.getOrDefault(item.getCategoryId(), "未分类");
        String encounter = ENCOUNTERS[ThreadLocalRandom.current().nextInt(ENCOUNTERS.length)]
                .replace("{name}", item.getTitle() == null ? "秘境" : item.getTitle());

        Map<String, Object> data = new LinkedHashMap<>();
        data.put("id", item.getId());
        data.put("title", item.getTitle());
        data.put("description", item.getDescription());
        data.put("grade", item.getGrade());
        data.put("icon", item.getIcon());
        data.put("categoryName", catName);
        data.put("viewCount", (item.getViewCount() == null ? 0L : item.getViewCount()) + 1);
        data.put("encounter", encounter);
        return data;
    }
}
