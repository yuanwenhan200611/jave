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
 *
 * 注：旧的免费「/api/sect/explore」已下线——探索秘境一律走
 * /api/secret/roam（天机引路费 200，每次必收），不存在不收费的探索口子。
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
}
