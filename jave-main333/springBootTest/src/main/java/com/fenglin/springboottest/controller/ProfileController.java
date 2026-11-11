package com.fenglin.springboottest.controller;

import com.fenglin.springboottest.common.Result;
import com.fenglin.springboottest.entity.ForumPost;
import com.fenglin.springboottest.entity.SearchLog;
import com.fenglin.springboottest.entity.UserProfile;
import com.fenglin.springboottest.service.ProfileService;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

/**
 * 洞府（个人页）REST 接口，供 Vue 前端调用：
 *
 *   GET  /api/profile?username=xxx          读取档案 + 跨模块统计（论道/首页/用户）
 *   POST /api/profile/update                保存档案 { username, nickname, icon, realm, hall, bio }
 *   GET  /api/profile/posts?username=xxx    我的帖子（论道联动）
 *   GET  /api/profile/searches?username=xxx 搜索足迹（首页联动）
 */
@RestController
@RequestMapping("/api/profile")
@RequiredArgsConstructor
public class ProfileController {

    private final ProfileService profileService;

    /** 读取档案 + 统计 */
    @GetMapping
    public Result<Map<String, Object>> profile(@RequestParam String username) {
        try {
            return Result.ok(profileService.getProfile(username));
        } catch (IllegalArgumentException e) {
            return Result.error(e.getMessage());
        }
    }

    /** 保存档案 */
    @PostMapping("/update")
    public Result<UserProfile> update(@RequestBody Map<String, String> body) {
        if (body == null) {
            return Result.error("请求体不能为空");
        }
        try {
            return Result.ok(profileService.updateProfile(
                    body.get("username"),
                    body.get("nickname"),
                    body.get("icon"),
                    body.get("realm"),
                    body.get("hall"),
                    body.get("bio")));
        } catch (IllegalArgumentException e) {
            return Result.error(e.getMessage());
        }
    }

    /** 我的帖子（论道联动） */
    @GetMapping("/posts")
    public Result<List<ForumPost>> posts(@RequestParam String username) {
        try {
            return Result.ok(profileService.myPosts(username));
        } catch (IllegalArgumentException e) {
            return Result.error(e.getMessage());
        }
    }

    /** 搜索足迹（首页联动） */
    @GetMapping("/searches")
    public Result<List<SearchLog>> searches(@RequestParam String username) {
        try {
            return Result.ok(profileService.mySearches(username));
        } catch (IllegalArgumentException e) {
            return Result.error(e.getMessage());
        }
    }
}
