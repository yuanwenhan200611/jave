package com.fenglin.springboottest.controller;

import com.fenglin.springboottest.common.Result;
import com.fenglin.springboottest.service.UserService;
import com.fenglin.springboottest.util.CaptchaUtil;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;

import java.util.HashMap;
import java.util.Map;

/**
 * 认证相关 REST 接口，供 Vue 前端调用：
 *   GET  /api/captcha   获取图形验证码
 *   POST /api/register  注册
 *   POST /api/login     登录
 */
@RestController
@RequestMapping("/api")
@RequiredArgsConstructor
public class AuthController {

    private final UserService userService;

    /** 获取验证码：返回 captchaId + base64 图片 */
    @GetMapping("/captcha")
    public Result<Map<String, String>> captcha() {
        String[] pair = CaptchaUtil.create();
        Map<String, String> data = new HashMap<>();
        data.put("captchaId", pair[0]);
        data.put("image", pair[1]);
        return Result.ok(data);
    }

    /** 注册 */
    @PostMapping("/register")
    public Result<Map<String, Object>> register(@RequestBody Map<String, String> body) {
        try {
            return Result.ok(userService.register(
                    body.get("username"),
                    body.get("password"),
                    body.get("captchaId"),
                    body.get("captcha")));
        } catch (IllegalArgumentException e) {
            return Result.error(e.getMessage());
        }
    }

    /** 登录 */
    @PostMapping("/login")
    public Result<Map<String, Object>> login(@RequestBody Map<String, String> body) {
        try {
            return Result.ok(userService.login(body.get("username"), body.get("password")));
        } catch (IllegalArgumentException e) {
            return Result.error(e.getMessage());
        }
    }
}
