package com.fenglin.springboottest.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.fenglin.springboottest.entity.SearchLog;
import org.apache.ibatis.annotations.Mapper;

/**
 * 搜索日志 Mapper，继承 BaseMapper 即拥有常用 CRUD。
 */
@Mapper
public interface SearchLogMapper extends BaseMapper<SearchLog> {
}
