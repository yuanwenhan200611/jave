package com.fenglin.springboottest.controller;

import com.fenglin.springboottest.common.Result;
import com.fenglin.springboottest.entity.Quest;
import com.fenglin.springboottest.service.QuestService;
import com.fenglin.springboottest.vo.PageResult;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

/**
 * 任务阁 REST 接口：
 *
 *   GET  /api/quest/summary?type=sect       分类统计（分堂 tab 计数）
 *   GET  /api/quest/types                   悬赏来源统计（宗门 / 个人）
 *   GET  /api/quest/list                    任务牌分页列表（type / category / sort / page / size）
 *   POST /api/quest/publish                 发布个人悬赏 { username, title, description, category,
 *                                           difficulty, minRealm, maxAccept, rewardItem, icon }
 *   POST /api/quest/accept                  接取任务 { username, questId }（校验修为门槛与名额）
 *   POST /api/quest/finish                  完成任务 { username, questId }（结算贡献值/灵石/物品，联动洞府）
 *   POST /api/quest/abandon                 放弃任务 { username, questId }（释放名额）
 *   GET  /api/quest/my?username=xxx         我的任务牌（洞府「我的任务」联动）
 */
@RestController
@RequestMapping("/api/quest")
public class QuestController {

    private final QuestService questService;

    public QuestController(QuestService questService) {
        this.questService = questService;
    }

    /** 分类统计 */
    @GetMapping("/summary")
    public Result<Map<String, Long>> summary(@RequestParam(required = false) String type) {
        return Result.ok(questService.categoryCounts(type));
    }

    /** 悬赏来源统计（宗门 / 个人） */
    @GetMapping("/types")
    public Result<Map<String, Long>> types() {
        return Result.ok(questService.typeCounts());
    }

    /** 任务牌分页列表 */
    @GetMapping("/list")
    public Result<PageResult<Quest>> list(
            @RequestParam(required = false) String type,
            @RequestParam(required = false) String category,
            @RequestParam(required = false) String sort,
            @RequestParam(required = false, defaultValue = "1") Integer page,
            @RequestParam(required = false, defaultValue = "10") Integer size) {
        return Result.ok(questService.page(type, category, sort, page, size));
    }

    /** 发布个人悬赏 */
    @PostMapping("/publish")
    public Result<Quest> publish(@RequestBody(required = false) Map<String, Object> body) {
        if (body == null) {
            return Result.error("请求体不能为空");
        }
        try {
            return Result.ok(questService.publish(
                    asString(body.get("username")),
                    asString(body.get("title")),
                    asString(body.get("description")),
                    asString(body.get("category")),
                    asString(body.get("difficulty")),
                    asString(body.get("minRealm")),
                    asInteger(body.get("maxAccept")),
                    asString(body.get("rewardItem")),
                    asString(body.get("icon"))));
        } catch (IllegalArgumentException e) {
            return Result.error(e.getMessage());
        }
    }

    /** 接取任务 */
    @PostMapping("/accept")
    public Result<Map<String, Object>> accept(@RequestBody(required = false) Map<String, Object> body) {
        if (body == null) {
            return Result.error("请求体不能为空");
        }
        try {
            return Result.ok(questService.accept(
                    asString(body.get("username")), asLong(body.get("questId"))));
        } catch (IllegalArgumentException e) {
            return Result.error(e.getMessage());
        }
    }

    /** 完成任务（结算贡献，洞府统计联动） */
    @PostMapping("/finish")
    public Result<Map<String, Object>> finish(@RequestBody(required = false) Map<String, Object> body) {
        if (body == null) {
            return Result.error("请求体不能为空");
        }
        try {
            return Result.ok(questService.finish(
                    asString(body.get("username")), asLong(body.get("questId"))));
        } catch (IllegalArgumentException e) {
            return Result.error(e.getMessage());
        }
    }

    /** 放弃任务 */
    @PostMapping("/abandon")
    public Result<Map<String, Object>> abandon(@RequestBody(required = false) Map<String, Object> body) {
        if (body == null) {
            return Result.error("请求体不能为空");
        }
        try {
            return Result.ok(questService.abandon(
                    asString(body.get("username")), asLong(body.get("questId"))));
        } catch (IllegalArgumentException e) {
            return Result.error(e.getMessage());
        }
    }

    /** 我的任务牌（洞府联动） */
    @GetMapping("/my")
    public Result<List<Map<String, Object>>> my(@RequestParam String username) {
        try {
            return Result.ok(questService.myQuests(username));
        } catch (IllegalArgumentException e) {
            return Result.error(e.getMessage());
        }
    }

    private String asString(Object v) {
        return v == null ? null : String.valueOf(v);
    }

    private Long asLong(Object v) {
        if (v == null) {
            return null;
        }
        try {
            return Long.parseLong(String.valueOf(v));
        } catch (NumberFormatException e) {
            throw new IllegalArgumentException("任务 id 不合法");
        }
    }

    private Integer asInteger(Object v) {
        if (v == null || String.valueOf(v).isBlank()) {
            return null;
        }
        try {
            return Integer.parseInt(String.valueOf(v));
        } catch (NumberFormatException e) {
            throw new IllegalArgumentException("名额数值不合法");
        }
    }
}
