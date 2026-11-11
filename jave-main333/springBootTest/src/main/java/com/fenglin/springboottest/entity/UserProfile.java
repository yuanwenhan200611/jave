package com.fenglin.springboottest.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

import java.time.LocalDateTime;

/**
 * 用户个人档案实体，对应数据库 login_db.user_profile 表。
 * 洞府（个人页）展示与编辑：道号 / 头像 / 境界 / 堂口 / 签名。
 * 以 username 关联 user 表（一对一），首次访问洞府时自动生成默认档案。
 */
@Data
@TableName("user_profile")
public class UserProfile {

    /** 主键，数据库自增 */
    @TableId(type = IdType.AUTO)
    private Long id;

    /** 用户名（唯一，关联 user.username） */
    private String username;

    /** 道号（昵称，展示用） */
    private String nickname;

    /** 头像 emoji */
    private String icon;

    /** 境界：炼气/筑基/金丹/元婴/化神/炼虚/合体/大乘/渡劫/魔尊 */
    private String realm;

    /** 所属堂口（主殿、血煞堂、幽冥堂、千机堂、执法堂、炼丹堂） */
    private String hall;

    /** 道语签名 */
    private String bio;

    /** 创建时间 */
    private LocalDateTime createTime;

    /** 更新时间 */
    private LocalDateTime updateTime;
}
