package com.fenglin.springboottest.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

import java.time.LocalDateTime;

/**
 * 坊市·交易手札实体，对应数据库 login_db.market_order 表。
 * 每次买入 / 卖出各落一条流水，供「交易手札」面板回看。
 */
@Data
@TableName("market_order")
public class MarketOrder {

    /** 主键，数据库自增 */
    @TableId(type = IdType.AUTO)
    private Long id;

    /** 交易人（关联 user.username） */
    private String username;

    /** 方向：buy 购入 / sell 卖出 */
    private String tradeType;

    /** 货品名快照 */
    private String title;

    /** 货品类型快照 */
    private String itemType;

    /** 稀有度快照 */
    private String rarity;

    /** 成交价（灵石，买入为支出、卖出为所得） */
    private Long price;

    /** 对手方（NPC 摊主） */
    private String counterparty;

    /** 成交时间 */
    private LocalDateTime createTime;
}
