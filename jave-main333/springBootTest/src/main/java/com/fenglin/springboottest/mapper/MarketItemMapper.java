package com.fenglin.springboottest.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.fenglin.springboottest.entity.MarketItem;
import org.apache.ibatis.annotations.Mapper;

/** 坊市·在售货品 Mapper */
@Mapper
public interface MarketItemMapper extends BaseMapper<MarketItem> {
}
