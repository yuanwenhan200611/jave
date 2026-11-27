package com.fenglin.springboottest.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.fenglin.springboottest.entity.AdminUser;
import org.apache.ibatis.annotations.Mapper;

/** 后台管理员账号 Mapper（ @Mapper 不能省，否则启动报 bean not found ） */
@Mapper
public interface AdminUserMapper extends BaseMapper<AdminUser> {
}
