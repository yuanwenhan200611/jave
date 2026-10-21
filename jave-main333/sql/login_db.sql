-- ============================================================
--  login_db 初始化脚本
--  适用环境：MySQL 8.x，账号 root / 123456
--  对应后端：springBootTest (Spring Boot 3.4.5 + MyBatis-Plus)
--  说明：实体 User 对应表 user；验证码存于内存，无需建表
--
--  用法（任选其一）：
--   1) 命令行：  mysql -uroot -p123456 < login_db.sql
--   2) IDEA：   Database 面板 -> New -> Query Console -> 粘贴执行
--   3) 客户端： 先 SELECT 这段脚本执行即可（已含建库/建表幂等判断）
-- ============================================================

-- 1. 创建数据库（若不存在），字符集 utf8mb4 以兼容中文与表情
CREATE DATABASE IF NOT EXISTS `login_db`
  DEFAULT CHARACTER SET utf8mb4
  DEFAULT COLLATE utf8mb4_general_ci;

USE `login_db`;

-- 2. 用户表（对应 com.fenglin.springboottest.entity.User）
--    create_time / update_time 由数据库默认值维护，插入时无需赋值
DROP TABLE IF EXISTS `user`;
CREATE TABLE `user` (
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

-- 3. 演示数据（密码均为明文 123456 的 MD5）
--    MD5("123456") = e10adc3949ba59abbe56e057f20f883e
INSERT INTO `user` (`username`, `password`) VALUES
  ('admin', 'e10adc3949ba59abbe56e057f20f883e'),
  ('test',  'e10adc3949ba59abbe56e057f20f883e');

-- 4. 校验
SELECT 'init done' AS result;
SELECT COUNT(*) AS user_count FROM `user`;
