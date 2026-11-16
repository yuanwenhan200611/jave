package com.fenglin.springboottest.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableField;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

import java.time.LocalDateTime;

/**
 * 任务牌实体，对应数据库 login_db.quest 表。
 * 任务阁两大悬赏来源：
 *   · sect     宗门颁发，奖励贡献值 / 灵石（可兼得）
 *   · personal 个人发布，奖励天才地宝 / 法宝等（reward_item 描述）
 * 接取门槛：min_realm 修为限制 + max_accept 人数限制。
 */
@Data
@TableName("quest")
public class Quest {

    /** 主键，数据库自增 */
    @TableId(type = IdType.AUTO)
    private Long id;

    /** 类型：sect 宗门悬赏 / personal 个人悬赏 */
    private String questType;

    /** 发布人（宗门悬赏为 NULL，个人悬赏为用户名） */
    private String publisher;

    /** 任务名 */
    private String title;

    /** 任务详情 */
    private String description;

    /** 分类：斩妖/夺宝/护送/炼丹/寻物/戒律/其它 */
    private String category;

    /** 难度：简单/普通/困难/地狱 */
    private String difficulty;

    /** 修为门槛：炼气~魔尊，低于该境界不可接取 */
    private String minRealm;

    /** 接取名额（完成/进行中占用名额，放弃后释放） */
    private Integer maxAccept;

    /** 贡献值奖励（宗门悬赏） */
    private Long rewardContribution;

    /** 灵石奖励（宗门悬赏，可与贡献值兼得） */
    private Long rewardStones;

    /** 物品奖励（个人悬赏：天才地宝/法宝等） */
    private String rewardItem;

    /** 图标（emoji） */
    private String icon;

    /** 状态：1 上架 / 0 下架 */
    private Integer status;

    /** 累计接取次数（热度展示） */
    private Long acceptCount;

    /** 发布时间 */
    private LocalDateTime createTime;

    // ===== 以下为查询时的计算字段，不入库 =====

    /** 当前占用的接取名额（进行中 + 已完成的去重人数） */
    @TableField(exist = false)
    private Long currentAcceptors;

    /** 名额是否已满 */
    @TableField(exist = false)
    private Boolean full;
}
