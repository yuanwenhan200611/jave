package com.fenglin.springboottest.service;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
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
