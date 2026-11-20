package com.fenglin.springboottest.controller;

import com.fenglin.springboottest.common.Result;
import com.fenglin.springboottest.entity.UserSecret;
import com.fenglin.springboottest.service.SecretService;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

/**
 * 秘境·破界 REST 接口（贡献值经济闭环第二消耗端）：
 *
 *   GET  /api/secret/status?username=xxx   秘境状态：贡献值账本 + 已开辟秘境
 *   POST /api/secret/enter                 破界进入 { username, itemId }（门票扣贡献值）
 *   POST /api/secret/roam                  随机探秘 { username }（收天机引路费）
 *   GET  /api/secret/mine?username=xxx     我的已开辟秘境（洞府联动）
 */
@RestController
@RequestMapping("/api/secret")
public class SecretController {

    private final SecretService secretService;

    public SecretController(SecretService secretService) {
        this.secretService = secretService;
    }

    /** 秘境状态总览（贡献值余额 / 已开辟秘境 id 列表） */
    @GetMapping("/status")
    public Result<Map<String, Object>> status(@RequestParam String username) {
        try {
            return Result.ok(secretService.status(username));
        } catch (IllegalArgumentException e) {
            return Result.error(e.getMessage());
        } catch (Exception e) {
            return Result.error(secretInitHint());
        }
    }

    /** 破界进入指定秘境：门票扣贡献值，每人每秘境一次；首入掷探索奖励 */
    @PostMapping("/enter")
    public Result<Map<String, Object>> enter(@RequestBody Map<String, Object> body) {
        try {
            String username = body == null ? null : String.valueOf(body.get("username"));
            Long itemId = asLong(body == null ? null : body.get("itemId"));
            return Result.ok(secretService.enter(username, itemId));
        } catch (IllegalArgumentException e) {
            return Result.error(e.getMessage());
        } catch (Exception e) {
            return Result.error(secretInitHint());
        }
    }

    /** 随机探秘：收「天机引路费」后随机挑秘境并生成奇遇文案 */
    @PostMapping("/roam")
    public Result<Map<String, Object>> roam(@RequestBody Map<String, Object> body) {
        try {
            String username = body == null ? null : String.valueOf(body.get("username"));
            return Result.ok(secretService.roam(username));
        } catch (IllegalArgumentException e) {
            return Result.error(e.getMessage());
        } catch (Exception e) {
            return Result.error(secretInitHint());
        }
    }

    /** 我的已开辟秘境（洞府联动） */
    @GetMapping("/mine")
    public Result<List<UserSecret>> mine(@RequestParam String username) {
        try {
            return Result.ok(secretService.mySecrets(username));
        } catch (IllegalArgumentException e) {
            return Result.error(e.getMessage());
        } catch (Exception e) {
            return Result.error(secretInitHint());
        }
    }

    /** 储物空间（洞府联动）：历次探索获得的法宝 / 残篇 / 神通 */
    @GetMapping("/storage")
    public Result<List<Map<String, Object>>> storage(@RequestParam String username) {
        try {
            return Result.ok(secretService.storageCards(username));
        } catch (IllegalArgumentException e) {
            return Result.error(e.getMessage());
        } catch (Exception e) {
            return Result.error(secretInitHint());
        }
    }

    /** 秘境阵法未开辟（新表未建）时的统一提示 */
    private String secretInitHint() {
        return "秘境禁制未开：请重启后端并执行 sql/ensure_db.sql 初始化秘境阵法";
    }

    private Long asLong(Object v) {
        if (v == null) {
            return null;
        }
        try {
            return Long.parseLong(String.valueOf(v));
        } catch (NumberFormatException e) {
            throw new IllegalArgumentException("秘境编号不合法");
        }
    }
}
