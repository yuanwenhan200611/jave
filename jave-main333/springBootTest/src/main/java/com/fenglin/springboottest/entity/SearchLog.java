package com.fenglin.springboottest.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

import java.time.LocalDateTime;

/**
 * 搜索日志实体，对应数据库 login_db.search_log 表。
 * 每次搜索落一条，用于「热搜词榜」与「无结果词」分析。
 */
@Data
@TableName("search_log")
public class SearchLog {

    /** 主键，数据库自增 */
    @TableId(type = IdType.AUTO)
    private Long id;

    /** 搜索关键词 */
    private String keyword;

    /** 分类过滤条件（可空，空表示全部分类） */
    private Long categoryId;

    /** 本次搜索命中的结果条数 */
    private Integer resultCount;

    /** 发起搜索的用户名（可空，未登录时为空） */
    private String username;

    /** 搜索时间 */
    private LocalDateTime createTime;
}
