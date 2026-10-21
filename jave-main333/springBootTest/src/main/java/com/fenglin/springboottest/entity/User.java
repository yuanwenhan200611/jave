package com.fenglin.springboottest.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

import java.time.LocalDateTime;

/**
 * 用户实体，对应数据库 login_db.user 表
 * 注意：create_time / update_time 由数据库默认值维护，插入时留空即可
 */
@Data
// 注意：user 是 MySQL 保留字，MyBatis-Plus 默认生成的 SQL 不带反引号，
// 会导致 "You have an error in your SQL syntax" 而 500。这里用反引号包裹表名。
@TableName("`user`")
public class User {

    /** 主键，数据库自增 */
    @TableId(type = IdType.AUTO)
    private Long id;

    /** 用户名 */
    private String username;

    /** 密码（MD5 存储） */
    private String password;

    /** 创建时间 */
    private LocalDateTime createTime;

    /** 更新时间 */
    private LocalDateTime updateTime;
}
