package com.fenglin.springboottest.controller;

import com.fenglin.springboottest.common.Result;
import com.fenglin.springboottest.service.HomeService;
import com.fenglin.springboottest.vo.ContentItemVO;
import com.fenglin.springboottest.vo.PageResult;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

/**
 * 首页相关 REST 接口，供 Vue 前端调用：
 *
 *   GET /api/home/summary                       首页展示（分类树 + 热门榜 + 最新 + 分类计数 + 品阶）
 *   GET /api/home/categories                    分类树（分级分类）
 *   GET /api/home/search                        搜索（分页）
 *                                                  keyword     可选，匹配标题/简介/品阶
 *                                                  categoryId  可选，传任意层级分类会包含其全部子孙分类
 *                                                  sort        可选，hot(默认)/new/grade/title
 *                                                  page        可选，页码，默认 1
 *                                                  size        可选，每页条数，默认 10（上限 100）
 *   GET /api/home/hot-keywords                  搜索热词（近 N 天日志统计，无日志时退回热榜标题）
 *   GET /api/home/item/{id}                     条目详情（浏览量 +1）
 *   GET /api/home/item/{id}/related             条目详情页的相关推荐
 *   POST /api/home/item/{id}/view               浏览量 +1（前端已浏览过详情时单独上报）
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

    /**
     * 搜索：支持关键词 + 分级分类过滤 + 分页 + 排序。
     * 关键词被截断到 50 字符，页码/条数越界会自动兜底，不会抛 500。
     */
    @GetMapping("/search")
    public Result<PageResult<ContentItemVO>> search(
            @RequestParam(required = false) String keyword,
            @RequestParam(required = false) Long categoryId,
            @RequestParam(required = false) String sort,
            @RequestParam(required = false, defaultValue = "1") Integer page,
            @RequestParam(required = false, defaultValue = "10") Integer size) {
        return Result.ok(homeService.searchPage(keyword, categoryId, sort, page, size));
    }

    /** 搜索热词 */
    @GetMapping("/hot-keywords")
    public Result<List<Map<String, Object>>> hotKeywords(
            @RequestParam(required = false, defaultValue = "10") Integer limit,
            @RequestParam(required = false, defaultValue = "30") Integer days) {
        return Result.ok(homeService.hotKeywords(limit, days));
    }

    /** 条目详情（同时浏览量 +1） */
    @GetMapping("/item/{id}")
    public Result<ContentItemVO> detail(@PathVariable Long id) {
        try {
            return Result.ok(homeService.detail(id));
        } catch (IllegalArgumentException e) {
            return Result.error(e.getMessage());
        }
    }

    /** 相关推荐 */
    @GetMapping("/item/{id}/related")
    public Result<List<ContentItemVO>> related(
            @PathVariable Long id,
            @RequestParam(required = false, defaultValue = "6") Integer limit) {
        return Result.ok(homeService.related(id, limit));
    }

    /** 浏览量 +1，返回 { viewCount: n } */
    @PostMapping("/item/{id}/view")
    public Result<Map<String, Object>> increaseView(@PathVariable Long id) {
        try {
            long count = homeService.increaseView(id);
            return Result.ok(Map.of("viewCount", count));
        } catch (IllegalArgumentException e) {
            return Result.error(e.getMessage());
        }
    }
}
