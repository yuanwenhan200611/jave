package com.fenglin.springboottest.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

import java.time.LocalDateTime;

/**
 * 功法阁·参悟记录实体，对应数据库 login_db.user_skill 表。
 * 弟子在功法阁消耗贡献值参悟功法后落一条记录（功法名/品阶快照）。
 * 贡献值经济闭环：任务阁交差赚贡献值 → 功法阁参悟花贡献值。
 */
@Data
@TableName("user_skill")
public class UserSkill {

    /** 主键，数据库自增 */
    @TableId(type = IdType.AUTO)
    private Long id;

    /** 参悟人（关联 user.username） */
    private String username;

    /** 功法条目 id（关联 content_item.id） */
    private Long itemId;

    /** 参悟时消耗的贡献值快照 */
    private Long cost;

    /** 功法名快照（防止条目日后改名导致记录失真） */
    private String title;

    /** 品阶快照 */
    private String grade;

    /** 图标快照 */
    private String icon;

    /** 参悟时间 */
    private LocalDateTime createTime;
}
