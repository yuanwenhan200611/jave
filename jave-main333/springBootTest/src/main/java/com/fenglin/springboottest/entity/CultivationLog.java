package com.fenglin.springboottest.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

import java.time.LocalDateTime;

/**
 * 魔功殿修炼记录实体，对应数据库 login_db.cultivation_log 表。
 * 记录每一次修炼的法门 / 结果 / 修为增减 / 消耗，供洞府统计与魔功殿冷却判定。
 */
@Data
@TableName("cultivation_log")
public class CultivationLog {

    /** 主键，数据库自增 */
    @TableId(type = IdType.AUTO)
    private Long id;

    /** 修炼人（关联 user.username） */
    private String username;

    /** 法门标识：mogu / xuedan / xueji / duoshe / tuntian */
    private String methodKey;

    /** 法门名快照 */
    private String methodName;

    /** 结果：great 大成 / good 小成 / backlash 反噬 */
    private String outcome;

    /** 本次修为增减（负数为反噬） */
    private Long delta;

    /** 消耗灵石 */
    private Long costStones;

    /** 消耗贡献值 */
    private Long costContribution;

    /** 修炼异象文案 */
    private String story;

    /** 修炼时间 */
    private LocalDateTime createTime;
}
