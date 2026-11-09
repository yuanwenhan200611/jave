package com.fenglin.springboottest.controller;

import com.fenglin.springboottest.common.Result;
import com.fenglin.springboottest.entity.ForumPost;
import com.fenglin.springboottest.service.ForumService;
import com.fenglin.springboottest.vo.PageResult;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

/**
 * 论道模块 REST 接口：
 *
 *   GET  /api/forum/posts             帖子分页列表（sort=new|hot）
 *   POST /api/forum/posts             发帖 { author, title, content }
 *   POST /api/forum/posts/{id}/like   道心相印（点赞 +1）
 */
@RestController
@RequestMapping("/api/forum")
public class ForumController {

    private final ForumService forumService;

    public ForumController(ForumService forumService) {
        this.forumService = forumService;
    }

    /** 帖子分页列表 */
    @GetMapping("/posts")
    public Result<PageResult<ForumPost>> posts(
            @RequestParam(required = false) String sort,
            @RequestParam(required = false, defaultValue = "1") Integer page,
            @RequestParam(required = false, defaultValue = "10") Integer size) {
        return Result.ok(forumService.page(sort, page, size));
    }

    /** 发帖 */
    @PostMapping("/posts")
    public Result<?> create(@RequestBody(required = false) Map<String, String> body) {
        if (body == null) {
            return Result.error("请求体不能为空");
        }
        try {
            return Result.ok(forumService.create(
                    body.get("author"), body.get("title"), body.get("content")));
        } catch (IllegalArgumentException e) {
            return Result.error(e.getMessage());
        }
    }

    /** 道心相印 */
    @PostMapping("/posts/{id}/like")
    public Result<Map<String, Object>> like(@PathVariable Long id) {
        try {
            long likes = forumService.like(id);
            return Result.ok(Map.of("likes", likes));
        } catch (IllegalArgumentException e) {
            return Result.error(e.getMessage());
        }
    }
}
