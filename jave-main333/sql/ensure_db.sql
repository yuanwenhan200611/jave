-- ============================================================
--  ensure_db.sql  —— 幂等确保 login_db 与 user 表存在
--  适用：每次 start.bat 启动时调用，环境重置后库会被清空，这里自动重建
--  特点：CREATE ... IF NOT EXISTS，演示账号仅在不存在时插入
--        不会 DROP 已有表，也不会清空用户自己注册的账号
-- ============================================================

-- 1. 建库（若不存在）
CREATE DATABASE IF NOT EXISTS `login_db`
  DEFAULT CHARACTER SET utf8mb4
  DEFAULT COLLATE utf8mb4_general_ci;

USE `login_db`;

-- 2. 建表（若不存在，保留数据）
CREATE TABLE IF NOT EXISTS `user` (
  `id`          BIGINT       NOT NULL AUTO_INCREMENT COMMENT '主键，自增',
  `username`    VARCHAR(50)  NOT NULL                COMMENT '用户名（3-20 位字母/数字/下划线，唯一）',
  `password`    VARCHAR(64)  NOT NULL                COMMENT '密码，MD5 32 位十六进制存储',
  `create_time` DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_username` (`username`)
) ENGINE = InnoDB
  DEFAULT CHARSET = utf8mb4
  COLLATE = utf8mb4_general_ci
  COMMENT = '用户表';

-- 3. 演示账号（仅当该用户名不存在时才插入，避免重复 / 不破坏已有数据）
--    MD5("123456") = e10adc3949ba59abbe56e057f20f883e
INSERT INTO `user` (`username`, `password`)
SELECT 'admin', 'e10adc3949ba59abbe56e057f20f883e'
WHERE NOT EXISTS (SELECT 1 FROM `user` WHERE `username` = 'admin');

INSERT INTO `user` (`username`, `password`)
SELECT 'test', 'e10adc3949ba59abbe56e057f20f883e'
WHERE NOT EXISTS (SELECT 1 FROM `user` WHERE `username` = 'test');

-- 4. 校验
SELECT COUNT(*) AS user_count FROM `user`;
