package com.fenglin.springboottest.controller;

import com.fenglin.springboottest.common.Result;
import com.fenglin.springboottest.service.ForumService;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

/**
 * 血辩台（原论道）模块 REST 接口——论道即修炼，全部真实结算：
 *
 *   GET  /api/forum/posts                  帖子分页列表（sort=new|hot，username 可选，返回动作状态）
 *   POST /api/forum/posts                  开坛讲道 { author, title, content }（20 灵石，修为 +60~150，60s 调息）
 *   POST /api/forum/posts/{id}/incense     香火供奉 { username }（10 灵石，自己 +修为，帖主 +5 贡献）
 *   POST /api/forum/posts/{id}/counter     驳道 { username }（押 50 修为，45% 胜 +120~300 / 败 -50）
 */
@RestController
@RequestMapping("/api/forum")
public class ForumController {

    private final ForumService forumService;

    public ForumController(ForumService forumService) {
        this.forumService = forumService;
    }

    /** 帖子分页列表（含当前用户供奉/驳道状态） */
    @GetMapping("/posts")
    public Result<Map<String, Object>> posts(
            @RequestParam(required = false) String sort,
            @RequestParam(required = false, defaultValue = "1") Integer page,
            @RequestParam(required = false, defaultValue = "10") Integer size,
            @RequestParam(required = false) String username) {
        return Result.ok(forumService.page(sort, page, size, username));
    }

    /** 开坛讲道（发帖即修炼） */
    @PostMapping("/posts")
    public Result<Map<String, Object>> create(@RequestBody(required = false) Map<String, String> body) {
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

    /** 香火供奉（原点赞）：供奉者 +修为，帖主 +贡献分成 */
    @PostMapping("/posts/{id}/incense")
    public Result<Map<String, Object>> incense(@PathVariable Long id,
                                               @RequestBody(required = false) Map<String, String> body) {
        String username = body == null ? null : body.get("username");
        try {
            return Result.ok(forumService.incense(id, username));
        } catch (IllegalArgumentException e) {
            return Result.error(e.getMessage());
        }
    }

    /** 驳道：押修为上台论剑 */
    @PostMapping("/posts/{id}/counter")
    public Result<Map<String, Object>> counter(@PathVariable Long id,
                                               @RequestBody(required = false) Map<String, String> body) {
        String username = body == null ? null : body.get("username");
        try {
            return Result.ok(forumService.counter(id, username));
        } catch (IllegalArgumentException e) {
            return Result.error(e.getMessage());
        }
    }
}
