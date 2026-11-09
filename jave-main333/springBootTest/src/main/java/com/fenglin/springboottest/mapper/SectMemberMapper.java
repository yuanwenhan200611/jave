package com.fenglin.springboottest.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.fenglin.springboottest.entity.SectMember;
import org.apache.ibatis.annotations.Mapper;

/** 宗门榜弟子 Mapper */
@Mapper
public interface SectMemberMapper extends BaseMapper<SectMember> {
}
