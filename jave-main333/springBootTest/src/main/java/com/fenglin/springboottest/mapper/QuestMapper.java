package com.fenglin.springboottest.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.fenglin.springboottest.entity.Quest;
import org.apache.ibatis.annotations.Mapper;

/** 任务牌表访问 */
@Mapper
public interface QuestMapper extends BaseMapper<Quest> {
}
