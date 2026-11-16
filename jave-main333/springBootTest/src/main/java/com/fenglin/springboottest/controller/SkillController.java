package com.fenglin.springboottest.controller;

import com.fenglin.springboottest.common.Result;
import com.fenglin.springboottest.entity.UserSkill;
import com.fenglin.springboottest.service.SkillService;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

/**
 * 功法阁·参悟 REST 接口：
 *
 *   GET  /api/skill/status?username=xxx   参悟状态：贡献值账本 + 已习功法
 *   POST /api/skill/learn                 参悟功法 { username, itemId }（扣贡献值）
 *   GET  /api/skill/mine?username=xxx     我的已参悟功法（洞府联动）
 */
@RestController
@RequestMapping("/api/skill")
public class SkillController {

    private final SkillService skillService;

    public SkillController(SkillService skillService) {
        this.skillService = skillService;
    }

    /** 参悟状态总览（贡献值余额 / 已习功法 id 列表） */
    @GetMapping("/status")
    public Result<Map<String, Object>> status(@RequestParam String username) {
        try {
            return Result.ok(skillService.status(username));
        } catch (IllegalArgumentException e) {
            return Result.error(e.getMessage());
        }
    }

    /** 参悟功法：消耗贡献值，每人每功法一次 */
    @PostMapping("/learn")
    public Result<UserSkill> learn(@RequestBody Map<String, Object> body) {
        try {
            String username = body == null ? null : String.valueOf(body.get("username"));
            Long itemId = asLong(body == null ? null : body.get("itemId"));
            return Result.ok(skillService.learn(username, itemId));
        } catch (IllegalArgumentException e) {
            return Result.error(e.getMessage());
        }
    }

    /** 我的已参悟功法（洞府「已习功法」tab 联动） */
    @GetMapping("/mine")
    public Result<List<UserSkill>> mine(@RequestParam String username) {
        try {
            return Result.ok(skillService.mySkills(username));
        } catch (IllegalArgumentException e) {
            return Result.error(e.getMessage());
        }
    }

    private Long asLong(Object v) {
        if (v == null) {
            return null;
        }
        try {
            return Long.parseLong(String.valueOf(v));
        } catch (NumberFormatException e) {
            throw new IllegalArgumentException("功法编号不合法");
        }
    }
}
