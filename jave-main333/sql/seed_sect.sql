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
  `realm`        VARCHAR(20)  NOT NULL                COMMENT '境界：魔尊/渡劫/大乘/合体/炼虚/化神/元婴/金丹/筑基/炼气',
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

-- 3. 宗门榜种子（判重：道号不存在才插入） ----------------------
INSERT INTO `sect_member` (`name`, `realm`, `title`, `hall`, `power`, `contribution`, `icon`)
SELECT t.name, t.realm, t.title, t.hall, t.power, t.contribution, t.icon
FROM (
  SELECT '血无常' AS name, '魔尊' AS realm, '宗主' AS title, '主殿' AS hall, 9999999 AS power, 999999 AS contribution, '😈' AS icon
  UNION ALL SELECT '阎罗娘子', '渡劫', '副宗主', '血煞堂', 8800000, 620000, '🌙'
  UNION ALL SELECT '白骨真人', '渡劫', '执法长老', '执法堂', 7600000, 540000, '💀'
  UNION ALL SELECT '千面魔君', '大乘', '内务长老', '千机堂', 5900000, 410000, '🎭'
  UNION ALL SELECT '幽冥子', '大乘', '长老', '幽冥堂', 5200000, 380000, '🌑'
  UNION ALL SELECT '玉面罗刹', '合体', '堂主', '血煞堂', 3600000, 260000, '🌺'
  UNION ALL SELECT '赤炎老祖', '合体', '丹殿长老', '炼丹堂', 3300000, 245000, '🔥'
  UNION ALL SELECT '噬魂叟', '炼虚', '长老', '幽冥堂', 2100000, 180000, '👁️'
  UNION ALL SELECT '墨鸦', '炼虚', '首席弟子', '执法堂', 1800000, 160000, '🐦'
  UNION ALL SELECT '苏九黎', '化神', '内门弟子', '千机堂', 900000, 95000, '🦋'
  UNION ALL SELECT '谢无咎', '化神', '外门弟子', '血煞堂', 850000, 88000, '⚔️'
  UNION ALL SELECT '阿蛮', '金丹', '记名弟子', '炼丹堂', 260000, 30000, '🍖'
) AS t
WHERE NOT EXISTS (SELECT 1 FROM `sect_member` x WHERE x.name = t.name);

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
