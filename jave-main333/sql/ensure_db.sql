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

-- ============================================================
-- 8. 宗门榜 + 论道模块（幂等建表 + 魔宗风格种子）
--    与 sql/seed_sect.sql 内容一致，保证 start.bat 一键自愈
-- ============================================================

CREATE TABLE IF NOT EXISTS `sect_member` (
  `id`           BIGINT       NOT NULL AUTO_INCREMENT COMMENT '主键',
  `name`         VARCHAR(50)  NOT NULL                COMMENT '道号',
  `realm`        VARCHAR(20)  NOT NULL                COMMENT '境界',
  `title`        VARCHAR(50)  NULL                    COMMENT '称号/职位',
  `hall`         VARCHAR(30)  NULL                    COMMENT '所属堂口',
  `power`        BIGINT       NOT NULL DEFAULT 0      COMMENT '战力',
  `contribution` BIGINT       NOT NULL DEFAULT 0      COMMENT '宗门贡献',
  `icon`         VARCHAR(16)  NULL                    COMMENT '头像 emoji',
  `create_time`  DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '入门时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_member_name` (`name`)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_general_ci COMMENT = '宗门榜·弟子名录';

CREATE TABLE IF NOT EXISTS `forum_post` (
  `id`          BIGINT        NOT NULL AUTO_INCREMENT COMMENT '主键',
  `author`      VARCHAR(50)   NOT NULL                COMMENT '发帖人',
  `title`       VARCHAR(100)  NOT NULL                COMMENT '帖名',
  `content`     VARCHAR(2000) NOT NULL                COMMENT '正文',
  `views`       BIGINT        NOT NULL DEFAULT 0      COMMENT '围观量',
  `likes`       BIGINT        NOT NULL DEFAULT 0      COMMENT '道心相印（点赞）',
  `status`      TINYINT       NOT NULL DEFAULT 1      COMMENT '状态：1 显示 / 0 屏蔽',
  `create_time` DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '发帖时间',
  PRIMARY KEY (`id`),
  KEY `idx_post_time` (`create_time`)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_general_ci COMMENT = '论道帖';

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
-- ============================================================
-- 9. 任务阁模块（幂等建表 + 魔宗风格种子任务）
--    两大悬赏来源：
--      · quest_type = 'sect'     宗门颁发，奖励贡献值 / 灵石（可兼得）
--      · quest_type = 'personal' 个人发布，奖励天才地宝 / 法宝等（reward_item 描述）
--    接取门槛：min_realm 修为限制（炼气~魔尊）+ max_accept 人数限制
--    注：本节曾改版（v2 增加类型/奖励/门槛字段），旧库需先 DROP 重建
-- ============================================================

CREATE TABLE IF NOT EXISTS `quest` (
  `id`           BIGINT       NOT NULL AUTO_INCREMENT COMMENT '主键',
  `quest_type`   VARCHAR(10)  NOT NULL DEFAULT 'sect' COMMENT '类型：sect 宗门悬赏 / personal 个人悬赏',
  `publisher`    VARCHAR(50)  NULL                    COMMENT '发布人（宗门悬赏为 NULL，个人悬赏为用户名）',
  `title`        VARCHAR(100) NOT NULL                COMMENT '任务名',
  `description`  VARCHAR(500) NULL                    COMMENT '任务详情',
  `category`     VARCHAR(20)  NOT NULL                COMMENT '分类：斩妖/夺宝/护送/炼丹/寻物/戒律/其它',
  `difficulty`   VARCHAR(10)  NOT NULL                COMMENT '难度：简单/普通/困难/地狱',
  `min_realm`    VARCHAR(10)  NOT NULL DEFAULT '炼气' COMMENT '修为门槛：炼气~魔尊，低于该境界不可接取',
  `max_accept`   INT          NOT NULL DEFAULT 1      COMMENT '接取名额（完成/进行中占用名额，放弃后释放）',
  `reward_contribution` BIGINT NOT NULL DEFAULT 0     COMMENT '贡献值奖励（宗门悬赏）',
  `reward_stones` BIGINT      NOT NULL DEFAULT 0      COMMENT '灵石奖励（宗门悬赏，可与贡献值兼得）',
  `reward_item`  VARCHAR(100) NULL                    COMMENT '物品奖励（个人悬赏：天才地宝/法宝等）',
  `icon`         VARCHAR(16)  NULL                    COMMENT '图标（emoji）',
  `status`       TINYINT      NOT NULL DEFAULT 1      COMMENT '状态：1 上架 / 0 下架',
  `accept_count` BIGINT       NOT NULL DEFAULT 0      COMMENT '累计接取次数（热度展示）',
  `create_time`  DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '发布时间',
  PRIMARY KEY (`id`),
  KEY `idx_quest_type` (`quest_type`),
  KEY `idx_quest_category` (`category`),
  KEY `idx_quest_status` (`status`)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_general_ci COMMENT = '任务阁·任务牌';

CREATE TABLE IF NOT EXISTS `user_quest` (
  `id`          BIGINT      NOT NULL AUTO_INCREMENT COMMENT '主键',
  `username`    VARCHAR(50) NOT NULL                COMMENT '接取人（关联 user.username）',
  `quest_id`    BIGINT      NOT NULL                COMMENT '任务 id（关联 quest.id）',
  `status`      TINYINT     NOT NULL DEFAULT 0      COMMENT '状态：0 进行中 / 1 已完成 / 2 已放弃',
  `reward_contribution` BIGINT NOT NULL DEFAULT 0   COMMENT '完成时所得贡献值快照',
  `reward_stones` BIGINT    NOT NULL DEFAULT 0      COMMENT '完成时所得灵石快照',
  `reward_item` VARCHAR(100) NULL                    COMMENT '完成时所得物品快照（个人悬赏）',
  `create_time` DATETIME    NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '接取时间',
  `finish_time` DATETIME    NULL                    COMMENT '完成 / 放弃时间',
  PRIMARY KEY (`id`),
  KEY `idx_uq_user` (`username`),
  KEY `idx_uq_quest` (`quest_id`)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_general_ci COMMENT = '任务阁·弟子接取记录';

-- ============ 种子任务：宗门悬赏（奖励贡献值 / 灵石） ============
INSERT INTO `quest` (`quest_type`, `publisher`, `title`, `description`, `category`, `difficulty`, `min_realm`, `max_accept`, `reward_contribution`, `reward_stones`, `reward_item`, `icon`, `status`, `accept_count`)
SELECT t.* FROM (
  SELECT 'sect' AS quest_type, NULL AS publisher, '清剿血狼坡狼群' AS title, '血狼坡狼群近来愈发猖獗，劫掠过往行商。斩狼二十，取狼王左耳为凭。' AS description, '斩妖' AS category, '普通' AS difficulty, '筑基' AS min_realm, 10 AS max_accept, 300 AS reward_contribution, 20 AS reward_stones, NULL AS reward_item, '⚔️' AS icon, 1 AS status, 320 AS accept_count
  UNION ALL SELECT 'sect', NULL, '夜探万剑坟场斩剑灵', '坟场剑灵夜半出鞘伤人。入得进去，斩得剑灵三尊，归来者皆道中之人。', '斩妖', '困难', '金丹', 5, 800, 60, NULL, '🗡️', 1, 150
  UNION ALL SELECT 'sect', NULL, '讨伐沉渊魔蛟', '沉渊之底魔蛟苏醒，掀翻渔船七十二。此任务九死一生，性命自负，宗门不收尸。', '斩妖', '地狱', '元婴', 3, 2000, 200, NULL, '🐉', 1, 21
  UNION ALL SELECT 'sect', NULL, '幽冥鬼市购破境丹', '鬼市子时开市，丹价一日三涨。替宗主购得破境丹两枚，真伪自辨，吃亏自负。', '夺宝', '普通', '筑基', 8, 350, 30, NULL, '⚗️', 1, 260
  UNION ALL SELECT 'sect', NULL, '万剑坟场拾遗残剑', '剑冢边缘偶有残剑浮土而出。拾得三柄有灵残剑，上缴藏经阁即可。', '夺宝', '简单', '炼气', 20, 150, 10, NULL, '⚒️', 1, 410
  UNION ALL SELECT 'sect', NULL, '护送丹车队过乱星岭', '炼丹堂三车血参要过乱星岭，岭上散修劫道成风。人货俱全者，赏。', '护送', '普通', '筑基', 6, 400, 25, NULL, '🛡️', 1, 190
  UNION ALL SELECT 'sect', NULL, '护送新弟子入宗', '山下接引八名记名弟子入宗。要求：人不丢，心不歪，路上不许讲鬼故事。', '护送', '简单', '炼气', 20, 100, 5, NULL, '🧭', 1, 520
  UNION ALL SELECT 'sect', NULL, '为炼丹堂采百年血参', '断魂崖阴面生百年血参七株，须寅时采摘，日头一出便枯。', '炼丹', '简单', '炼气', 15, 120, 8, NULL, '🌿', 1, 480
  UNION ALL SELECT 'sect', NULL, '炼制三炉回春丹', '丹房拨药材若干，成丹三炉。炸炉者扣当月例钱，成丹者丹堂记功。', '炼丹', '普通', '筑基', 10, 450, 35, NULL, '🔥', 1, 230
  UNION ALL SELECT 'sect', NULL, '寻找失落的化神诀残页', '化神诀下半卷失踪百年，线索只有一句：剑鸣最弱时，向东南坡去。', '寻物', '困难', '金丹', 4, 700, 80, NULL, '📜', 1, 88
  UNION ALL SELECT 'sect', NULL, '寻回走失的噬魂兽', '执法堂豢养的噬魂兽趁夜出逃，会学人哭。找回者赏，被吓哭者不赏。', '寻物', '普通', '筑基', 10, 300, 20, NULL, '🐺', 1, 210
  UNION ALL SELECT 'sect', NULL, '罚扫藏经阁三月', '自领此任者，须是触犯戒律以功抵过之身。扫帚自备，藏经阁长老验收。', '戒律', '简单', '炼气', 3, 80, 3, NULL, '🧹', 1, 66
) AS t
WHERE NOT EXISTS (SELECT 1 FROM `quest` WHERE `quest_type` = 'sect');

-- ============ 种子任务：个人悬赏（奖励天才地宝 / 法宝等） ============
INSERT INTO `quest` (`quest_type`, `publisher`, `title`, `description`, `category`, `difficulty`, `min_realm`, `max_accept`, `reward_contribution`, `reward_stones`, `reward_item`, `icon`, `status`, `accept_count`)
SELECT t.* FROM (
  SELECT 'personal' AS quest_type, '赤炎老祖' AS publisher, '寻九叶凤凰草' AS title, '炼一炉自用丹缺一味主药。九叶凤凰草，叶背带火纹者为真。找到即刻交割，一手草一手宝。' AS description, '炼丹' AS category, '普通' AS difficulty, '筑基' AS min_realm, 2 AS max_accept, 0 AS reward_contribution, 0 AS reward_stones, '百年血参两株' AS reward_item, '🌿' AS icon, 1 AS status, 95 AS accept_count
  UNION ALL SELECT 'personal', '墨鸦', '取回坠入万蛇窟的佩剑', '执法堂制式魔剑坠崖，剑通灵性，认主不认贼。取得原剑归还者，另有谢礼。', '寻物', '困难', '金丹', 1, 0, 0, '上古剑丸·青蚀', '⚔️', 1, 37
  UNION ALL SELECT 'personal', '苏九黎', '心魔幻阵陪练', '卡在第七层三个月了，需要一位道友陪我进幻阵走一遍。要求：道心稳固，见故人不至于当场泪崩。', '其它', '普通', '筑基', 3, 0, 0, '千机堂秘制安神香十支', '🌫️', 1, 120
  UNION ALL SELECT 'personal', '千面魔君', '辨认真伪魔宗古图', '得一残图，真伪难辨。持图去鬼市需一位懂古篆的道友随行鉴定。真图者，谢礼从优。', '寻物', '困难', '金丹', 1, 0, 0, '魔宗秘藏古图（若为真）', '🗺️', 1, 42
  UNION ALL SELECT 'personal', '玉面罗刹', '血煞堂外哨换防三日', '本堂外哨连值日久，寻三位道友替岗三日。只求尽责，不求勇武。', '护送', '简单', '炼气', 3, 0, 0, '血煞堂护身符一枚', '🛡️', 1, 210
  UNION ALL SELECT 'personal', '阿蛮', '寻会讲故事的道友', '藏经阁扫地太闷。寻一位会讲志怪故事的道友，每日酉时来扫帚堆边说书半个时辰。', '其它', '简单', '炼气', 1, 0, 0, '阿蛮娘亲手做的酱肘子（管够）', '🍖', 1, 66
) AS t
WHERE NOT EXISTS (SELECT 1 FROM `quest` WHERE `quest_type` = 'personal');

SELECT COUNT(*) AS quest_count FROM `quest`;

-- ============================================================
-- 10. 功法阁·贡献值体系（幂等）
--    content_item.required_contribution  参悟所需贡献值（按品阶高深定价，仅功法类）
--    user_skill                          参悟记录（联动洞府：已习功法 / 消耗贡献值）
--    user_secret                         破界记录（秘境进入 / 消耗贡献值）
--    经济闭环：任务阁交差赚贡献值 → 功法阁参悟花贡献值
--    可用贡献值 = 累计所得(user_quest) - 已耗于参悟(user_skill)
-- ============================================================

-- 10.1 content_item 增列（MySQL 8 无 ADD COLUMN IF NOT EXISTS，用条件语句幂等）
SET @col_exists := (
  SELECT COUNT(*) FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'content_item'
    AND COLUMN_NAME = 'required_contribution'
);
SET @ddl := IF(@col_exists = 0,
  'ALTER TABLE `content_item` ADD COLUMN `required_contribution` BIGINT NOT NULL DEFAULT 0 COMMENT ''参悟所需贡献值（仅功法类 > 0）'' AFTER `grade`',
  'SELECT 1');
PREPARE stmt FROM @ddl; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- 10.2 参悟记录表
CREATE TABLE IF NOT EXISTS `user_skill` (
  `id`          BIGINT      NOT NULL AUTO_INCREMENT COMMENT '主键',
  `username`    VARCHAR(50) NOT NULL                COMMENT '参悟人（关联 user.username）',
  `item_id`     BIGINT      NOT NULL                COMMENT '功法条目 id（关联 content_item.id）',
  `cost`        BIGINT      NOT NULL DEFAULT 0      COMMENT '参悟时消耗的贡献值快照',
  `title`       VARCHAR(100) NOT NULL               COMMENT '功法名快照',
  `grade`       VARCHAR(20) NULL                    COMMENT '品阶快照',
  `icon`        VARCHAR(16) NULL                    COMMENT '图标快照',
  `create_time` DATETIME    NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '参悟时间',
  PRIMARY KEY (`id`),
  KEY `idx_us_user` (`username`),
  KEY `idx_us_item` (`item_id`)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_general_ci COMMENT = '功法阁·弟子参悟记录';

-- 10.3 按品阶给「功法」子树的条目定价（强制全量重刷，保证品阶梯度始终生效）
--      品阶越高贡献值越贵：神 8000 / 圣 6000 / 魔 5000 / 天 3000 / 地 1500 /
--      王·皇 1200 / 玄 600 / 黄 200 / 凡·未标注 100
UPDATE `content_item` ci
JOIN `category` c ON c.id = ci.category_id
LEFT JOIN `category` p ON p.id = c.parent_id
SET ci.required_contribution = CASE ci.grade
  WHEN '神阶' THEN 8000
  WHEN '圣阶' THEN 6000
  WHEN '魔阶' THEN 5000
  WHEN '天阶' THEN 3000
  WHEN '地阶' THEN 1500
  WHEN '王阶' THEN 1200
  WHEN '皇阶' THEN 1200
  WHEN '玄阶' THEN 600
  WHEN '黄阶' THEN 200
  WHEN '凡阶' THEN 100
  ELSE 100
END
WHERE (c.name = '功法' OR p.name = '功法');

SELECT COUNT(*) AS priced_skills FROM `content_item` WHERE `required_contribution` > 0;

-- 10.4 秘境进入记录表（幂等）
--    经济闭环：任务阁交差赚贡献值 → 功法阁参悟 / 秘境破界花贡献值
--    可用贡献值 = 累计所得(user_quest) - 已耗于参悟(user_skill) - 已耗于破界(user_secret)
CREATE TABLE IF NOT EXISTS `user_secret` (
  `id`          BIGINT      NOT NULL AUTO_INCREMENT COMMENT '主键',
  `username`    VARCHAR(50) NOT NULL                COMMENT '破界人（关联 user.username）',
  `item_id`     BIGINT      NOT NULL                COMMENT '秘境条目 id（关联 content_item.id）',
  `cost`        BIGINT      NOT NULL DEFAULT 0      COMMENT '进入时消耗的贡献值快照（随机探秘记引路费）',
  `title`       VARCHAR(100) NOT NULL               COMMENT '秘境名快照',
  `grade`       VARCHAR(20) NULL                    COMMENT '品阶快照',
  `icon`        VARCHAR(16) NULL                    COMMENT '图标快照',
  `create_time` DATETIME    NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '进入时间',
  PRIMARY KEY (`id`),
  KEY `idx_usecret_user` (`username`),
  KEY `idx_usecret_item` (`item_id`)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_general_ci COMMENT = '秘境·弟子破界记录';

-- 10.5 按品阶给「秘境」子树的条目定门票价（强制全量重刷，保证品阶梯度始终生效）
--      品阶越高门票越贵，高级秘境绝不免费：神 5000 / 圣 4000 / 魔 3000 /
--      天 2000 / 地 1200 / 王·皇 800 / 玄 400
--      仅黄阶 / 凡阶 / 未标注 = 低端「无主之境」：不设门票（0），人人可进，但收获寒酸
UPDATE `content_item` ci
JOIN `category` c  ON c.id  = ci.category_id
LEFT JOIN `category` p  ON p.id  = c.parent_id
LEFT JOIN `category` p2 ON p2.id = p.parent_id
SET ci.required_contribution = CASE ci.grade
  WHEN '神阶' THEN 5000
  WHEN '圣阶' THEN 4000
  WHEN '魔阶' THEN 3000
  WHEN '天阶' THEN 2000
  WHEN '地阶' THEN 1200
  WHEN '王阶' THEN 800
  WHEN '皇阶' THEN 800
  WHEN '玄阶' THEN 400
  WHEN '黄阶' THEN 0
  WHEN '凡阶' THEN 0
  ELSE 0
END
WHERE (c.name = '秘境' OR p.name = '秘境' OR p2.name = '秘境');

SELECT COUNT(*) AS priced_secrets FROM `content_item`
WHERE `required_contribution` > 0
  AND `category_id` IN (
    SELECT c2.id FROM `category` c2
    LEFT JOIN `category` c3 ON c3.id = c2.parent_id
    LEFT JOIN `category` c4 ON c4.id = c3.parent_id
    WHERE c2.name = '秘境' OR c3.name = '秘境' OR c4.name = '秘境'
  );

-- 10.6 秘境探索奖励表（幂等）
--    奖励不固定：灵石/贡献值（入 forum_income, source=secret）、
--    修为（落 cultivation_log, method_key=secret）、功法（免贡落 user_skill, cost=0）、
--    残篇/法宝/神通/道心通明等奇遇留档本表
CREATE TABLE IF NOT EXISTS `secret_reward` (
  `id`           BIGINT       NOT NULL AUTO_INCREMENT COMMENT '主键',
  `username`     VARCHAR(50)  NOT NULL                COMMENT '得主（关联 user.username）',
  `item_id`      BIGINT       NOT NULL                COMMENT '触发秘境条目 id（关联 content_item.id）',
  `reward_type`  VARCHAR(30)  NOT NULL                COMMENT '类型：stones/contribution/cultivation/technique/fragment/artifact/divine_ability/dao_clarity',
  `reward_name`  VARCHAR(100) NULL                    COMMENT '奖励名称快照',
  `rarity`       VARCHAR(20)  NOT NULL DEFAULT 'common' COMMENT '稀有度：common/rare/epic/legendary',
  `amount`       BIGINT       NOT NULL DEFAULT 0      COMMENT '数值奖励量（灵石/贡献值/修为），奇遇类为 0',
  `detail`       VARCHAR(500) NULL                    COMMENT '奖励描述（奇遇文案）',
  `create_time`  DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '入账时间',
  PRIMARY KEY (`id`),
  KEY `idx_sreward_user` (`username`),
  KEY `idx_sreward_item` (`item_id`)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_general_ci COMMENT = '秘境·探索奖励记录';

-- ============================================================
-- 11. 魔功殿·修为体系（幂等）
--     user_profile.cultivation  修为值（魔功殿修炼累计，跨过门槛自动晋升境界）
--     cultivation_log           修炼记录（每次吞吐魔气的流水，兼作冷却判定）
--     经济闭环：任务阁赚灵石/贡献 → 魔功殿花灵石/贡献换修为
--     五法门：mogu 魔窟苦修 / xuedan 吞噬血丹 / xueji 血祭秘法 /
--             duoshe 夺舍夺元 / tuntian 吞天魔功
-- ============================================================

-- 11.1 user_profile 增列（MySQL 8 无 ADD COLUMN IF NOT EXISTS，用条件语句幂等）
SET @col_exists := (
  SELECT COUNT(*) FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'user_profile'
    AND COLUMN_NAME = 'cultivation'
);
SET @ddl := IF(@col_exists = 0,
  'ALTER TABLE `user_profile` ADD COLUMN `cultivation` BIGINT NOT NULL DEFAULT 0 COMMENT ''修为值（魔功殿修炼累计）'' AFTER `realm`',
  'SELECT 1');
PREPARE stmt FROM @ddl; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- 11.2 修炼记录表
CREATE TABLE IF NOT EXISTS `cultivation_log` (
  `id`          BIGINT       NOT NULL AUTO_INCREMENT COMMENT '主键',
  `username`    VARCHAR(50)  NOT NULL                COMMENT '修炼人（关联 user.username）',
  `method_key`  VARCHAR(20)  NOT NULL                COMMENT '法门标识：mogu/xuedan/xueji/duoshe/tuntian',
  `method_name` VARCHAR(30)  NOT NULL                COMMENT '法门名快照',
  `outcome`     VARCHAR(10)  NOT NULL                COMMENT '结果：great 大成 / good 小成 / backlash 反噬',
  `delta`       BIGINT       NOT NULL DEFAULT 0      COMMENT '本次修为增减（负数为反噬）',
  `cost_stones`       BIGINT NOT NULL DEFAULT 0      COMMENT '消耗灵石',
  `cost_contribution` BIGINT NOT NULL DEFAULT 0      COMMENT '消耗贡献值',
  `story`       VARCHAR(500) NULL                    COMMENT '修炼异象文案',
  `create_time` DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '修炼时间',
  PRIMARY KEY (`id`),
  KEY `idx_cl_user` (`username`),
  KEY `idx_cl_method` (`username`, `method_key`)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_general_ci COMMENT = '魔功殿·修炼记录';

SELECT COUNT(*) AS cultivation_log_ready FROM `cultivation_log`;

-- ============================================================
-- 12. 血辩台（原论道魔宗化）：论道即修炼
--     forum_post 加被驳计数；forum_like 动作防重；forum_income 帖主分成账本
-- ============================================================

-- 12.1 forum_post 增列
SET @col_exists := (
  SELECT COUNT(*) FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'forum_post'
    AND COLUMN_NAME = 'counters'
);
SET @ddl := IF(@col_exists = 0,
  'ALTER TABLE `forum_post` ADD COLUMN `counters` BIGINT NOT NULL DEFAULT 0 COMMENT ''被驳次数（血辩台驳道）'' AFTER `likes`',
  'SELECT 1');
PREPARE stmt FROM @ddl; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- 12.2 动作记录表（香火供奉 / 驳道，UNIQUE 防一人重复）
CREATE TABLE IF NOT EXISTS `forum_like` (
  `id`          BIGINT      NOT NULL AUTO_INCREMENT COMMENT '主键',
  `post_id`     BIGINT      NOT NULL                COMMENT '帖子 id（forum_post.id）',
  `username`    VARCHAR(50) NOT NULL                COMMENT '动作发起人',
  `action`      VARCHAR(16) NOT NULL                COMMENT '动作：incense 香火供奉 / counter 驳道',
  `create_time` DATETIME    NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '动作时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_fl_post_user_action` (`post_id`, `username`, `action`),
  KEY `idx_fl_user` (`username`)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_general_ci COMMENT = '血辩台·动作记录';

-- 12.3 帖主分成账本（香火供奉 → 帖主 +贡献值）
CREATE TABLE IF NOT EXISTS `forum_income` (
  `id`          BIGINT      NOT NULL AUTO_INCREMENT COMMENT '主键',
  `username`    VARCHAR(50) NOT NULL                COMMENT '收益人',
  `stones`      BIGINT      NOT NULL DEFAULT 0      COMMENT '灵石收益',
  `contribution` BIGINT     NOT NULL DEFAULT 0      COMMENT '贡献值收益',
  `source`      VARCHAR(20) NOT NULL                COMMENT '来源：incense 香火分成',
  `create_time` DATETIME    NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '入账时间',
  PRIMARY KEY (`id`),
  KEY `idx_fi_user` (`username`)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_general_ci COMMENT = '血辩台·帖主分成账本';

SELECT COUNT(*) AS forum_like_ready FROM `forum_like`;
SELECT COUNT(*) AS forum_income_ready FROM `forum_income`;
