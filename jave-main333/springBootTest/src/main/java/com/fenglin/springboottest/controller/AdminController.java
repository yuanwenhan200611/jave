package com.fenglin.springboottest.controller;

import com.fenglin.springboottest.common.Result;
import com.fenglin.springboottest.entity.UserProfile;
import com.fenglin.springboottest.service.AdminService;
import com.fenglin.springboottest.util.AdminUnauthorizedException;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

/**
 * 后台管理 REST 接口：
 *
 *   POST   /api/admin/login                后台登录（无注册）
 *   POST   /api/admin/logout               退出
 *   GET    /api/admin/session              查看当前会话
 *   GET    /api/admin/profiles             洞府档案列表 + 概览（keyword/page/size）
 *   POST   /api/admin/profiles             新增洞府档案
 *   PUT    /api/admin/profiles/{username}  编辑洞府档案
 *   DELETE /api/admin/profiles/{username}  删除洞府档案
 *
 * 除 login 外都要求请求头 X-Admin-Token。
 */
@RestController
@RequestMapping("/api/admin")
@RequiredArgsConstructor
public class AdminController {

    private static final String TOKEN_HEADER = "X-Admin-Token";

    private final AdminService adminService;

    @PostMapping("/login")
    public Result<Map<String, Object>> login(@RequestBody Map<String, String> body) {
        try {
            return Result.ok(adminService.login(body.get("username"), body.get("password")));
        } catch (AdminUnauthorizedException e) {
            return Result.error(401, e.getMessage());
        } catch (IllegalArgumentException e) {
            return Result.error(e.getMessage());
        }
    }

    @PostMapping("/logout")
    public Result<Void> logout(@RequestHeader(value = TOKEN_HEADER, required = false) String token) {
        adminService.logout(token);
        return Result.ok();
    }

    @GetMapping("/session")
    public Result<Map<String, String>> session(
            @RequestHeader(value = TOKEN_HEADER, required = false) String token) {
        try {
            return Result.ok(adminService.session(token));
        } catch (IllegalArgumentException e) {
            return Result.error(401, e.getMessage());
        }
    }

    @GetMapping("/profiles")
    public Result<Map<String, Object>> profiles(
            @RequestHeader(value = TOKEN_HEADER, required = false) String token,
            @RequestParam(required = false) String keyword,
            @RequestParam(defaultValue = "1") int page,
            @RequestParam(defaultValue = "10") int size) {
        try {
            adminService.session(token);
            return Result.ok(adminService.profiles(keyword, page, size));
        } catch (AdminUnauthorizedException e) {
            return Result.error(401, e.getMessage());
        } catch (IllegalArgumentException e) {
            return Result.error(e.getMessage());
        }
    }

    @PostMapping("/profiles")
    public Result<UserProfile> create(
            @RequestHeader(value = TOKEN_HEADER, required = false) String token,
            @RequestBody Map<String, Object> body) {
        try {
            adminService.session(token);
            return Result.ok(adminService.create(body));
        } catch (AdminUnauthorizedException e) {
            return Result.error(401, e.getMessage());
        } catch (IllegalArgumentException e) {
            return Result.error(e.getMessage());
        }
    }

    @PutMapping("/profiles/{username}")
    public Result<UserProfile> update(
            @RequestHeader(value = TOKEN_HEADER, required = false) String token,
            @PathVariable String username,
            @RequestBody Map<String, Object> body) {
        try {
            adminService.session(token);
            return Result.ok(adminService.update(username, body));
        } catch (AdminUnauthorizedException e) {
            return Result.error(401, e.getMessage());
        } catch (IllegalArgumentException e) {
            return Result.error(e.getMessage());
        }
    }

    @DeleteMapping("/profiles/{username}")
    public Result<Void> delete(
            @RequestHeader(value = TOKEN_HEADER, required = false) String token,
            @PathVariable String username) {
        try {
            adminService.session(token);
            adminService.delete(username);
            return Result.ok();
        } catch (AdminUnauthorizedException e) {
            return Result.error(401, e.getMessage());
        } catch (IllegalArgumentException e) {
            return Result.error(e.getMessage());
        }
    }
}
