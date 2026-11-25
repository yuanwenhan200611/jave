-- ============================================================
--  seed_sect.sql —— 宗门榜 + 论道 模块种子（古风修仙魔宗风格）
--  幂等：CREATE IF NOT EXISTS；种子按判重插入，可反复执行
--  使用：mysql -uroot -p123456 --default-character-set=utf8mb4 < sql/seed_sect.sql
-- ============================================================
USE `login_db`;

-- 1. 宗门榜·弟子名录表 ----------------------------------------
CREATE TABLE IF NOT EXISTS `sect_member` (
  `id`           BIGINT       NOT NULL AUTO_INCREMENT COMMENT '主键',
  `name`         VARCHAR(50)  NOT NULL                COMMENT '道号',
  `realm`        VARCHAR(20)  NOT NULL                COMMENT '大境界：魔尊~炼气',
  `stage`        VARCHAR(16)  NULL                    COMMENT '境界层次：一层~九层/初期~巅峰/小成~巅峰/一重~九重',
  `title`        VARCHAR(50)  NULL                    COMMENT '称号/职位',
  `hall`         VARCHAR(30)  NULL                    COMMENT '所属堂口',
  `power`        BIGINT       NOT NULL DEFAULT 0      COMMENT '战力',
  `contribution` BIGINT       NOT NULL DEFAULT 0      COMMENT '宗门贡献',
  `icon`         VARCHAR(16)  NULL                    COMMENT '头像 emoji',
  `create_time`  DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '入门时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_member_name` (`name`)
) ENGINE = InnoDB
  DEFAULT CHARSET = utf8mb4
  COLLATE = utf8mb4_general_ci
  COMMENT = '宗门榜·弟子名录';

-- 2. 论道帖表 -------------------------------------------------
CREATE TABLE IF NOT EXISTS `forum_post` (
  `id`          BIGINT        NOT NULL AUTO_INCREMENT COMMENT '主键',
  `author`      VARCHAR(50)   NOT NULL                COMMENT '发帖人（用户名或道号）',
  `title`       VARCHAR(100)  NOT NULL                COMMENT '帖名',
  `content`     VARCHAR(2000) NOT NULL                COMMENT '正文',
  `views`       BIGINT        NOT NULL DEFAULT 0      COMMENT '围观量',
  `likes`       BIGINT        NOT NULL DEFAULT 0      COMMENT '道心相印（点赞）',
  `status`      TINYINT       NOT NULL DEFAULT 1      COMMENT '状态：1 显示 / 0 屏蔽',
  `create_time` DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '发帖时间',
  PRIMARY KEY (`id`),
  KEY `idx_post_time` (`create_time`)
) ENGINE = InnoDB
  DEFAULT CHARSET = utf8mb4
  COLLATE = utf8mb4_general_ci
  COMMENT = '论道帖';



-- 3.0 sect_member 增列 stage（MySQL 8 无 ADD COLUMN IF NOT EXISTS，条件语句幂等）
SET @col_exists := (
  SELECT COUNT(*) FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'sect_member'
    AND COLUMN_NAME = 'stage'
);
SET @ddl := IF(@col_exists = 0,
  'ALTER TABLE `sect_member` ADD COLUMN `stage` VARCHAR(16) NULL COMMENT ''境界层次：一层~九层/初期~巅峰/小成~巅峰/一重~九重'' AFTER `realm`',
  'SELECT 1');
PREPARE stmt FROM @ddl; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- 3. 宗门榜种子（判重：道号不存在才插入；2026-11-25 扩充至 78 人） ----
INSERT INTO `sect_member` (`name`, `realm`, `stage`, `title`, `hall`, `power`, `contribution`, `icon`)
SELECT t.name, t.realm, t.stage, t.title, t.hall, t.power, t.contribution, t.icon
FROM (
  SELECT '血无常' AS name, '魔尊' AS realm, '九重' AS stage, '宗主' AS title, '主殿' AS hall, 9999999 AS power, 999999 AS contribution, '😈' AS icon
  UNION ALL SELECT '阎罗娘子', '渡劫', '九劫', '副宗主', '血煞堂', 8800000, 620000, '🌙'
  UNION ALL SELECT '玄冥太上', '渡劫', '五劫', '太上长老', '主殿', 8200000, 580000, '🌌'
  UNION ALL SELECT '枯荣太上', '渡劫', '三劫', '太上长老', '主殿', 7900000, 560000, '🍂'
  UNION ALL SELECT '白骨真人', '渡劫', '七劫', '执法长老', '执法堂', 7600000, 540000, '💀'
  UNION ALL SELECT '无相太上', '渡劫', '一劫', '太上长老', '主殿', 7500000, 530000, '🫥'
  UNION ALL SELECT '血河太上', '大乘', '巅峰', '太上长老', '血煞堂', 6800000, 480000, '🩸'
  UNION ALL SELECT '天枢太上', '大乘', '后期', '太上长老', '千机堂', 6500000, 460000, '⭐'
  UNION ALL SELECT '千面魔君', '大乘', '圆满', '内务长老', '千机堂', 5900000, 410000, '🎭'
  UNION ALL SELECT '幽冥子', '大乘', '后期', '长老', '幽冥堂', 5200000, 380000, '🌑'
  UNION ALL SELECT '阴无极', '大乘', '中期', '内门长老', '幽冥堂', 4800000, 350000, '🌑'
  UNION ALL SELECT '厉青锋', '大乘', '初期', '内门长老', '执法堂', 4500000, 330000, '⚔️'
  UNION ALL SELECT '慕容寒', '合体', '巅峰', '内门长老', '千机堂', 4200000, 310000, '❄️'
  UNION ALL SELECT '姬无夜', '合体', '后期', '内门长老', '血煞堂', 4100000, 300000, '🌃'
  UNION ALL SELECT '司徒冥', '合体', '后期', '内门长老', '幽冥堂', 4000000, 295000, '👁️'
  UNION ALL SELECT '上官烬', '合体', '中期', '内门长老', '炼丹堂', 3900000, 285000, '🔥'
  UNION ALL SELECT '东方曜', '合体', '中期', '内门长老', '主殿', 3800000, 280000, '☀️'
  UNION ALL SELECT '南宫影', '合体', '初期', '内门长老', '执法堂', 3700000, 275000, '🌘'
  UNION ALL SELECT '西门朔', '合体', '初期', '内门长老', '千机堂', 3650000, 270000, '🌪️'
  UNION ALL SELECT '北堂幽', '合体', '初期', '内门长老', '幽冥堂', 3600000, 265000, '🕯️'
  UNION ALL SELECT '玉面罗刹', '合体', '巅峰', '堂主', '血煞堂', 3600000, 260000, '🌺'
  UNION ALL SELECT '赤炎老祖', '合体', '后期', '丹殿长老', '炼丹堂', 3300000, 245000, '🔥'
  UNION ALL SELECT '噬魂叟', '炼虚', '圆满', '长老', '幽冥堂', 2100000, 180000, '👁️'
  UNION ALL SELECT '墨鸦', '炼虚', '大成', '首席弟子', '执法堂', 1800000, 160000, '🐦'
  UNION ALL SELECT '铁面判', '炼虚', '圆满', '外门长老', '执法堂', 1750000, 155000, '🛡️'
  UNION ALL SELECT '鬼手翁', '炼虚', '圆满', '外门长老', '炼丹堂', 1720000, 152000, '🖐️'
  UNION ALL SELECT '枯木禅', '炼虚', '大成', '外门长老', '主殿', 1700000, 150000, '🪵'
  UNION ALL SELECT '血煞尊', '炼虚', '大成', '外门长老', '血煞堂', 1680000, 148000, '🩸'
  UNION ALL SELECT '幽鬼婆', '炼虚', '大成', '外门长老', '幽冥堂', 1650000, 145000, '👵'
  UNION ALL SELECT '燕无归', '炼虚', '小成', '外门长老', '执法堂', 1620000, 142000, '🕊️'
  UNION ALL SELECT '石敢当', '炼虚', '小成', '外门长老', '主殿', 1600000, 140000, '🗿'
  UNION ALL SELECT '雷震子', '炼虚', '小成', '外门长老', '执法堂', 1580000, 138000, '⚡'
  UNION ALL SELECT '毒娘子', '炼虚', '小成', '外门长老', '炼丹堂', 1560000, 135000, '☠️'
  UNION ALL SELECT '赵无情', '炼虚', '小成', '外门长老', '血煞堂', 1540000, 132000, '🔪'
  UNION ALL SELECT '钱通神', '炼虚', '小成', '外门长老', '千机堂', 1520000, 130000, '💰'
  UNION ALL SELECT '孙大隐', '炼虚', '小成', '外门长老', '幽冥堂', 1500000, 128000, '🕳️'
  UNION ALL SELECT '郑铁山', '炼虚', '小成', '外门长老', '执法堂', 1480000, 125000, '⛰️'
  UNION ALL SELECT '周五邪', '炼虚', '小成', '外门长老', '血煞堂', 1460000, 122000, '🃏'
  UNION ALL SELECT '吴钩叟', '炼虚', '小成', '外门长老', '千机堂', 1440000, 120000, '🗡️'
  UNION ALL SELECT '凌天骄', '化神', '巅峰', '圣子', '主殿', 980000, 120000, '🔥'
  UNION ALL SELECT '冷月心', '化神', '巅峰', '圣女', '主殿', 960000, 115000, '🌙'
  UNION ALL SELECT '苏九黎', '化神', '巅峰', '内门弟子', '千机堂', 900000, 95000, '🦋'
  UNION ALL SELECT '顾长歌', '化神', '中期', '真传弟子', '千机堂', 880000, 92000, '🎼'
  UNION ALL SELECT '谢无咎', '化神', '后期', '外门弟子', '血煞堂', 850000, 88000, '⚔️'
  UNION ALL SELECT '沈傲霜', '化神', '初期', '真传弟子', '执法堂', 830000, 90000, '❄️'
  UNION ALL SELECT '白夜行', '元婴', '巅峰', '真传弟子', '幽冥堂', 800000, 85000, '🌑'
  UNION ALL SELECT '韩立雪', '元婴', '巅峰', '真传弟子', '炼丹堂', 780000, 82000, '❄️'
  UNION ALL SELECT '叶无痕', '元婴', '后期', '真传弟子', '血煞堂', 760000, 80000, '🍃'
  UNION ALL SELECT '楚天阔', '元婴', '后期', '真传弟子', '千机堂', 740000, 78000, '🌊'
  UNION ALL SELECT '段惊鸿', '元婴', '中期', '真传弟子', '执法堂', 720000, 75000, '🦅'
  UNION ALL SELECT '唐不哭', '元婴', '中期', '真传弟子', '血煞堂', 700000, 72000, '😢'
  UNION ALL SELECT '花非花', '元婴', '初期', '真传弟子', '幽冥堂', 680000, 70000, '🌸'
  UNION ALL SELECT '秦无焰', '元婴', '初期', '真传弟子', '炼丹堂', 660000, 68000, '🔥'
  UNION ALL SELECT '林青衣', '金丹', '巅峰', '内门弟子', '千机堂', 420000, 48000, '👕'
  UNION ALL SELECT '陆斩月', '金丹', '巅峰', '内门弟子', '血煞堂', 400000, 45000, '🌙'
  UNION ALL SELECT '萧别离', '金丹', '后期', '内门弟子', '执法堂', 380000, 42000, '🚶'
  UNION ALL SELECT '慕青鸾', '金丹', '后期', '内门弟子', '千机堂', 360000, 40000, '🦅'
  UNION ALL SELECT '厉飞雨', '金丹', '中期', '内门弟子', '炼丹堂', 340000, 38000, '🌧️'
  UNION ALL SELECT '钟离昧', '金丹', '中期', '内门弟子', '幽冥堂', 320000, 35000, '🔔'
  UNION ALL SELECT '独孤残', '金丹', '初期', '内门弟子', '血煞堂', 300000, 32000, '🦾'
  UNION ALL SELECT '南飞雁', '金丹', '初期', '内门弟子', '主殿', 280000, 30000, '🪶'
  UNION ALL SELECT '雷小斧', '金丹', '初期', '外门弟子', '血煞堂', 270000, 29000, '🪓'
  UNION ALL SELECT '苏小媚', '金丹', '初期', '外门弟子', '千机堂', 265000, 28500, '🦊'
  UNION ALL SELECT '阿蛮', '金丹', '中期', '记名弟子', '炼丹堂', 260000, 30000, '🍖'
  UNION ALL SELECT '铁牛', '筑基', '巅峰', '外门弟子', '血煞堂', 90000, 12000, '🐂'
  UNION ALL SELECT '王二牛', '筑基', '后期', '外门弟子', '执法堂', 85000, 11000, '🐃'
  UNION ALL SELECT '张小乙', '筑基', '中期', '外门弟子', '千机堂', 80000, 10000, '📜'
  UNION ALL SELECT '陈三炮', '筑基', '初期', '外门弟子', '炼丹堂', 75000, 9000, '💥'
  UNION ALL SELECT '刘四刀', '筑基', '初期', '外门弟子', '血煞堂', 70000, 8500, '🔪'
  UNION ALL SELECT '赵五毒', '筑基', '初期', '外门弟子', '幽冥堂', 65000, 8000, '☠️'
  UNION ALL SELECT '孙六指', '筑基', '初期', '外门弟子', '千机堂', 60000, 7500, '✋'
  UNION ALL SELECT '周七煞', '筑基', '初期', '外门弟子', '执法堂', 55000, 7000, '👿'
  UNION ALL SELECT '吴小宝', '炼气', '九层', '记名弟子', '主殿', 9000, 1500, '🧒'
  UNION ALL SELECT '郑大钱', '炼气', '八层', '记名弟子', '千机堂', 8000, 1300, '💰'
  UNION ALL SELECT '冯二狗', '炼气', '七层', '记名弟子', '血煞堂', 7000, 1100, '🐕'
  UNION ALL SELECT '陈小花', '炼气', '六层', '记名弟子', '炼丹堂', 6000, 900, '🌷'
  UNION ALL SELECT '褚小石', '炼气', '五层', '记名弟子', '幽冥堂', 5000, 700, '🪨'
  UNION ALL SELECT '卫小刀', '炼气', '三层', '记名弟子', '执法堂', 3000, 400, '🔪'
) AS t
WHERE NOT EXISTS (SELECT 1 FROM `sect_member` x WHERE x.name = t.name);

-- 3.1 老库补层次：按道号回填 stage（幂等，重复执行值不变）
UPDATE `sect_member` SET `stage` = CASE `name`
    WHEN '血无常' THEN '九重'
    WHEN '阎罗娘子' THEN '九劫'
    WHEN '玄冥太上' THEN '五劫'
    WHEN '枯荣太上' THEN '三劫'
    WHEN '白骨真人' THEN '七劫'
    WHEN '无相太上' THEN '一劫'
    WHEN '血河太上' THEN '巅峰'
    WHEN '天枢太上' THEN '后期'
    WHEN '千面魔君' THEN '圆满'
    WHEN '幽冥子' THEN '后期'
    WHEN '阴无极' THEN '中期'
    WHEN '厉青锋' THEN '初期'
    WHEN '慕容寒' THEN '巅峰'
    WHEN '姬无夜' THEN '后期'
    WHEN '司徒冥' THEN '后期'
    WHEN '上官烬' THEN '中期'
    WHEN '东方曜' THEN '中期'
    WHEN '南宫影' THEN '初期'
    WHEN '西门朔' THEN '初期'
    WHEN '北堂幽' THEN '初期'
    WHEN '玉面罗刹' THEN '巅峰'
    WHEN '赤炎老祖' THEN '后期'
    WHEN '噬魂叟' THEN '圆满'
    WHEN '墨鸦' THEN '大成'
    WHEN '铁面判' THEN '圆满'
    WHEN '鬼手翁' THEN '圆满'
    WHEN '枯木禅' THEN '大成'
    WHEN '血煞尊' THEN '大成'
    WHEN '幽鬼婆' THEN '大成'
    WHEN '燕无归' THEN '小成'
    WHEN '石敢当' THEN '小成'
    WHEN '雷震子' THEN '小成'
    WHEN '毒娘子' THEN '小成'
    WHEN '赵无情' THEN '小成'
    WHEN '钱通神' THEN '小成'
    WHEN '孙大隐' THEN '小成'
    WHEN '郑铁山' THEN '小成'
    WHEN '周五邪' THEN '小成'
    WHEN '吴钩叟' THEN '小成'
    WHEN '凌天骄' THEN '巅峰'
    WHEN '冷月心' THEN '巅峰'
    WHEN '苏九黎' THEN '巅峰'
    WHEN '顾长歌' THEN '中期'
    WHEN '谢无咎' THEN '后期'
    WHEN '沈傲霜' THEN '初期'
    WHEN '白夜行' THEN '巅峰'
    WHEN '韩立雪' THEN '巅峰'
    WHEN '叶无痕' THEN '后期'
    WHEN '楚天阔' THEN '后期'
    WHEN '段惊鸿' THEN '中期'
    WHEN '唐不哭' THEN '中期'
    WHEN '花非花' THEN '初期'
    WHEN '秦无焰' THEN '初期'
    WHEN '林青衣' THEN '巅峰'
    WHEN '陆斩月' THEN '巅峰'
    WHEN '萧别离' THEN '后期'
    WHEN '慕青鸾' THEN '后期'
    WHEN '厉飞雨' THEN '中期'
    WHEN '钟离昧' THEN '中期'
    WHEN '独孤残' THEN '初期'
    WHEN '南飞雁' THEN '初期'
    WHEN '雷小斧' THEN '初期'
    WHEN '苏小媚' THEN '初期'
    WHEN '阿蛮' THEN '中期'
    WHEN '铁牛' THEN '巅峰'
    WHEN '王二牛' THEN '后期'
    WHEN '张小乙' THEN '中期'
    WHEN '陈三炮' THEN '初期'
    WHEN '刘四刀' THEN '初期'
    WHEN '赵五毒' THEN '初期'
    WHEN '孙六指' THEN '初期'
    WHEN '周七煞' THEN '初期'
    WHEN '吴小宝' THEN '九层'
    WHEN '郑大钱' THEN '八层'
    WHEN '冯二狗' THEN '七层'
    WHEN '陈小花' THEN '六层'
    WHEN '褚小石' THEN '五层'
    WHEN '卫小刀' THEN '三层'
END
WHERE `name` IN ('血无常', '阎罗娘子', '玄冥太上', '枯荣太上', '白骨真人', '无相太上', '血河太上', '天枢太上', '千面魔君', '幽冥子', '阴无极', '厉青锋', '慕容寒', '姬无夜', '司徒冥', '上官烬', '东方曜', '南宫影', '西门朔', '北堂幽', '玉面罗刹', '赤炎老祖', '噬魂叟', '墨鸦', '铁面判', '鬼手翁', '枯木禅', '血煞尊', '幽鬼婆', '燕无归', '石敢当', '雷震子', '毒娘子', '赵无情', '钱通神', '孙大隐', '郑铁山', '周五邪', '吴钩叟', '凌天骄', '冷月心', '苏九黎', '顾长歌', '谢无咎', '沈傲霜', '白夜行', '韩立雪', '叶无痕', '楚天阔', '段惊鸿', '唐不哭', '花非花', '秦无焰', '林青衣', '陆斩月', '萧别离', '慕青鸾', '厉飞雨', '钟离昧', '独孤残', '南飞雁', '雷小斧', '苏小媚', '阿蛮', '铁牛', '王二牛', '张小乙', '陈三炮', '刘四刀', '赵五毒', '孙六指', '周七煞', '吴小宝', '郑大钱', '冯二狗', '陈小花', '褚小石', '卫小刀');

-- 4. 论道种子（判重：帖名不存在才插入） ------------------------
INSERT INTO `forum_post` (`author`, `title`, `content`, `views`, `likes`)
SELECT t.author, t.title, t.content, t.views, t.likes
FROM (
  SELECT '血无常' AS author, '【置顶】宗门戒律第一条：不得欺师灭祖' AS title,
         '戒律三百条，此为第一条。违者：废修为、逐出宗门、追杀千里。望诸弟子谨记。' AS content, 5200 AS views, 1314 AS likes
  UNION ALL SELECT '白骨真人', '论炼体与炼心孰优孰劣', '炼体者皮糙肉厚一力破万法，炼心者神识如网千里锁敌。依老夫看，都没我一根骨头硬。不服者执法堂领教。', 3400, 880
  UNION ALL SELECT '幽冥子', '幽冥鬼市亲历：我只带了三成寿元进去', '子时入市的道友切记：鬼商报价只砍一轮，第二轮他还价就是看上你的寿元了。附避坑清单，阅后即焚。', 4600, 720
  UNION ALL SELECT '赤炎老祖', '求破境丹真伪鉴定', '丹坊新收一枚破境丹，丹纹三圈、气味微腥。有人说是赝品，有人说是丹纹独树一帜。懂行的道友掌掌眼。', 2100, 450
  UNION ALL SELECT '千面魔君', '万剑坟场捡剑指南（勿外传）', '戌时剑鸣最弱，从东南坡绕开剑气林，见残剑先拜三拜。此帖发完我去坟场蹲点，看看是谁在偷师。', 5800, 903
  UNION ALL SELECT '玉面罗刹', '血煞堂招新，只收心狠手辣者', '本堂扩招。要求：一敢下手，二不废话，三听指挥。修为不限，金丹以上可直接面见堂主。', 3900, 666
  UNION ALL SELECT '苏九黎', '心魔幻阵第七层卡了三个月，求破', '每次都死在"故人相认"那一幕。明知是幻，偏偏醒不过来。过来人道友给个法子，愿以丹方相谢。', 1800, 512
  UNION ALL SELECT '阿蛮', '论道规则：辱骂道友者罚扫藏经阁三月', '新来的道友看过来：论道讲的是以理服人，骂人一时爽，藏经阁扫地扫断腰。文明论道，从你我做起。', 900, 233
) AS t
WHERE NOT EXISTS (SELECT 1 FROM `forum_post` x WHERE x.title = t.title);

-- 5. 校验 -----------------------------------------------------
SELECT COUNT(*) AS 宗门榜人数 FROM `sect_member`;
SELECT COUNT(*) AS 论道帖数 FROM `forum_post`;
