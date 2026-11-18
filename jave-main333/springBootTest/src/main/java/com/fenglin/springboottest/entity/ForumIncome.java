package com.fenglin.springboottest.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

import java.time.LocalDateTime;

/**
 * 血辩台收益账本：帖子收到香火供奉时，帖主的贡献值分成入账。
 * 可用余额 = 任务所得 + 论坛收益 - 修炼/论道消耗（CultivationService / ProfileService 统一口径）。
 */
@Data
@TableName("forum_income")
public class ForumIncome {

    /** 主键，数据库自增 */
    @TableId(type = IdType.AUTO)
    private Long id;

    /** 收益人（登录用户名） */
    private String username;

    /** 灵石收益 */
    private Long stones;

    /** 贡献值收益 */
    private Long contribution;

    /** 来源：incense 香火分成 */
    private String source;

    /** 入账时间 */
    private LocalDateTime createTime;
}
