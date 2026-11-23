package com.fenglin.springboottest.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.fenglin.springboottest.entity.MarketOrder;
import org.apache.ibatis.annotations.Mapper;

/** 坊市·交易手札 Mapper */
@Mapper
public interface MarketOrderMapper extends BaseMapper<MarketOrder> {
}
