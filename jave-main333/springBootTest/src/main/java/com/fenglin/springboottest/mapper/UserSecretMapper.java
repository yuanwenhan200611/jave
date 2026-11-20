package com.fenglin.springboottest.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.fenglin.springboottest.entity.UserSecret;
import org.apache.ibatis.annotations.Mapper;

/** 秘境·进入记录 Mapper */
@Mapper
public interface UserSecretMapper extends BaseMapper<UserSecret> {
}
