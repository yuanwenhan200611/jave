package com.fenglin.springboottest.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

import java.time.LocalDateTime;

/**
 * 秘境·进入记录实体，对应数据库 login_db.user_secret 表。
 * 弟子在秘境消耗贡献值破界进入后落一条记录（秘境名/品阶快照）。
 * 贡献值经济闭环：任务阁交差赚贡献值 → 功法阁参悟 / 秘境破界花贡献值。
 */
@Data
@TableName("user_secret")
public class UserSecret {

    /** 主键，数据库自增 */
    @TableId(type = IdType.AUTO)
    private Long id;

    /** 破界人（关联 user.username） */
    private String username;

    /** 秘境条目 id（关联 content_item.id） */
    private Long itemId;

    /** 进入时消耗的贡献值快照（随机探秘记「天机引路费」） */
    private Long cost;

    /** 秘境名快照（防止条目日后改名导致记录失真） */
    private String title;

    /** 品阶快照 */
    private String grade;

    /** 图标快照 */
    private String icon;

    /** 进入时间 */
    private LocalDateTime createTime;
}
