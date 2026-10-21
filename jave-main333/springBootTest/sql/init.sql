-- =============================================================
-- 登录注册示例数据库初始化脚本
-- 数据库: login_db    字符集: utf8mb4
-- 使用方式（任选其一）：
--   1. 命令行: mysql -uroot -p123456 < sql/init.sql
--   2. IDEA / Navicat 等工具直接执行本文件
-- =============================================================

DROP DATABASE IF EXISTS login_db;
CREATE DATABASE login_db DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;

USE login_db;

-- 用户表
DROP TABLE IF EXISTS `user`;
CREATE TABLE `user` (
    `id`          BIGINT       NOT NULL AUTO_INCREMENT COMMENT '主键',
    `username`    VARCHAR(20)  NOT NULL COMMENT '用户名(3-20位字母数字下划线)',
    `password`    VARCHAR(64)  NOT NULL COMMENT '密码(MD5加密存储)',
    `create_time` DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    `update_time` DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    PRIMARY KEY (`id`),
    UNIQUE KEY `uk_username` (`username`)
) ENGINE = InnoDB COMMENT ='用户表';

-- 演示账号: admin / 123456
INSERT INTO `user` (`username`, `password`) VALUES
('admin', 'e10adc3949ba59abbe56e057f20f883e');
