package com.fenglin.springboottest.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.fenglin.springboottest.entity.UserQuest;
import org.apache.ibatis.annotations.Mapper;

/** 弟子接取任务记录表访问 */
@Mapper
public interface UserQuestMapper extends BaseMapper<UserQuest> {
}
