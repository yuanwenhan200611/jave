package com.fenglin.springboottest.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

import java.time.LocalDateTime;

/**
 * 血辩台动作记录：同一用户对同一帖子的「香火供奉 / 驳道」各限一次。
 * 数据库 UNIQUE KEY (post_id, username, action) 兜底防重。
 */
@Data
@TableName("forum_like")
public class ForumLike {

    /** 主键，数据库自增 */
    @TableId(type = IdType.AUTO)
    private Long id;

    /** 帖子 id（forum_post.id） */
    private Long postId;

    /** 动作发起人（登录用户名） */
    private String username;

    /** 动作：incense 香火供奉 / counter 驳道 */
    private String action;

    /** 动作时间 */
    private LocalDateTime createTime;
}
