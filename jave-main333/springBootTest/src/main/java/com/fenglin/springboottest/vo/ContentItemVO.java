package com.fenglin.springboottest.vo;

import lombok.Data;

import java.time.LocalDateTime;

/**
 * 内容条目展示对象（VO）。
 * 相比实体多带 categoryName / categoryPath，前端无需再自行查分类表，
 * 搜索结果、热门榜、详情页统一用这一个结构。
 */
@Data
public class ContentItemVO {

    private Long id;

    private String title;

    private String description;

    private Long categoryId;

    /** 所属分类名称（冗余字段，便于列表展示） */
    private String categoryName;

    /** 分类路径，如「功法 / 炼体功法」，面包屑用 */
    private String categoryPath;

    private String grade;

    private String icon;

    private Long viewCount;

    private Integer status;

    private LocalDateTime createTime;
}
