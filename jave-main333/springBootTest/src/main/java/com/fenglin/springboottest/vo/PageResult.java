package com.fenglin.springboottest.vo;

import lombok.Data;

import java.util.List;

/**
 * 分页结果包装。list 为当前页数据，total 为满足条件的总条数。
 * page / size / pages 一并返回，前端分页器可直接用，不用自己算。
 */
@Data
public class PageResult<T> {

    /** 当前页数据 */
    private List<T> list;

    /** 满足条件的总条数 */
    private long total;

    /** 当前页码，从 1 开始 */
    private long page;

    /** 每页条数 */
    private long size;

    /** 总页数 */
    private long pages;

    public static <T> PageResult<T> of(List<T> list, long total, long page, long size) {
        PageResult<T> r = new PageResult<>();
        r.list = list;
        r.total = total;
        r.page = page;
        r.size = size;
        r.pages = size <= 0 ? 0 : (total + size - 1) / size;
        return r;
    }
}
