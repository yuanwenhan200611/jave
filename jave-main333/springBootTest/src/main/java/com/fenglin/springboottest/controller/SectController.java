package com.fenglin.springboottest.controller;

import com.fenglin.springboottest.common.Result;
import com.fenglin.springboottest.service.SectService;
import com.fenglin.springboottest.vo.RankEntryVO;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

/**
 * 宗门模块 REST 接口：
 *
 *   GET /api/sect/rank?username=xxx&sortBy=power|contribution&tier=elder|disciple|all
 *                              宗门榜（NPC + 当前玩家实时折算；默认全宗、战力降序）
 *   GET /api/sect/halls?username=xxx&tier=elder|disciple|all
 *                              各堂口人数统计（含当前玩家，与当前榜单同范围）
 *
 * 注：旧的免费「/api/sect/explore」已下线——探索秘境一律走
 * /api/secret/roam（天机引路费 200，每次必收），不存在不收费的探索口子。
 */
@RestController
@RequestMapping("/api/sect")
@RequiredArgsConstructor
public class SectController {

    private final SectService sectService;

    /**
     * 宗门榜：username 非空时把玩家并入排行。
     * sortBy = power / contribution；tier = elder（长老榜）/ disciple（弟子榜）/ all（全宗）。
     */
    @GetMapping("/rank")
    public Result<List<RankEntryVO>> rank(
            @RequestParam(required = false) String username,
            @RequestParam(required = false, defaultValue = "power") String sortBy,
            @RequestParam(required = false, defaultValue = "all") String tier) {
        return Result.ok(sectService.rankBoard(username, sortBy, tier));
    }

    /** 堂口统计（与当前榜单同范围） */
    @GetMapping("/halls")
    public Result<Map<String, Long>> halls(
            @RequestParam(required = false) String username,
            @RequestParam(required = false, defaultValue = "all") String tier) {
        return Result.ok(sectService.hallStats(username, tier));
    }
}
