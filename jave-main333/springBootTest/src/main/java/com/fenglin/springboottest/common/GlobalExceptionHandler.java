package com.fenglin.springboottest.common;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;

/**
 * 全局异常处理：
 * - 完整异常堆栈打到后端日志（方便用 IDEA / 控制台定位真实原因，通常是英文）。
 * - 给前端的提示翻译成中文并按常见类型归类，避免直接把 JDBC/MySQL 的英文原始报错甩给用户。
 */
@RestControllerAdvice
public class GlobalExceptionHandler {

    private static final Logger log = LoggerFactory.getLogger(GlobalExceptionHandler.class);

    @ExceptionHandler(Exception.class)
    public Result<Void> handle(Exception e) {
        // 1) 真实异常完整记录到后端日志（含英文原文、堆栈）
        log.error("【未处理异常】", e);

        // 2) 给前端的提示：中文 + 归类，便于普通用户理解
        String raw = e.getMessage();
        if (raw != null) {
            String m = raw.toLowerCase();
            // 连接类：MySQL 没起 / 账号密码不对 / 网络不通
            if (m.contains("communication") || m.contains("connection") || m.contains("hikari")
                    || m.contains("access denied") || m.contains("refused") || m.contains("timed out")) {
                return Result.error(500, "数据库连不上：请确认 MySQL 已启动，且 root/123456 能登录");
            }
            // 库/表不存在：没执行初始化 SQL
            if (m.contains("doesn't exist") || m.contains("does not exist")
                    || m.contains("unknown database")
                    || (m.contains("table") && m.contains("exist"))) {
                return Result.error(500, "数据库或表不存在：请先执行项目里的 sql/init.sql 初始化 login_db 和 user 表");
            }
            // SQL 语法类：多半是表名/字段名命中保留字
            if (m.contains("sql syntax") || m.contains("syntax error") || m.contains("you have an error")) {
                return Result.error(500, "SQL 语法错误：多半是表名/字段名命中数据库保留字，详见后端日志");
            }
        }
        return Result.error(500, "服务器内部错误，详细原因已打印在后端控制台日志");
    }
}
