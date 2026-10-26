package com.fenglin.springboottest.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableField;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;

/**
 * 分类实体，对应数据库 login_db.category 表。
 * 采用 parent_id 自引用实现分级（多级）分类树。
 */
@Data
@TableName("category")
public class Category {

    /** 主键，数据库自增 */
    @TableId(type = IdType.AUTO)
    private Long id;

    /** 分类名称 */
    private String name;

    /** 父分类 id，0 表示顶级分类 */
    private Long parentId;

    /** 层级：1 顶级 / 2 二级 / 3 三级 ... */
    private Integer level;

    /** 排序值，越小越靠前 */
    private Integer sort;

    /** 图标（emoji 或字符） */
    private String icon;

    /** 分类描述 */
    private String description;

    /** 创建时间（数据库默认值维护） */
    private LocalDateTime createTime;

    /** 子分类（不入库，仅用于构建树形结构返回前端） */
    @TableField(exist = false)
    private List<Category> children = new ArrayList<>();
}
