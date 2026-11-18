package com.fenglin.springboottest.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.fenglin.springboottest.entity.ForumIncome;
import org.apache.ibatis.annotations.Mapper;

/**
 * 血辩台收益账本 Mapper。
 * 注意：必须加 @Mapper 注解，否则启动报 bean not found。
 */
@Mapper
public interface ForumIncomeMapper extends BaseMapper<ForumIncome> {
}
