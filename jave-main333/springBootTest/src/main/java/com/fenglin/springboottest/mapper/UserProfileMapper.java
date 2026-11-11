package com.fenglin.springboottest.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.fenglin.springboottest.entity.UserProfile;
import org.apache.ibatis.annotations.Mapper;

/**
 * 用户个人档案 Mapper（MyBatis-Plus BaseMapper 即可覆盖全部查询）
 */
@Mapper
public interface UserProfileMapper extends BaseMapper<UserProfile> {
}
