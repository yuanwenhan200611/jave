package com.fenglin.springboottest.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.fenglin.springboottest.entity.UserSkill;
import org.apache.ibatis.annotations.Mapper;

/** 功法阁·参悟记录 Mapper */
@Mapper
public interface UserSkillMapper extends BaseMapper<UserSkill> {
}
