package com.fenglin.springboottest.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

import java.time.LocalDateTime;

/**
 * 后台管理员账号，对应 login_db.admin_user 表。
 * 与前台 user 表分开：普通会员即使叫 admin 也不能进后台。
 */
@Data
@TableName("admin_user")
public class AdminUser {

    @TableId(type = IdType.AUTO)
    private Long id;

    /** 后台登录账号 */
    private String username;

    /** 密码，MD5 32 位十六进制 */
    private String password;

    /** 后台显示名 */
    private String displayName;

    private LocalDateTime createTime;

    private LocalDateTime updateTime;
}
