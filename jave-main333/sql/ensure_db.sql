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

-- ============================================================
-- 5. 首页模块：分级分类表 + 内容条目表（幂等建表 + 演示数据）
-- ============================================================

-- 5.1 分级分类表（parent_id 自引用实现多级）
CREATE TABLE IF NOT EXISTS `category` (
  `id`          BIGINT      NOT NULL AUTO_INCREMENT COMMENT '主键，自增',
  `name`        VARCHAR(50) NOT NULL                COMMENT '分类名称',
  `parent_id`   BIGINT      NOT NULL DEFAULT 0      COMMENT '父分类 id，0 表示顶级',
  `level`       INT         NOT NULL DEFAULT 1      COMMENT '层级：1 顶级 / 2 二级 / 3 三级...',
  `sort`        INT         NOT NULL DEFAULT 0      COMMENT '排序值，越小越靠前',
  `icon`        VARCHAR(16) NULL                    COMMENT '图标（emoji）',
  `description` VARCHAR(200) NULL                   COMMENT '分类描述',
  `create_time` DATETIME    NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  PRIMARY KEY (`id`),
  KEY `idx_parent` (`parent_id`)
) ENGINE = InnoDB
  DEFAULT CHARSET = utf8mb4
  COLLATE = utf8mb4_general_ci
  COMMENT = '首页分级分类表';

-- 5.2 内容条目表（首页展示 + 搜索的数据主体）
CREATE TABLE IF NOT EXISTS `content_item` (
  `id`          BIGINT       NOT NULL AUTO_INCREMENT COMMENT '主键，自增',
  `title`       VARCHAR(100) NOT NULL                COMMENT '标题',
  `description` VARCHAR(500) NULL                    COMMENT '简介',
  `category_id` BIGINT       NOT NULL                COMMENT '所属分类 id（可为任意层级分类）',
  `grade`       VARCHAR(20)  NULL                    COMMENT '品阶（天阶/地阶/玄阶/黄阶等）',
  `icon`        VARCHAR(16)  NULL                    COMMENT '图标（emoji，展示用）',
  `view_count`  BIGINT       NOT NULL DEFAULT 0      COMMENT '浏览量',
  `status`      TINYINT      NOT NULL DEFAULT 1      COMMENT '状态：1 上架 / 0 下架',
  `create_time` DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`),
  KEY `idx_category` (`category_id`),
  KEY `idx_title` (`title`)
) ENGINE = InnoDB
  DEFAULT CHARSET = utf8mb4
  COLLATE = utf8mb4_general_ci
  COMMENT = '首页内容条目表';

-- 5.3 演示分类（仅当 category 表为空时插入；顶级 6 类 + 各带二级）
INSERT INTO `category` (`name`, `parent_id`, `level`, `sort`, `icon`, `description`)
SELECT * FROM (
  SELECT '功法' AS name, 0 AS parent_id, 1 AS level, 1 AS sort, '📜' AS icon, '诸天功法，皆可习练' AS description
  UNION ALL SELECT '秘境', 0, 1, 2, '🗺️', '无尽秘境，待你开辟'
  UNION ALL SELECT '丹药', 0, 1, 3, '⚗️', '逆天改命之丹'
  UNION ALL SELECT '法宝', 0, 1, 4, '🗡️', '神兵利器，掌中乾坤'
  UNION ALL SELECT '灵兽', 0, 1, 5, '🐉', '万兽臣服，皆入麾下'
  UNION ALL SELECT '典籍', 0, 1, 6, '📖', '万载传承，尽数收录'
) AS t
WHERE NOT EXISTS (SELECT 1 FROM `category`);

-- 二级分类（依赖上面的顶级分类名）
INSERT INTO `category` (`name`, `parent_id`, `level`, `sort`, `icon`, `description`)
SELECT c2.name, c1.id, 2, c2.sort, c2.icon, c2.description
FROM (
  SELECT '炼体功法' AS name, 1 AS sort, '💪' AS icon, '淬体炼骨，根基之道' AS description, '功法' AS parent_name
  UNION ALL SELECT '心法口诀', 2, '🧘', '凝聚灵力，运转周天', '功法'
  UNION ALL SELECT '上古秘境', 1, '🗿', '洪荒遗地，机缘无数', '秘境'
  UNION ALL SELECT '幻境试炼', 2, '🌫️', '心魔考验，突破之地', '秘境'
  UNION ALL SELECT '回春丹', 1, '🌿', '疗伤圣药', '丹药'
  UNION ALL SELECT '破境丹', 2, '⚡', '助修士破除瓶颈', '丹药'
  UNION ALL SELECT '攻击法宝', 1, '⚔️', '斩敌破阵', '法宝'
  UNION ALL SELECT '防御法宝', 2, '🛡️', '护体保命', '法宝'
  UNION ALL SELECT '飞行灵兽', 1, '🦅', '翱翔九天', '灵兽'
  UNION ALL SELECT '守护灵兽', 2, '🐺', '忠心护主', '灵兽'
) AS c2
JOIN `category` c1 ON c1.name = c2.parent_name AND c1.parent_id = 0
WHERE NOT EXISTS (SELECT 1 FROM `category` WHERE `level` = 2);

-- 5.4 演示条目（仅当 content_item 表为空时插入）
INSERT INTO `content_item` (`title`, `description`, `category_id`, `grade`, `icon`, `view_count`)
SELECT t.title, t.description, c.id, t.grade, t.icon, t.view_count
FROM (
  SELECT '吞天魔功' AS title, '上古魔宗镇宗功法，吞纳天地灵气化为己用' AS description, '天阶' AS grade, '📜' AS icon, 9999 AS view_count, '心法口诀' AS cat
  UNION ALL SELECT '九转玄冥体', '以魔气淬体的无上炼体法，肉身可撼山岳', '地阶', '💪', 8600, '炼体功法'
  UNION ALL SELECT '幽冥血海秘境', '上古魔神陨落之地，遍地机缘亦遍地杀机', '天阶', '🗿', 9200, '上古秘境'
  UNION ALL SELECT '心魔幻阵', '闯过者道心通明，闯不过者道基尽毁', '玄阶', '🌫️', 7300, '幻境试炼'
  UNION ALL SELECT '九转还魂丹', '传说可令陨落修士重生的禁忌丹药', '天阶', '🌿', 8800, '回春丹'
  UNION ALL SELECT '破境丹', '卡境界者的福音，一枚可搏一次突破契机', '地阶', '⚡', 6500, '破境丹'
  UNION ALL SELECT '诛仙魔剑', '饮血万千的魔道至宝，出鞘必见血', '天阶', '⚔️', 9998, '攻击法宝'
  UNION ALL SELECT '玄武宝甲', '取上古玄武甲壳炼制，刀枪不入', '地阶', '🛡️', 5400, '防御法宝'
  UNION ALL SELECT '赤炎火凤', '南明离火所化，可载人日行十万八千里', '天阶', '🦅', 7700, '飞行灵兽'
  UNION ALL SELECT '啸月天狼', '月圆之夜战力翻倍的忠勇灵兽', '玄阶', '🐺', 4800, '守护灵兽'
  UNION ALL SELECT '魔宗起居注', '历代宗主手札，藏着宗门最大的秘密', '地阶', '📖', 6100, '典籍'
  UNION ALL SELECT '化神诀残卷', '残缺的上古化神法门，参悟者寥寥', '玄阶', '📜', 3900, '心法口诀'
) AS t
JOIN `category` c ON c.name = t.cat
WHERE NOT EXISTS (SELECT 1 FROM `content_item`);

-- 6. 校验
SELECT COUNT(*) AS user_count FROM `user`;
SELECT COUNT(*) AS category_count FROM `category`;
SELECT COUNT(*) AS content_count FROM `content_item`;

-- 7. 内容条目批量种子（古风修仙风格，10 个二级分类 + 典籍，每类 10 条以上）
--    幂等：按 title 判重，可重复执行；内容见同目录 sql/seed_content.sql
--    单独灌数据：mysql -uroot -p123456 --default-character-set=utf8mb4 < sql/seed_content.sql
