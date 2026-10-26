package com.fenglin.springboottest.controller;

import com.fenglin.springboottest.common.Result;
import com.fenglin.springboottest.service.HomeService;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

/**
 * 首页相关 REST 接口，供 Vue 前端调用：
 *   GET /api/home/summary       首页展示（分类树 + 热门条目）
 *   GET /api/home/categories    分类树（分级分类）
 *   GET /api/home/search        搜索（keyword 可选；categoryId 可选，支持分级分类搜索：
 *                               传任意层级分类 id 会包含其全部子孙分类的结果）
 */
@RestController
@RequestMapping("/api/home")
@RequiredArgsConstructor
public class HomeController {

    private final HomeService homeService;

    /** 首页展示数据 */
    @GetMapping("/summary")
    public Result<Map<String, Object>> summary() {
        return Result.ok(homeService.homeSummary());
    }

    /** 分类树 */
    @GetMapping("/categories")
    public Result<?> categories() {
        return Result.ok(homeService.categoryTree());
    }

    /** 搜索：支持关键词 + 分级分类过滤 */
    @GetMapping("/search")
    public Result<Map<String, Object>> search(
            @RequestParam(required = false) String keyword,
            @RequestParam(required = false) Long categoryId) {
        return Result.ok(homeService.search(keyword, categoryId));
    }
}
