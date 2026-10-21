package com.fenglin.springboottest.service;

import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import com.fenglin.springboottest.entity.User;
import com.fenglin.springboottest.mapper.UserMapper;
import com.fenglin.springboottest.util.CaptchaUtil;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.util.DigestUtils;

import java.util.HashMap;
import java.util.Map;
import java.util.UUID;

/**
 * 用户服务：注册 / 登录
 */
@Service
@RequiredArgsConstructor
public class UserService {

    private final UserMapper userMapper;

    /**
     * 注册：校验验证码 + 用户名格式 + 用户名唯一性，密码 MD5 后入库
     */
    public Map<String, Object> register(String username, String password, String captchaId, String captcha) {
        // 1. 验证码校验（一次性）
        String captchaError = CaptchaUtil.verify(captchaId, captcha);
        if (captchaError != null) {
            throw new IllegalArgumentException(captchaError);
        }

        // 2. 用户名格式校验
        if (username == null || !username.matches("^[A-Za-z0-9_]{3,20}$")) {
            throw new IllegalArgumentException("用户名需为 3-20 位字母、数字或下划线");
        }

        // 3. 密码长度校验
        if (password == null || password.length() < 6) {
            throw new IllegalArgumentException("密码不能少于 6 位");
        }

        // 4. 用户名唯一性校验
        Long count = userMapper.selectCount(new QueryWrapper<User>().eq("username", username));
        if (count != null && count > 0) {
            throw new IllegalArgumentException("用户名已被注册");
        }

        // 5. 入库（密码 MD5；create_time/update_time 由数据库默认值生成）
        User user = new User();
        user.setUsername(username);
        user.setPassword(DigestUtils.md5DigestAsHex(password.getBytes()));
        userMapper.insert(user);

        // 重新查询以获取数据库默认生成的 create_time
        User saved = userMapper.selectById(user.getId());

        Map<String, Object> data = new HashMap<>();
        data.put("username", saved.getUsername());
        data.put("createdAt", saved.getCreateTime());
        return data;
    }

    /**
     * 登录：用户名 + 密码匹配则签发一个简单 token（演示用，无会话管理）
     */
    public Map<String, Object> login(String username, String password) {
        if (username == null || username.isBlank() || password == null || password.isBlank()) {
            throw new IllegalArgumentException("请输入用户名和密码");
        }

        User user = userMapper.selectOne(new QueryWrapper<User>().eq("username", username));
        if (user == null || !user.getPassword().equals(DigestUtils.md5DigestAsHex(password.getBytes()))) {
            throw new IllegalArgumentException("用户名或密码错误");
        }

        Map<String, Object> data = new HashMap<>();
        data.put("token", UUID.randomUUID().toString().replace("-", ""));
        data.put("username", user.getUsername());
        return data;
    }
}
