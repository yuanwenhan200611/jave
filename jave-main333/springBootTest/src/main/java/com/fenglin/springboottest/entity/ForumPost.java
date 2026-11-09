package com.fenglin.springboottest.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

import java.time.LocalDateTime;

/**
 * 论道帖实体，对应数据库 login_db.forum_post 表。
 * 论道页面：帖子列表 / 发帖 / 点赞（道心相印）。
 */
@Data
@TableName("forum_post")
public class ForumPost {

    /** 主键，数据库自增 */
    @TableId(type = IdType.AUTO)
    private Long id;

    /** 发帖人（登录用户名或道号） */
    private String author;

    /** 帖名 */
    private String title;

    /** 正文 */
    private String content;

    /** 围观量 */
    private Long views;

    /** 道心相印（点赞）数 */
    private Long likes;

    /** 状态：1 显示 / 0 屏蔽 */
    private Integer status;

    /** 发帖时间 */
    private LocalDateTime createTime;
}
