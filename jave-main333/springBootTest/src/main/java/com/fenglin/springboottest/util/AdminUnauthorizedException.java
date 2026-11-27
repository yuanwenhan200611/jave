package com.fenglin.springboottest.util;

/** 后台会话未登录 / 已过期，控制器据此返回 401 */
public class AdminUnauthorizedException extends RuntimeException {

    public AdminUnauthorizedException(String message) {
        super(message);
    }
}
