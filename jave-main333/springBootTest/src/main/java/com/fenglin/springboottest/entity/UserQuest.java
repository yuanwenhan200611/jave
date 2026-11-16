package com.fenglin.springboottest.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

import java.time.LocalDateTime;

/**
 * 弟子接取任务记录实体，对应数据库 login_db.user_quest 表。
 * 洞府联动：以 username 统计进行中任务、已完成任务、累计贡献值与灵石。
 */
@Data
@TableName("user_quest")
public class UserQuest {

    /** 主键，数据库自增 */
    @TableId(type = IdType.AUTO)
    private Long id;

    /** 接取人（关联 user.username） */
    private String username;

    /** 任务 id（关联 quest.id） */
    private Long questId;

    /** 状态：0 进行中 / 1 已完成 / 2 已放弃 */
    private Integer status;

    /** 完成时所得贡献值快照 */
    private Long rewardContribution;

    /** 完成时所得灵石快照 */
    private Long rewardStones;

    /** 完成时所得物品快照（个人悬赏） */
    private String rewardItem;

    /** 接取时间 */
    private LocalDateTime createTime;

    /** 完成 / 放弃时间 */
    private LocalDateTime finishTime;
}
