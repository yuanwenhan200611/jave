package com.fenglin.springboottest.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.fenglin.springboottest.entity.CultivationLog;
import org.apache.ibatis.annotations.Mapper;

/**
 * 魔功殿修炼记录 Mapper。
 * 注意：必须加 @Mapper 注解，否则启动报 bean not found。
 */
@Mapper
public interface CultivationLogMapper extends BaseMapper<CultivationLog> {
}
