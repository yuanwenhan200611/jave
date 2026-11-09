package com.fenglin.springboottest.controller;

import com.fenglin.springboottest.common.Result;
import com.fenglin.springboottest.entity.SectMember;
import com.fenglin.springboottest.service.SectService;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

/**
 * 宗门模块 REST 接口：
 *
 *   GET /api/sect/rank      宗门榜（战力降序）
 *   GET /api/sect/halls     各堂口人数统计
 *   GET /api/sect/explore   秘境探索（随机秘境 + 奇遇文案，浏览量 +1）
 */
@RestController
@RequestMapping("/api/sect")
@RequiredArgsConstructor
public class SectController {

    private final SectService sectService;

    /** 宗门榜 */
    @GetMapping("/rank")
    public Result<List<SectMember>> rank() {
        return Result.ok(sectService.rankBoard());
    }

    /** 堂口统计 */
    @GetMapping("/halls")
    public Result<Map<String, Long>> halls() {
        return Result.ok(sectService.hallStats());
    }

    /** 秘境探索 */
    @GetMapping("/explore")
    public Result<Map<String, Object>> explore() {
        try {
            return Result.ok(sectService.explore());
        } catch (IllegalArgumentException e) {
            return Result.error(e.getMessage());
        }
    }
}
