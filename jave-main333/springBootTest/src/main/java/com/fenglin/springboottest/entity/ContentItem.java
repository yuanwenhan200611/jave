package com.fenglin.springboottest.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

import java.time.LocalDateTime;

/**
 * 内容条目实体，对应数据库 login_db.content_item 表。
 * 首页展示与搜索的数据主体（功法、秘境、丹药、法宝等通用条目）。
 */
@Data
@TableName("content_item")
public class ContentItem {

    /** 主键，数据库自增 */
    @TableId(type = IdType.AUTO)
    private Long id;

    /** 标题 */
    private String title;

    /** 简介 */
    private String description;

    /** 所属分类 id（关联 category 表，可为任意层级分类） */
    private Long categoryId;

    /** 品阶（如：天阶 / 地阶 / 玄阶 / 黄阶） */
    private String grade;

    /** 图标（emoji，展示用） */
    private String icon;

    /** 浏览量 */
    private Long viewCount;

    /** 状态：1 上架 / 0 下架 */
    private Integer status;

    /** 创建时间（数据库默认值维护） */
    private LocalDateTime createTime;

    /** 更新时间（数据库默认值维护） */
    private LocalDateTime updateTime;
}
