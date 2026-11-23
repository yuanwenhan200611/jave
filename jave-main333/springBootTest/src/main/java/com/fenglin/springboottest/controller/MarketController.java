package com.fenglin.springboottest.controller;

import com.fenglin.springboottest.common.Result;
import com.fenglin.springboottest.entity.MarketOrder;
import com.fenglin.springboottest.service.MarketService;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

/**
 * 坊市·交易市场 REST 接口（灵石经济第三极：买卖双向）：
 *
 *   GET  /api/market/list?username=xxx&category=all   坊市货架（含灵石余额 / 可寄售藏品）
 *   GET  /api/market/orders?username=xxx              我的交易手札
 *   POST /api/market/buy                              买货 { username, itemId }
 *   POST /api/market/sell                             寄售回购 { username, rewardId }
 *   POST /api/market/list-item                        自行挂单 { username, rewardId, price }
 *   POST /api/market/cancel                          撤单 { username, itemId }
 */
@RestController
@RequestMapping("/api/market")
public class MarketController {

    private final MarketService marketService;

    public MarketController(MarketService marketService) {
        this.marketService = marketService;
    }

    /** 坊市总览：灵石余额 + 在售货品 + 可寄售藏品 + 分类统计 */
    @GetMapping("/list")
    public Result<Map<String, Object>> list(@RequestParam String username,
                                            @RequestParam(required = false) String category) {
        try {
            return Result.ok(marketService.list(username, category));
        } catch (IllegalArgumentException e) {
            return Result.error(e.getMessage());
        } catch (Exception e) {
            return Result.error(marketInitHint());
        }
    }

    /** 我的交易手札（买入 / 卖出流水） */
    @GetMapping("/orders")
    public Result<List<MarketOrder>> orders(@RequestParam String username,
                                            @RequestParam(required = false, defaultValue = "20") int limit) {
        try {
            return Result.ok(marketService.orders(username, limit));
        } catch (IllegalArgumentException e) {
            return Result.error(e.getMessage());
        } catch (Exception e) {
            return Result.error(marketInitHint());
        }
    }

    /** 买货：扣灵石 → 法宝/残篇/神通入储物空间，功法免贡收录，丹药当场服用 */
    @PostMapping("/buy")
    public Result<Map<String, Object>> buy(@RequestBody Map<String, Object> body) {
        try {
            String username = body == null ? null : String.valueOf(body.get("username"));
            Long itemId = asLong(body == null ? null : body.get("itemId"), "货品编号不合法");
            return Result.ok(marketService.buy(username, itemId));
        } catch (IllegalArgumentException e) {
            return Result.error(e.getMessage());
        } catch (Exception e) {
            return Result.error(marketInitHint());
        }
    }

    /** 寄售回购：储物空间里的法宝/残篇/神通卖给坊市牙人换灵石 */
    @PostMapping("/sell")
    public Result<Map<String, Object>> sell(@RequestBody Map<String, Object> body) {
        try {
            String username = body == null ? null : String.valueOf(body.get("username"));
            Long rewardId = asLong(body == null ? null : body.get("rewardId"), "藏品编号不合法");
            return Result.ok(marketService.sell(username, rewardId));
        } catch (IllegalArgumentException e) {
            return Result.error(e.getMessage());
        } catch (Exception e) {
            return Result.error(marketInitHint());
        }
    }

    /** 自行挂单：给储物空间的藏品自由标价（牙人估价 0.5~3 倍），摆上私摊 */
    @PostMapping("/list-item")
    public Result<Map<String, Object>> listItem(@RequestBody Map<String, Object> body) {
        try {
            String username = body == null ? null : String.valueOf(body.get("username"));
            Long rewardId = asLong(body == null ? null : body.get("rewardId"), "藏品编号不合法");
            Long price = asLong(body == null ? null : body.get("price"), "标价不合法");
            return Result.ok(marketService.listItem(username, rewardId, price));
        } catch (IllegalArgumentException e) {
            return Result.error(e.getMessage());
        } catch (Exception e) {
            return Result.error(marketInitHint());
        }
    }

    /** 撤单：未售出的私摊货收回储物空间 */
    @PostMapping("/cancel")
    public Result<Map<String, Object>> cancel(@RequestBody Map<String, Object> body) {
        try {
            String username = body == null ? null : String.valueOf(body.get("username"));
            Long itemId = asLong(body == null ? null : body.get("itemId"), "货品编号不合法");
            return Result.ok(marketService.cancel(username, itemId));
        } catch (IllegalArgumentException e) {
            return Result.error(e.getMessage());
        } catch (Exception e) {
            return Result.error(marketInitHint());
        }
    }

    /** 坊市阵法未开辟（新表未建）时的统一提示 */
    private String marketInitHint() {
        return "坊市尚未开张：请重启后端并执行 sql/ensure_db.sql 初始化坊市阵法";
    }

    private Long asLong(Object v, String errorText) {
        if (v == null) {
            return null;
        }
        try {
            return Long.parseLong(String.valueOf(v));
        } catch (NumberFormatException e) {
            throw new IllegalArgumentException(errorText);
        }
    }
}
