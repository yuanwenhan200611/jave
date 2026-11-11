-- ============================================================
--  user_profile 个人档案表（洞府页面）
--  适用环境：MySQL 8.x，账号 root / 123456，库 login_db
--  对应后端：com.fenglin.springboottest.entity.UserProfile
--
--  用法：mysql -uroot -p123456 < user_profile.sql
--  说明：以 username 唯一关联 user 表；首次访问洞府时由后端
--        自动生成默认档案，无需预置数据。
-- ============================================================

CREATE DATABASE IF NOT EXISTS `login_db`
  DEFAULT CHARACTER SET utf8mb4
  DEFAULT COLLATE utf8mb4_general_ci;

USE `login_db`;

CREATE TABLE IF NOT EXISTS `user_profile` (
  `id`          BIGINT       NOT NULL AUTO_INCREMENT COMMENT '主键，自增',
  `username`    VARCHAR(50)  NOT NULL                COMMENT '用户名（唯一，关联 user.username）',
  `nickname`    VARCHAR(20)  NOT NULL                COMMENT '道号（展示昵称）',
  `icon`        VARCHAR(8)   DEFAULT NULL            COMMENT '头像 emoji（后端默认 🧑‍🦲）',
  `realm`       VARCHAR(10)  DEFAULT '炼气'           COMMENT '境界：炼气~魔尊',
  `hall`        VARCHAR(10)  DEFAULT '血煞堂'         COMMENT '所属堂口',
  `bio`         VARCHAR(100) DEFAULT ''              COMMENT '道语签名',
  `create_time` DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_username` (`username`)
) ENGINE = InnoDB
  DEFAULT CHARSET = utf8mb4
  COLLATE = utf8mb4_general_ci
  COMMENT = '用户个人档案表（洞府）';

SELECT 'user_profile ready' AS result;
