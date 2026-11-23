package com.fenglin.springboottest.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

import java.time.LocalDateTime;

/**
 * 坊市·在售货品实体，对应数据库 login_db.market_item 表。
 *
 * 坊市是魔宗唯一的「玩家 ↔ NPC」交易场：
 *   摊主（NPC：噬魂老魔 / 白骨夫人 / 鬼手药王 ……）摆摊卖货，
 *   弟子用灵石买下——法宝/残篇/神通入储物空间，功法免贡收录，丹药当场服用。
 *   卖光后由 MarketService 自动补货，坊市永不冷清。
 */
@Data
@TableName("market_item")
public class MarketItem {

    /** 主键，数据库自增 */
    @TableId(type = IdType.AUTO)
    private Long id;

    /** 摊主（NPC 名或用户名） */
    private String seller;

    /** 摊主类型：npc / user */
    private String sellerType;

    /** 货品名 */
    private String title;

    /** 货品介绍（摊主吆喝） */
    private String description;

    /** 类型：artifact 法宝 / technique 功法 / divine_ability 神通 / pill 丹药 */
    private String itemType;

    /** 品阶：黄阶 / 玄阶 / 地阶 / 天阶 */
    private String grade;

    /** 稀有度：common / uncommon / rare / epic / legendary */
    private String rarity;

    /** 展示图标 */
    private String icon;

    /** 玩家寄售关联 secret_reward.id（NPC 货为 null） */
    private Long rewardId;

    /** 售价（灵石） */
    private Long price;

    /** 状态：0 在售 / 1 已售 / 2 已撤单 */
    private Integer status;

    /** 买主（成交后回填） */
    private String buyer;

    /** 成交时间 */
    private LocalDateTime buyTime;

    /** 上架时间 */
    private LocalDateTime createTime;
}
