package com.fenglin.springboottest.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

import java.time.LocalDateTime;

/**
 * 宗门榜弟子实体，对应数据库 login_db.sect_member 表。
 * 宗门榜页面展示：道号 / 境界 / 职位 / 堂口 / 战力 / 贡献。
 */
@Data
@TableName("sect_member")
public class SectMember {

    /** 主键，数据库自增 */
    @TableId(type = IdType.AUTO)
    private Long id;

    /** 道号（唯一） */
    private String name;

    /** 大境界：魔尊/渡劫/大乘/合体/炼虚/化神/元婴/金丹/筑基/炼气 */
    private String realm;

    /** 境界层次：一层~九层 / 初期~巅峰 / 小成~巅峰 / 一重~九重 */
    private String stage;

    /** 称号 / 职位（宗主、太上长老、内门长老、外门长老、真传弟子……） */
    private String title;

    /** 所属堂口（主殿、血煞堂、幽冥堂、千机堂、执法堂、炼丹堂） */
    private String hall;

    /** 战力 */
    private Long power;

    /** 宗门贡献 */
    private Long contribution;

    /** 头像 emoji */
    private String icon;

    /** 入门时间 */
    private LocalDateTime createTime;
}
