package com.fenglin.springboottest.controller;

import com.fenglin.springboottest.common.Result;
import com.fenglin.springboottest.service.CultivationService;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

/**
 * 魔功殿（增修为）REST 接口：
 *
 *   GET  /api/cultivation/info?username=xxx   总览（修为进度 / 灵石贡献余额 / 法门冷却 / 修炼记录）
 *   POST /api/cultivation/practice            修炼一门魔功 { username, key }
 *                                             （校验冷却与余额，掷结果：大成/小成/反噬，自动突破境界）
 */
@RestController
@RequestMapping("/api/cultivation")
public class CultivationController {

    private final CultivationService cultivationService;

    public CultivationController(CultivationService cultivationService) {
        this.cultivationService = cultivationService;
    }

    /** 魔功殿总览 */
    @GetMapping("/info")
    public Result<Map<String, Object>> info(@RequestParam String username) {
        try {
            return Result.ok(cultivationService.info(username));
        } catch (IllegalArgumentException e) {
            return Result.error(e.getMessage());
        }
    }

    /** 修炼一门魔功 */
    @PostMapping("/practice")
    public Result<Map<String, Object>> practice(@RequestBody(required = false) Map<String, Object> body) {
        if (body == null) {
            return Result.error("请求体不能为空");
        }
        try {
            return Result.ok(cultivationService.practice(
                    body.get("username") == null ? null : String.valueOf(body.get("username")),
                    body.get("key") == null ? null : String.valueOf(body.get("key"))));
        } catch (IllegalArgumentException e) {
            return Result.error(e.getMessage());
        }
    }
}
