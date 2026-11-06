-- ============================================================
--  home_db.sql —— 首页模块完整建表 + 演示数据（幂等，可反复执行）
--  库：login_db（与登录模块共用，若不存在则先创建）
--  表：
--    category      分级分类（parent_id 自引用，任意层级）
--    content_item  内容条目（首页展示 + 搜索的数据主体）
--    search_log    搜索词日志（热搜词榜 / 搜索统计用，可选）
--  特点：
--    * 全部 CREATE TABLE IF NOT EXISTS，不 DROP、不清库
--    * 演示数据按唯一键判重插入，重复执行不会产生脏数据
--    * 可单独执行：mysql -uroot -p123456 < sql/home_db.sql
-- ============================================================

CREATE DATABASE IF NOT EXISTS `login_db`
  DEFAULT CHARACTER SET utf8mb4
  DEFAULT COLLATE utf8mb4_general_ci;

USE `login_db`;

-- ------------------------------------------------------------
-- 1. 分级分类表
--    parent_id = 0 表示顶级；level 保存冗余层级，便于按层查询
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `category` (
  `id`          BIGINT       NOT NULL AUTO_INCREMENT COMMENT '主键，自增',
  `name`        VARCHAR(50)  NOT NULL                COMMENT '分类名称',
  `parent_id`   BIGINT       NOT NULL DEFAULT 0      COMMENT '父分类 id，0 表示顶级',
  `level`       INT          NOT NULL DEFAULT 1      COMMENT '层级：1 顶级 / 2 二级 / 3 三级...',
  `sort`        INT          NOT NULL DEFAULT 0      COMMENT '排序值，越小越靠前',
  `icon`        VARCHAR(16)  NULL                    COMMENT '图标（emoji）',
  `description` VARCHAR(200) NULL                    COMMENT '分类描述',
  `create_time` DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`),
  KEY `idx_parent` (`parent_id`),
  KEY `idx_level_sort` (`level`, `sort`)
) ENGINE = InnoDB
  DEFAULT CHARSET = utf8mb4
  COLLATE = utf8mb4_general_ci
  COMMENT = '首页分级分类表';

-- ------------------------------------------------------------
-- 2. 内容条目表（首页展示 + 搜索主体）
--    view_count 用于热门榜排序，搜索命中一次 +1
--    fulltext 索引：MySQL 8 InnoDB 原生支持，中文需配合 ngram，
--    这里以 LIKE 为主（数据量小、中文分词更可控），FULLTEXT 备用
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `content_item` (
  `id`          BIGINT       NOT NULL AUTO_INCREMENT COMMENT '主键，自增',
  `title`       VARCHAR(100) NOT NULL                COMMENT '标题',
  `description` VARCHAR(500) NULL                    COMMENT '简介',
  `category_id` BIGINT       NOT NULL                COMMENT '所属分类 id（可为任意层级分类）',
  `grade`       VARCHAR(20)  NULL                    COMMENT '品阶（天阶/地阶/玄阶/黄阶等）',
  `icon`        VARCHAR(16)  NULL                    COMMENT '图标（emoji，展示用）',
  `view_count`  BIGINT       NOT NULL DEFAULT 0      COMMENT '浏览量（热门榜排序依据）',
  `status`      TINYINT      NOT NULL DEFAULT 1      COMMENT '状态：1 上架 / 0 下架',
  `create_time` DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`),
  KEY `idx_category` (`category_id`),
  KEY `idx_title` (`title`),
  KEY `idx_status_view` (`status`, `view_count`)
) ENGINE = InnoDB
  DEFAULT CHARSET = utf8mb4
  COLLATE = utf8mb4_general_ci
  COMMENT = '首页内容条目表';

-- ------------------------------------------------------------
-- 3. 搜索日志表（记录每次搜索，用于热搜词 / 无结果词分析）
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `search_log` (
  `id`           BIGINT       NOT NULL AUTO_INCREMENT COMMENT '主键，自增',
  `keyword`      VARCHAR(100) NOT NULL                COMMENT '搜索关键词',
  `category_id`  BIGINT       NULL                    COMMENT '分类过滤条件（可空）',
  `result_count` INT          NOT NULL DEFAULT 0      COMMENT '本次结果条数',
  `username`     VARCHAR(50)  NULL                    COMMENT '发起搜索的用户（可空）',
  `create_time`  DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '搜索时间',
  PRIMARY KEY (`id`),
  KEY `idx_keyword` (`keyword`),
  KEY `idx_create_time` (`create_time`)
) ENGINE = InnoDB
  DEFAULT CHARSET = utf8mb4
  COLLATE = utf8mb4_general_ci
  COMMENT = '首页搜索日志表';

-- ============================================================
-- 4. 演示数据 —— 分级分类
--    顶级 6 类：功法 / 秘境 / 丹药 / 法宝 / 灵兽 / 典籍（典籍为单层）
--    二级 10 类挂在对应顶级下
--    判重键：顶级靠 (name, parent_id=0)；二级靠 (name, parent_id)
-- ============================================================

-- 4.1 顶级分类
INSERT INTO `category` (`name`, `parent_id`, `level`, `sort`, `icon`, `description`)
SELECT t.name, 0, 1, t.sort, t.icon, t.description
FROM (
            SELECT '功法' AS name, 1 AS sort, '📜' AS icon, '诸天功法，皆可习练' AS description
  UNION ALL SELECT '秘境', 2, '🗺️', '无尽秘境，待你开辟'
  UNION ALL SELECT '丹药', 3, '⚗️', '逆天改命之丹'
  UNION ALL SELECT '法宝', 4, '🗡️', '神兵利器，掌中乾坤'
  UNION ALL SELECT '灵兽', 5, '🐉', '万兽臣服，皆入麾下'
  UNION ALL SELECT '典籍', 6, '📖', '万载传承，尽数收录'
) AS t
WHERE NOT EXISTS (
  SELECT 1 FROM `category` x WHERE x.name = t.name AND x.parent_id = 0
);

-- 4.2 二级分类（依赖上面的顶级分类）
INSERT INTO `category` (`name`, `parent_id`, `level`, `sort`, `icon`, `description`)
SELECT t.name, c1.id, 2, t.sort, t.icon, t.description
FROM (
            SELECT '炼体功法' AS name, 1 AS sort, '💪' AS icon, '淬体炼骨，根基之道' AS description, '功法' AS parent_name
  UNION ALL SELECT '心法口诀', 2, '🧘', '凝聚灵力，运转周天', '功法'
  UNION ALL SELECT '上古秘境', 1, '🗿', '洪荒遗地，机缘无数', '秘境'
  UNION ALL SELECT '幻境试炼', 2, '🌫️', '心魔考验，突破之地', '秘境'
  UNION ALL SELECT '回春丹',   1, '🌿', '疗伤圣药', '丹药'
  UNION ALL SELECT '破境丹',   2, '⚡', '助修士破除瓶颈', '丹药'
  UNION ALL SELECT '攻击法宝', 1, '⚔️', '斩敌破阵', '法宝'
  UNION ALL SELECT '防御法宝', 2, '🛡️', '护体保命', '法宝'
  UNION ALL SELECT '飞行灵兽', 1, '🦅', '翱翔九天', '灵兽'
  UNION ALL SELECT '守护灵兽', 2, '🐺', '忠心护主', '灵兽'
) AS t
JOIN `category` c1 ON c1.name = t.parent_name AND c1.parent_id = 0
WHERE NOT EXISTS (
  SELECT 1 FROM `category` x WHERE x.name = t.name AND x.parent_id = c1.id
);

-- ============================================================
-- 5. 演示数据 —— 内容条目（古风修仙风格，按 title 判重）
--    每类 12 条左右，合计 132 条
-- ============================================================

-- 5.1 炼体功法
INSERT INTO `content_item` (`title`, `description`, `category_id`, `grade`, `icon`, `view_count`)
SELECT t.title, t.description, c.id, t.grade, t.icon, t.view_count
FROM (
            SELECT '金刚不坏身' AS title, '以周身三百六十骨节为炉，日夜锤打，皮肉如金石，刀斧难伤分毫。' AS description, '天阶' AS grade, '🗿' AS icon, 9120 AS view_count, '炼体功法' AS cat
  UNION ALL SELECT '血煞炼骨术', '引凶兽精血入骨，骨中生煞，一击可碎山门。然煞气反噬，心如擂鼓。', '地阶', '🩸', 7840, '炼体功法'
  UNION ALL SELECT '春雷淬身诀', '每岁惊蛰引天雷淬体，痛极则生，九淬之后血肉自生雷纹。', '玄阶', '⚡', 6210, '炼体功法'
  UNION ALL SELECT '不周山印', '以身作山，重逾万钧，气机一动便压塌一方天地。', '天阶', '⛰️', 8760, '炼体功法'
  UNION ALL SELECT '玄龟息法', '吞吐迟缓如龟，可闭气三月不死，肉身生鳞，万毒不侵。', '黄阶', '🐢', 4320, '炼体功法'
  UNION ALL SELECT '焚身决', '以真火自焚其身，焚去凡胎浊骨，浴火一遭，胜修十年苦功。', '玄阶', '🔥', 5680, '炼体功法'
  UNION ALL SELECT '冰魄寒体', '久居极北寒渊，以身饲冰，血凝成霜，举手投足皆是万里冰封。', '地阶', '❄️', 7010, '炼体功法'
  UNION ALL SELECT '万木回春体', '借草木生机淬体，断肢可续，重伤自愈，唯惧烈火焚林。', '黄阶', '🌿', 3890, '炼体功法'
  UNION ALL SELECT '修罗战体', '以杀养体，每斩一敌肉躯便厚重一分，杀满千敌可徒手撕蛟。', '天阶', '🗡️', 9450, '炼体功法'
  UNION ALL SELECT '紫府真形', '观想紫府神宫，将肉身炼作道场，内蕴一方小世界，坚不可摧。', '地阶', '🔮', 7260, '炼体功法'
  UNION ALL SELECT '龙象大力诀', '每日子时扛石磨骨，积九牛二虎之力于双臂，力可撼岳。', '玄阶', '🐘', 5480, '炼体功法'
  UNION ALL SELECT '枯荣禅体', '一念枯、一念荣，枯时如朽木可受万击，荣时生机暴涨还以重拳。', '地阶', '🍂', 6730, '炼体功法'
) AS t
JOIN `category` c ON c.name = t.cat AND c.level = 2
WHERE NOT EXISTS (SELECT 1 FROM `content_item` x WHERE x.title = t.title);

-- 5.2 心法口诀
INSERT INTO `content_item` (`title`, `description`, `category_id`, `grade`, `icon`, `view_count`)
SELECT t.title, t.description, c.id, t.grade, t.icon, t.view_count
FROM (
            SELECT '太虚周天诀' AS title, '一念引气走周天，三百六十窍窍窍皆通，吐纳之间自成天地。' AS description, '天阶' AS grade, '🌀' AS icon, 9340 AS view_count, '心法口诀' AS cat
  UNION ALL SELECT '清心明性经', '魔宗弟子入门第一课，斩杂念、定道心，心魔不生则万法可修。', '黄阶', '🪷', 4120, '心法口诀'
  UNION ALL SELECT '紫气东来诀', '寅时面东而坐，纳第一缕紫气入丹田，修至圆满则气血如朝霞。', '地阶', '🌅', 7680, '心法口诀'
  UNION ALL SELECT '九幽噬灵法', '以神魂为钩，吞噬残魂补己身，神识远胜同阶，然夜夜闻哭声。', '天阶', '👁️', 8890, '心法口诀'
  UNION ALL SELECT '无相真空咒', '心中无一物，万法皆是空。敌之神通落于身上，如投石入水。', '玄阶', '🕳️', 5970, '心法口诀'
  UNION ALL SELECT '两仪归元诀', '阴阳二气交抱轮转，攻守一体，动若奔雷，静若古井。', '地阶', '☯️', 7420, '心法口诀'
  UNION ALL SELECT '燃灯续命篇', '以自身寿元为薪，点燃一盏心灯，灯不灭则命不绝。', '玄阶', '🕯️', 5630, '心法口诀'
  UNION ALL SELECT '万象归心图', '观想三千世界尽入方寸，神识铺开可察方圆百里草木之动。', '玄阶', '🌌', 6080, '心法口诀'
  UNION ALL SELECT '北冥蓄灵诀', '气海如北冥之渊，蓄灵十倍于常修，久战不竭。', '地阶', '🌊', 7150, '心法口诀'
  UNION ALL SELECT '一念千年诀', '识海自成一界，外界一瞬，识海已参悟千载，闭关破境之神物。', '天阶', '⏳', 9010, '心法口诀'
  UNION ALL SELECT '寒潭静照法', '心如寒潭映月，照见己身诸般妄念，妄念一散，灵台自清。', '玄阶', '🌙', 5340, '心法口诀'
  UNION ALL SELECT '劫火焚心经', '每夜观想劫火焚心，焚去怯懦，此后临阵不惧、赴死不退。', '地阶', '🔥', 6890, '心法口诀'
) AS t
JOIN `category` c ON c.name = t.cat AND c.level = 2
WHERE NOT EXISTS (SELECT 1 FROM `content_item` x WHERE x.title = t.title);

-- 5.3 上古秘境
INSERT INTO `content_item` (`title`, `description`, `category_id`, `grade`, `icon`, `view_count`)
SELECT t.title, t.description, c.id, t.grade, t.icon, t.view_count
FROM (
            SELECT '不周山墟' AS title, '天柱折处，残峰悬空，山腹藏有上古神魔断骨，机缘与杀机并存。' AS description, '天阶' AS grade, '⛰️' AS icon, 9560 AS view_count, '上古秘境' AS cat
  UNION ALL SELECT '归墟海眼', '万水归流之尽头，海水倒灌天穹，深处可闻先民钟鸣。', '天阶', '🌊', 9280, '上古秘境'
  UNION ALL SELECT '枯骨荒原', '白骨堆积成丘，风过如万人低语，昼夜颠倒，尸傀游荡。', '玄阶', '🦴', 6340, '上古秘境'
  UNION ALL SELECT '昆仑遗宫', '雪线之上的白玉宫阙，门前立无面石像，擅入者皆成石俑。', '地阶', '🏯', 8120, '上古秘境'
  UNION ALL SELECT '落星谷', '千年前天外陨星坠此，谷中石皆有星纹，触之可窥一线天机。', '玄阶', '☄️', 5820, '上古秘境'
  UNION ALL SELECT '幽冥鬼市', '子时方现的街市，鬼商贩卖活人不敢要的东西，只收寿元。', '地阶', '🏮', 7630, '上古秘境'
  UNION ALL SELECT '万剑坟场', '上古剑修尽殁于此，残剑插地如林，剑气未散，日夜铮鸣。', '天阶', '⚔️', 9740, '上古秘境'
  UNION ALL SELECT '沉舟海窟', '千艘古船沉于海底，船中货物保存如新，唯无人敢取。', '玄阶', '🚢', 5980, '上古秘境'
  UNION ALL SELECT '雷泽古林', '古木参天皆被雷火焚成焦炭，每逢雨夜雷声复起。', '地阶', '🌩️', 7180, '上古秘境'
  UNION ALL SELECT '血月荒祠', '每三十年血月临空，祠堂自开，祭品便是闯入者。', '天阶', '🌕', 8920, '上古秘境'
  UNION ALL SELECT '镜湖倒影界', '湖面映出的世界，与真实世界镜像颠倒，入者易迷失归途。', '玄阶', '🪞', 6150, '上古秘境'
  UNION ALL SELECT '天梯石阶', '九万九千级石阶通往云端，每一级都记着一位陨落者的名字。', '地阶', '🪜', 7840, '上古秘境'
) AS t
JOIN `category` c ON c.name = t.cat AND c.level = 2
WHERE NOT EXISTS (SELECT 1 FROM `content_item` x WHERE x.title = t.title);

-- 5.4 幻境试炼
INSERT INTO `content_item` (`title`, `description`, `category_id`, `grade`, `icon`, `view_count`)
SELECT t.title, t.description, c.id, t.grade, t.icon, t.view_count
FROM (
            SELECT '心魔幻阵' AS title, '闯过者道心通明，闯不过者道基尽毁，阵中映出的全是自己最怕的模样。' AS description, '玄阶' AS grade, '🌫️' AS icon, 8210 AS view_count, '幻境试炼' AS cat
  UNION ALL SELECT '九重问心阶', '一阶一问，九问九答，答不出的问题会化作利刃割开记忆。', '地阶', '🪜', 7560, '幻境试炼'
  UNION ALL SELECT '镜中己身', '与另一个自己交手，他知晓你所有招式的破绽——因为他就是你。', '天阶', '🪞', 9030, '幻境试炼'
  UNION ALL SELECT '黄粱一梦阵', '入阵即过完一生，醒来不过半炷香，然九成人不愿醒。', '地阶', '💭', 7840, '幻境试炼'
  UNION ALL SELECT '七情困锁', '喜、怒、忧、思、悲、恐、惊各成一关，破一关割一情。', '玄阶', '🎭', 6420, '幻境试炼'
  UNION ALL SELECT '无相试心台', '台上无物，唯有一面空镜，照出的不是你，而是你想要成为的人。', '天阶', '🔮', 8760, '幻境试炼'
  UNION ALL SELECT '血池炼魂场', '魂魄入血池反复煎熬，熬得住则神识凝如实质。', '地阶', '🩸', 7310, '幻境试炼'
  UNION ALL SELECT '百鬼夜行图', '画中百鬼齐出，需在画中活过一夜，鸡鸣方能脱身。', '玄阶', '👻', 5980, '幻境试炼'
  UNION ALL SELECT '枯井回声境', '向井中呼喊，回应你的声音会说出你此生最不堪的往事。', '黄阶', '🕳️', 4270, '幻境试炼'
  UNION ALL SELECT '轮回九世劫', '九世轮回，世世横死，第九世若仍执剑，方见真我。', '天阶', '⏳', 9180, '幻境试炼'
  UNION ALL SELECT '寒冰绝念关', '心跳一停，幻境自破；心若不静，先冻住的是自己。', '玄阶', '❄️', 6150, '幻境试炼'
  UNION ALL SELECT '万念俱灰台', '所有念想被抽走的一瞬，便是破境之机，亦是道消之始。', '地阶', '🌑', 7420, '幻境试炼'
) AS t
JOIN `category` c ON c.name = t.cat AND c.level = 2
WHERE NOT EXISTS (SELECT 1 FROM `content_item` x WHERE x.title = t.title);

-- 5.5 回春丹
INSERT INTO `content_item` (`title`, `description`, `category_id`, `grade`, `icon`, `view_count`)
SELECT t.title, t.description, c.id, t.grade, t.icon, t.view_count
FROM (
            SELECT '九转还魂丹' AS title, '传说可令陨落修士重生的禁忌丹药，丹成之时天必降雷。' AS description, '天阶' AS grade, '🌿' AS icon, 9610 AS view_count, '回春丹' AS cat
  UNION ALL SELECT '大回春丹', '断肢可续、五脏可补，疗伤圣药，一枚值一座小宗门。', '地阶', '💊', 8320, '回春丹'
  UNION ALL SELECT '小还丹', '散修囊中常备之物，止血生肌，服之立见效。', '黄阶', '🟡', 4890, '回春丹'
  UNION ALL SELECT '复脉养元丹', '重伤垂危者服之，脉象先稳，元气后补，为疗伤争取三日。', '玄阶', '🫀', 6740, '回春丹'
  UNION ALL SELECT '碧灵清心丸', '解百毒、清心火，走火入魔初起服之，可将魔念压回识海。', '地阶', '🟢', 7480, '回春丹'
  UNION ALL SELECT '续命金丹', '以百年寿元为丹引，为将死之人续命一年，一年之内不可再服。', '天阶', '⚜️', 8940, '回春丹'
  UNION ALL SELECT '洗髓还元丹', '洗去体内丹毒与旧伤根，服后如获新生，然过程痛不欲生。', '地阶', '🫧', 7820, '回春丹'
  UNION ALL SELECT '止血散', '最寻常的疗伤之药，碾碎敷于伤口，血即止住。', '黄阶', '🧂', 4120, '回春丹'
  UNION ALL SELECT '固本培元丹', '体虚气弱者服之，如以温汤灌田，三日之内气力自复。', '玄阶', '🌾', 5960, '回春丹'
  UNION ALL SELECT '回天造化丹', '只要一息尚存，便可从鬼门关拉回半条命，炼成者寥寥。', '天阶', '✨', 9180, '回春丹'
  UNION ALL SELECT '养血生肌丹', '失血过多者之福音，服后三日便可再战。', '玄阶', '🩸', 6210, '回春丹'
  UNION ALL SELECT '百草敷元膏', '非丹而是膏，涂于伤处，草木生机自皮肤渗入经脉。', '黄阶', '🌱', 3870, '回春丹'
) AS t
JOIN `category` c ON c.name = t.cat AND c.level = 2
WHERE NOT EXISTS (SELECT 1 FROM `content_item` x WHERE x.title = t.title);

-- 5.6 破境丹
INSERT INTO `content_item` (`title`, `description`, `category_id`, `grade`, `icon`, `view_count`)
SELECT t.title, t.description, c.id, t.grade, t.icon, t.view_count
FROM (
            SELECT '破境丹' AS title, '卡境界者的福音，一枚可搏一次突破契机，成与不成皆看道心。' AS description, '地阶' AS grade, '⚡' AS icon, 8820 AS view_count, '破境丹' AS cat
  UNION ALL SELECT '冲虚丹', '助筑基后期冲破虚境，服后三日经脉如鼓胀，慎用。', '玄阶', '🌀', 7140, '破境丹'
  UNION ALL SELECT '化神引', '引动神魂蜕变之丹，服之者十有其三神魂崩散，余者化神。', '天阶', '👁️', 9260, '破境丹'
  UNION ALL SELECT '凝金丹', '将散乱灵力凝为一颗金丹，金丹既成，寿元再增三百。', '地阶', '🟡', 8140, '破境丹'
  UNION ALL SELECT '凿壁丹', '如凿壁透光，专为瓶颈如铁壁者所炼，一凿即通。', '玄阶', '🔨', 6320, '破境丹'
  UNION ALL SELECT '洗尘丹', '洗去修行途中积下的杂浊之气，为下一次破境清场。', '黄阶', '💧', 4380, '破境丹'
  UNION ALL SELECT '九窍通明丹', '服后九窍俱开，灵气往来无碍，破境成功率增三成。', '地阶', '🕳️', 7680, '破境丹'
  UNION ALL SELECT '渡劫护心丹', '天劫临头前服下，可护住心脉不被劫雷震碎。', '天阶', '🌩️', 8940, '破境丹'
  UNION ALL SELECT '破妄丹', '破除心中妄念与自我设限，副作用是三日之内口吐真言。', '玄阶', '🪞', 5870, '破境丹'
  UNION ALL SELECT '固境丹', '境界初成时服之，可将新生境界夯实，免跌落之虞。', '地阶', '🏔️', 7210, '破境丹'
  UNION ALL SELECT '引灵丹', '以丹力牵引外灵入体，为筑基之人铺第一级台阶。', '黄阶', '🌬️', 4050, '破境丹'
  UNION ALL SELECT '魂契丹', '以自身一缕神魂为契，换取一次强行冲关的机会。', '天阶', '🔗', 8760, '破境丹'
) AS t
JOIN `category` c ON c.name = t.cat AND c.level = 2
WHERE NOT EXISTS (SELECT 1 FROM `content_item` x WHERE x.title = t.title);

-- 5.7 攻击法宝
INSERT INTO `content_item` (`title`, `description`, `category_id`, `grade`, `icon`, `view_count`)
SELECT t.title, t.description, c.id, t.grade, t.icon, t.view_count
FROM (
            SELECT '诛仙魔剑' AS title, '饮血万千的魔道至宝，出鞘必见血，剑身常凝一层暗红。' AS description, '天阶' AS grade, '⚔️' AS icon, 9998 AS view_count, '攻击法宝' AS cat
  UNION ALL SELECT '斩月弯刀', '刀光如新月一线，斩出时无声无息，敌人往往先倒后闻声。', '地阶', '🌙', 8360, '攻击法宝'
  UNION ALL SELECT '九幽噬魂幡', '幡动则百鬼出，吞噬敌之神魂，为魔宗镇派重器。', '天阶', '🏴', 9120, '攻击法宝'
  UNION ALL SELECT '裂山锤', '一锤落下山崩地裂，重而不失准，力修最爱。', '玄阶', '🔨', 6240, '攻击法宝'
  UNION ALL SELECT '血饮枪', '枪尖饮血则愈利，一场大战之后枪身赤红如烙铁。', '地阶', '🔱', 7530, '攻击法宝'
  UNION ALL SELECT '青莲剑', '剑身刻莲纹，出剑气成莲华，清正而不容邪祟。', '天阶', '🪷', 8740, '攻击法宝'
  UNION ALL SELECT '夺魂钉', '七枚一套，钉入则锁魂，离体则魂散，防不胜防。', '玄阶', '📌', 6080, '攻击法宝'
  UNION ALL SELECT '落雷锥', '掷出引天雷附于锥身，专破护身结界。', '地阶', '⚡', 7280, '攻击法宝'
  UNION ALL SELECT '缚龙索', '上古缚龙之索，越是挣扎勒得越紧，捆人亦捆兽。', '地阶', '🪢', 6950, '攻击法宝'
  UNION ALL SELECT '焚天扇', '一扇起风、二扇生火、三扇燎野，非大能不可轻挥。', '天阶', '🪭', 8620, '攻击法宝'
  UNION ALL SELECT '铁骨鞭', '以妖骨节节串成，抽人不见血，伤在筋骨与神魂。', '玄阶', '🦴', 5470, '攻击法宝'
  UNION ALL SELECT '飞蝗针', '一次可散出三百六十枚细针，蚁多咬死象。', '黄阶', '📍', 4260, '攻击法宝'
) AS t
JOIN `category` c ON c.name = t.cat AND c.level = 2
WHERE NOT EXISTS (SELECT 1 FROM `content_item` x WHERE x.title = t.title);

-- 5.8 防御法宝
INSERT INTO `content_item` (`title`, `description`, `category_id`, `grade`, `icon`, `view_count`)
SELECT t.title, t.description, c.id, t.grade, t.icon, t.view_count
FROM (
            SELECT '玄武宝甲' AS title, '取上古玄武甲壳炼制，刀枪不入，唯气闷难久着。' AS description, '地阶' AS grade, '🛡️' AS icon, 7710 AS view_count, '防御法宝' AS cat
  UNION ALL SELECT '太虚玄光罩', '罩起如琉璃，可挡三次同阶全力一击，三次之后自碎。', '天阶', '🔵', 8940, '防御法宝'
  UNION ALL SELECT '金刚护心镜', '贴于胸前者，可卸三成力于身外，唯惧背后偷袭。', '玄阶', '🪞', 6470, '防御法宝'
  UNION ALL SELECT '九幽尸衣', '以千年尸茧织成，刀剑不穿、火烧不烂，着之者气息如死人。', '地阶', '👘', 7360, '防御法宝'
  UNION ALL SELECT '缠丝软甲', '千根蚕丝缠成，轻若无物，贴身可挡暗器与流矢。', '黄阶', '🕸️', 4590, '防御法宝'
  UNION ALL SELECT '山河盾', '盾上刻山河地理，受击时万里山川共担其力。', '天阶', '🏔️', 9180, '防御法宝'
  UNION ALL SELECT '寒玉障壁', '掷出成障，寒气凝壁，破之需三击同处。', '玄阶', '❄️', 6080, '防御法宝'
  UNION ALL SELECT '不动明王钟', '钟起声波成域，域中万法皆缓三分，攻守两用。', '地阶', '🔔', 7590, '防御法宝'
  UNION ALL SELECT '替身符偶', '刻主人生辰的木偶，替主人受一次死击即成齑粉。', '玄阶', '🎎', 6830, '防御法宝'
  UNION ALL SELECT '紫金钵盂', '钵口朝天可罩自身，水火不侵，唯行动迟缓。', '地阶', '🍚', 7040, '防御法宝'
  UNION ALL SELECT '血魂护主牌', '以心头血养之，主人垂危时自动挡下致命一击。', '天阶', '🩸', 8860, '防御法宝'
  UNION ALL SELECT '藤甲护身', '山藤老根编成，箭矢难入，然遇火即焚，需谨慎。', '黄阶', '🌿', 3720, '防御法宝'
) AS t
JOIN `category` c ON c.name = t.cat AND c.level = 2
WHERE NOT EXISTS (SELECT 1 FROM `content_item` x WHERE x.title = t.title);

-- 5.9 飞行灵兽
INSERT INTO `content_item` (`title`, `description`, `category_id`, `grade`, `icon`, `view_count`)
SELECT t.title, t.description, c.id, t.grade, t.icon, t.view_count
FROM (
            SELECT '赤炎火凤' AS title, '南明离火所化，羽落成焰，可载人日行十万八千里。' AS description, '天阶' AS grade, '🦅' AS icon, 9430 AS view_count, '飞行灵兽' AS cat
  UNION ALL SELECT '玄冰白鹤', '自极北寒渊来，双翼展开可凝云成冰，飞行无声。', '地阶', '🕊️', 7280, '飞行灵兽'
  UNION ALL SELECT '幽冥蝠王', '夜行如影，散播阴气遮蔽天光，最宜潜行潜入。', '玄阶', '🦇', 6340, '飞行灵兽'
  UNION ALL SELECT '金翅大鹏', '一翅九万里，振翅可起飓风，非大能者镇不住其性。', '天阶', '🦅', 9660, '飞行灵兽'
  UNION ALL SELECT '云纹青鸾', '青鸾过处云雾自生，可藏行迹，性情温顺通人意。', '地阶', '🪶', 7690, '飞行灵兽'
  UNION ALL SELECT '赤鬃焰马', '踏火而行，四蹄过处留一串燃痕，奔行百里不歇。', '玄阶', '🐎', 5870, '飞行灵兽'
  UNION ALL SELECT '雷翼飞蛟', '生双翼，御雷而行，落雷之处焦土遍野。', '天阶', '🐉', 9210, '飞行灵兽'
  UNION ALL SELECT '纸鹤灵', '符纸所折，载人不足百斤，然价廉易得，散修最爱。', '黄阶', '📃', 3920, '飞行灵兽'
  UNION ALL SELECT '紫翼天蝠', '翼生紫纹，飞行时周身紫雾弥漫，可迷敌目。', '玄阶', '🦇', 5610, '飞行灵兽'
  UNION ALL SELECT '风隼', '身小而疾，御之者如乘风，传讯千里可日还。', '黄阶', '🦅', 4180, '飞行灵兽'
) AS t
JOIN `category` c ON c.name = t.cat AND c.level = 2
WHERE NOT EXISTS (SELECT 1 FROM `content_item` x WHERE x.title = t.title);

-- 5.10 守护灵兽
INSERT INTO `content_item` (`title`, `description`, `category_id`, `grade`, `icon`, `view_count`)
SELECT t.title, t.description, c.id, t.grade, t.icon, t.view_count
FROM (
            SELECT '啸月天狼' AS title, '月圆之夜战力翻倍的忠勇灵兽，护主之心至死不改。' AS description, '玄阶' AS grade, '🐺' AS icon, 6820 AS view_count, '守护灵兽' AS cat
  UNION ALL SELECT '玄甲铁犀', '皮坚如铁，横身一挡可替主人受三击，性慢而忠。', '地阶', '🦏', 7140, '守护灵兽'
  UNION ALL SELECT '九尾天狐', '狐尾每增一尾便多一幻术，护主时以幻遮身，以媚惑敌。', '天阶', '🦊', 9370, '守护灵兽'
  UNION ALL SELECT '石胎守卫', '以山石封神魂而成，不眠不休守在洞府门口三百载。', '地阶', '🗿', 7460, '守护灵兽'
  UNION ALL SELECT '赤眼蛟蜥', '两眼赤红如灯，能吐毒雾成墙，护主时全身鳞甲炸立。', '玄阶', '🦎', 6180, '守护灵兽'
  UNION ALL SELECT '千年树妖', '根须盘地，可自地底缚敌，护院最是牢靠。', '地阶', '🌳', 6890, '守护灵兽'
  UNION ALL SELECT '白骨犬', '枯骨所化，不知痛、不畏死，主人一声令下便冲阵。', '黄阶', '🐕', 4260, '守护灵兽'
  UNION ALL SELECT '玄龟老祖', '背负玄甲，寿逾万年，护身结界可抵元婴一击。', '天阶', '🐢', 9050, '守护灵兽'
  UNION ALL SELECT '墨麒麟', '无角之麟，气息厚重压场，邪祟见之不敢近。', '天阶', '🐐', 8940, '守护灵兽'
  UNION ALL SELECT '照影猫', '九命之猫，能窥人心念，主人遇险前必先炸毛。', '黄阶', '🐈', 3970, '守护灵兽'
  UNION ALL SELECT '铁背苍猿', '臂能举鼎，护主时挡在最前，挨打愈多怒气愈盛。', '玄阶', '🦍', 5640, '守护灵兽'
) AS t
JOIN `category` c ON c.name = t.cat AND c.level = 2
WHERE NOT EXISTS (SELECT 1 FROM `content_item` x WHERE x.title = t.title);

-- 5.11 典籍（挂在顶级分类「典籍」下）
INSERT INTO `content_item` (`title`, `description`, `category_id`, `grade`, `icon`, `view_count`)
SELECT t.title, t.description, c.id, t.grade, t.icon, t.view_count
FROM (
            SELECT '魔宗起居注' AS title, '历代宗主手札，字里行间藏着宗门最大的秘密与最深的债。' AS description, '地阶' AS grade, '📖' AS icon, 7420 AS view_count, '典籍' AS cat
  UNION ALL SELECT '万法源流考', '考证诸天功法源流，一册在手，可辨天下功法之根脚。', '天阶', '📚', 8860, '典籍'
  UNION ALL SELECT '山河地理志', '记载九州灵脉、秘境、灵材产地，行商修士必备。', '玄阶', '🗺️', 6410, '典籍'
  UNION ALL SELECT '百炼丹方集', '丹修手抄药方八百余则，多处批注：此方慎用。', '地阶', '⚗️', 7730, '典籍'
  UNION ALL SELECT '神兵谱', '录古今法宝名器，附其铸造者之辛酸旧事。', '地阶', '🗡️', 7560, '典籍'
  UNION ALL SELECT '上古神魔录', '录神魔之战始末，读之者常于梦中见血。', '天阶', '👁️', 9180, '典籍'
  UNION ALL SELECT '灵兽驯养经', '自筑基期至化神期的驯兽之法，附灵兽脾性一览。', '玄阶', '🐾', 5980, '典籍'
  UNION ALL SELECT '阵道真解', '三百六十阵图详解，破阵者当先识阵。', '地阶', '🕸️', 7090, '典籍'
  UNION ALL SELECT '星象推演录', '以星轨推演大劫之期，无人敢信，又无人敢不看。', '玄阶', '🌟', 6230, '典籍'
  UNION ALL SELECT '残卷·太初篇', '仅余七页，却引得三派为此血战一场。', '天阶', '📜', 9410, '典籍'
  UNION ALL SELECT '草木灵材典', '录天下灵草三千种，附图辨真伪，采药人赖此活命。', '黄阶', '🌱', 4120, '典籍'
) AS t
JOIN `category` c ON c.name = t.cat AND c.parent_id = 0
WHERE NOT EXISTS (SELECT 1 FROM `content_item` x WHERE x.title = t.title);

-- ============================================================
-- 6. 校验
-- ============================================================
SELECT c.id, c.name, c.level, c.parent_id,
       (SELECT COUNT(*) FROM `content_item` i WHERE i.category_id = c.id) AS items
FROM `category` c
ORDER BY c.level, c.sort, c.id;

SELECT COUNT(*) AS 分类总数 FROM `category`;
SELECT COUNT(*) AS 条目总数 FROM `content_item`;
