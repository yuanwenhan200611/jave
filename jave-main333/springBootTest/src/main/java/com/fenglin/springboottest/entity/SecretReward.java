package com.fenglin.springboottest.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

import java.time.LocalDateTime;

/**
 * 秘境·探索奖励实体，对应数据库 login_db.secret_reward 表。
 * 每次探索/首入秘境按秘境类型（幻境/上古/普通）与品阶掷奖励：
 *   灵石 / 贡献值（入 forum_income，source=secret）——
 *   修为（落 cultivation_log，methodKey=secret）——
 *   功法（免贡参悟，落 user_skill，cost=0）——
 *   残篇 / 法宝 / 神通 / 道心通明 等奇遇类（落本表留档）。
 */
@Data
@TableName("secret_reward")
public class SecretReward {

    /** 主键，数据库自增 */
    @TableId(type = IdType.AUTO)
    private Long id;

    /** 得主（关联 user.username） */
    private String username;

    /** 触发奖励的秘境条目 id（关联 content_item.id） */
    private Long itemId;

    /** 奖励类型：stones 灵石 / contribution 贡献值 / cultivation 修为 /
     *  technique 功法 / fragment 上古残篇 / artifact 法宝 /
     *  divine_ability 天赋神通 / dao_clarity 道心通明 */
    private String rewardType;

    /** 奖励名称（法宝名 / 功法名 / 神通名等快照） */
    private String rewardName;

    /** 稀有度：common 普通 / rare 稀有 / epic 史诗 / legendary 传说 */
    private String rarity;

    /** 数值奖励量（灵石 / 贡献值 / 修为），奇遇类为 0 */
    private Long amount;

    /** 奖励描述（奇遇文案） */
    private String detail;

    /** 入账时间 */
    private LocalDateTime createTime;
}
