package com.fenglin.springboottest.util;

import java.util.Map;
import java.util.UUID;
import java.util.concurrent.ConcurrentHashMap;

/**
 * 后台会话（单机演示版）：token -> 管理员账号，2 小时有效。
 * 前端把 token 放在请求头 X-Admin-Token 里，每个后台接口都校验。
 * 集群部署请换 Redis / Spring Session。
 */
public final class AdminSessionUtil {

    private static final long EXPIRE_MS = 2 * 60 * 60 * 1000L;
    private static final Map<String, Entry> STORE = new ConcurrentHashMap<>();

    private record Entry(String adminUsername, long expireAt) {
    }

    private AdminSessionUtil() {
    }

    /** 登录成功签发 token */
    public static String create(String adminUsername) {
        STORE.entrySet().removeIf(e -> e.getValue().expireAt() < System.currentTimeMillis());
        String token = UUID.randomUUID().toString().replace("-", "");
        STORE.put(token, new Entry(adminUsername, System.currentTimeMillis() + EXPIRE_MS));
        return token;
    }

    /** 校验 token，返回管理员账号；无效时抛出 AdminUnauthorizedException */
    public static String require(String token) {
        if (token == null || token.isBlank()) {
            throw new AdminUnauthorizedException("请先登录后台");
        }
        Entry entry = STORE.get(token.trim());
        if (entry == null || entry.expireAt() < System.currentTimeMillis()) {
            STORE.remove(token.trim());
            throw new AdminUnauthorizedException("后台登录已过期，请重新登录");
        }
        return entry.adminUsername();
    }

    /** 校验并返回会话信息（退出时也用它先确认身份） */
    public static Map<String, String> session(String token) {
        String adminUsername = require(token);
        return Map.of("adminUsername", adminUsername);
    }

    /** 退出登录 */
    public static void remove(String token) {
        if (token != null) {
            STORE.remove(token.trim());
        }
    }
}
