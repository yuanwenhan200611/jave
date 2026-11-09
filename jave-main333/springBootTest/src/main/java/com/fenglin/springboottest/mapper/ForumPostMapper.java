package com.fenglin.springboottest.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.fenglin.springboottest.entity.ForumPost;
import org.apache.ibatis.annotations.Mapper;

/** 论道帖 Mapper */
@Mapper
public interface ForumPostMapper extends BaseMapper<ForumPost> {
}
