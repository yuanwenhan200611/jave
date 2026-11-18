/*
 Navicat Premium Dump SQL

 Source Server         : test
 Source Server Type    : MySQL
 Source Server Version : 80039 (8.0.39)
 Source Host           : localhost:3306
 Source Schema         : login_db

 Target Server Type    : MySQL
 Target Server Version : 80039 (8.0.39)
 File Encoding         : 65001

 Date: 18/11/2026 09:57:26
*/

SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;

-- ----------------------------
-- Table structure for category
-- ----------------------------
DROP TABLE IF EXISTS `category`;
CREATE TABLE `category`  (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '主键，自增',
  `name` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT '分类名称',
  `parent_id` bigint NOT NULL DEFAULT 0 COMMENT '父分类 id，0 表示顶级',
  `level` int NOT NULL DEFAULT 1 COMMENT '层级：1 顶级 / 2 二级 / 3 三级...',
  `sort` int NOT NULL DEFAULT 0 COMMENT '排序值，越小越靠前',
  `icon` varchar(16) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NULL DEFAULT NULL COMMENT '图标（emoji）',
  `description` varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NULL DEFAULT NULL COMMENT '分类描述',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  PRIMARY KEY (`id`) USING BTREE,
  INDEX `idx_parent`(`parent_id` ASC) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 23 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_general_ci COMMENT = '首页分级分类表' ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of category
-- ----------------------------
INSERT INTO `category` VALUES (1, '功法', 0, 1, 1, '📜', '诸天功法，皆可习练', '2026-11-18 08:58:54');
INSERT INTO `category` VALUES (2, '秘境', 0, 1, 2, '🗺️', '无尽秘境，待你开辟', '2026-11-18 08:58:54');
INSERT INTO `category` VALUES (3, '丹药', 0, 1, 3, '⚗️', '逆天改命之丹', '2026-11-18 08:58:54');
INSERT INTO `category` VALUES (4, '法宝', 0, 1, 4, '🗡️', '神兵利器，掌中乾坤', '2026-11-18 08:58:54');
INSERT INTO `category` VALUES (5, '灵兽', 0, 1, 5, '🐉', '万兽臣服，皆入麾下', '2026-11-18 08:58:54');
INSERT INTO `category` VALUES (6, '典籍', 0, 1, 6, '📖', '万载传承，尽数收录', '2026-11-18 08:58:54');
INSERT INTO `category` VALUES (8, '炼体功法', 1, 2, 1, '💪', '淬体炼骨，根基之道', '2026-11-18 08:58:54');
INSERT INTO `category` VALUES (9, '心法口诀', 1, 2, 2, '🧘', '凝聚灵力，运转周天', '2026-11-18 08:58:54');
INSERT INTO `category` VALUES (10, '上古秘境', 2, 2, 1, '🗿', '洪荒遗地，机缘无数', '2026-11-18 08:58:54');
INSERT INTO `category` VALUES (11, '幻境试炼', 2, 2, 2, '🌫️', '心魔考验，突破之地', '2026-11-18 08:58:54');
INSERT INTO `category` VALUES (12, '回春丹', 3, 2, 1, '🌿', '疗伤圣药', '2026-11-18 08:58:54');
INSERT INTO `category` VALUES (13, '破境丹', 3, 2, 2, '⚡', '助修士破除瓶颈', '2026-11-18 08:58:54');
INSERT INTO `category` VALUES (14, '攻击法宝', 4, 2, 1, '⚔️', '斩敌破阵', '2026-11-18 08:58:54');
INSERT INTO `category` VALUES (15, '防御法宝', 4, 2, 2, '🛡️', '护体保命', '2026-11-18 08:58:54');
INSERT INTO `category` VALUES (16, '飞行灵兽', 5, 2, 1, '🦅', '翱翔九天', '2026-11-18 08:58:54');
INSERT INTO `category` VALUES (17, '守护灵兽', 5, 2, 2, '🐺', '忠心护主', '2026-11-18 08:58:54');

-- ----------------------------
-- Table structure for content_item
-- ----------------------------
DROP TABLE IF EXISTS `content_item`;
CREATE TABLE `content_item`  (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '主键，自增',
  `title` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT '标题',
  `description` varchar(500) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NULL DEFAULT NULL COMMENT '简介',
  `category_id` bigint NOT NULL COMMENT '所属分类 id（可为任意层级分类）',
  `grade` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NULL DEFAULT NULL COMMENT '品阶（天阶/地阶/玄阶/黄阶等）',
  `required_contribution` bigint NOT NULL DEFAULT 0 COMMENT '参悟所需贡献值（仅功法类 > 0）',
  `icon` varchar(16) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NULL DEFAULT NULL COMMENT '图标（emoji，展示用）',
  `view_count` bigint NOT NULL DEFAULT 0 COMMENT '浏览量',
  `status` tinyint NOT NULL DEFAULT 1 COMMENT '状态：1 上架 / 0 下架',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`) USING BTREE,
  INDEX `idx_category`(`category_id` ASC) USING BTREE,
  INDEX `idx_title`(`title` ASC) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 249 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_general_ci COMMENT = '首页内容条目表' ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of content_item
-- ----------------------------
INSERT INTO `content_item` VALUES (1, '魔宗起居注', '历代宗主手札，藏着宗门最大的秘密', 6, '地阶', 0, '📖', 6100, 1, '2026-11-18 08:58:54', '2026-11-18 08:58:54');
INSERT INTO `content_item` VALUES (2, '九转玄冥体', '以魔气淬体的无上炼体法，肉身可撼山岳', 8, '地阶', 800, '💪', 8600, 1, '2026-11-18 08:58:54', '2026-11-18 08:58:54');
INSERT INTO `content_item` VALUES (3, '化神诀残卷', '残缺的上古化神法门，参悟者寥寥', 9, '玄阶', 400, '📜', 3900, 1, '2026-11-18 08:58:54', '2026-11-18 08:58:54');
INSERT INTO `content_item` VALUES (4, '吞天魔功', '上古魔宗镇宗功法，吞纳天地灵气化为己用', 9, '天阶', 1500, '📜', 10000, 1, '2026-11-18 08:58:54', '2026-11-18 09:26:14');
INSERT INTO `content_item` VALUES (5, '幽冥血海秘境', '上古魔神陨落之地，遍地机缘亦遍地杀机', 10, '天阶', 0, '🗿', 9200, 1, '2026-11-18 08:58:54', '2026-11-18 08:58:54');
INSERT INTO `content_item` VALUES (6, '心魔幻阵', '闯过者道心通明，闯不过者道基尽毁', 11, '玄阶', 0, '🌫️', 7300, 1, '2026-11-18 08:58:54', '2026-11-18 08:58:54');
INSERT INTO `content_item` VALUES (7, '九转还魂丹', '传说可令陨落修士重生的禁忌丹药', 12, '天阶', 0, '🌿', 8800, 1, '2026-11-18 08:58:54', '2026-11-18 08:58:54');
INSERT INTO `content_item` VALUES (8, '破境丹', '卡境界者的福音，一枚可搏一次突破契机', 13, '地阶', 0, '⚡', 6500, 1, '2026-11-18 08:58:54', '2026-11-18 08:58:54');
INSERT INTO `content_item` VALUES (9, '诛仙魔剑', '饮血万千的魔道至宝，出鞘必见血', 14, '天阶', 0, '⚔️', 9998, 1, '2026-11-18 08:58:54', '2026-11-18 08:58:54');
INSERT INTO `content_item` VALUES (10, '玄武宝甲', '取上古玄武甲壳炼制，刀枪不入', 15, '地阶', 0, '🛡️', 5400, 1, '2026-11-18 08:58:54', '2026-11-18 08:58:54');
INSERT INTO `content_item` VALUES (11, '赤炎火凤', '南明离火所化，可载人日行十万八千里', 16, '天阶', 0, '🦅', 7700, 1, '2026-11-18 08:58:54', '2026-11-18 08:58:54');
INSERT INTO `content_item` VALUES (12, '啸月天狼', '月圆之夜战力翻倍的忠勇灵兽', 17, '玄阶', 0, '🐺', 4800, 1, '2026-11-18 08:58:54', '2026-11-18 08:58:54');
INSERT INTO `content_item` VALUES (16, '金刚不坏身', '以周身三百六十骨节为炉，日夜锤打，皮肉如金石，刀斧难伤分毫。', 8, '天阶', 1500, '🗿', 9120, 1, '2026-11-18 08:58:54', '2026-11-18 09:01:15');
INSERT INTO `content_item` VALUES (17, '血煞炼骨术', '引凶兽精血入骨，骨中生煞，一击可碎山门。然煞气反噬，心如擂鼓。', 8, '地阶', 800, '🩸', 7840, 1, '2026-11-18 08:58:54', '2026-11-18 09:01:15');
INSERT INTO `content_item` VALUES (18, '春雷淬身诀', '每岁惊蛰引天雷淬体，痛极则生，九淬之后血肉自生雷纹。', 8, '玄阶', 400, '⚡', 6210, 1, '2026-11-18 08:58:54', '2026-11-18 09:01:15');
INSERT INTO `content_item` VALUES (19, '不周山印', '以身作山，重逾万钧，气机一动便压塌一方天地。', 8, '天阶', 1500, '⛰️', 8760, 1, '2026-11-18 08:58:54', '2026-11-18 09:01:15');
INSERT INTO `content_item` VALUES (20, '玄龟息法', '吞吐迟缓如龟，可闭气三月不死，肉身生鳞，万毒不侵。', 8, '黄阶', 150, '🐢', 4320, 1, '2026-11-18 08:58:54', '2026-11-18 09:01:15');
INSERT INTO `content_item` VALUES (21, '焚身决', '以真火自焚其身，焚去凡胎浊骨，浴火一遭，胜修十年苦功。', 8, '玄阶', 400, '🔥', 5680, 1, '2026-11-18 08:58:54', '2026-11-18 09:01:15');
INSERT INTO `content_item` VALUES (22, '冰魄寒体', '久居极北寒渊，以身饲冰，血凝成霜，举手投足皆是万里冰封。', 8, '地阶', 800, '❄️', 7010, 1, '2026-11-18 08:58:54', '2026-11-18 09:01:15');
INSERT INTO `content_item` VALUES (23, '万木回春体', '借草木生机淬体，断肢可续，重伤自愈，唯惧烈火焚林。', 8, '黄阶', 150, '🌿', 3890, 1, '2026-11-18 08:58:54', '2026-11-18 09:01:15');
INSERT INTO `content_item` VALUES (24, '修罗战体', '以杀养体，每斩一敌肉躯便厚重一分，杀满千敌可徒手撕蛟。', 8, '天阶', 1500, '🗡️', 9450, 1, '2026-11-18 08:58:54', '2026-11-18 09:01:15');
INSERT INTO `content_item` VALUES (25, '紫府真形', '观想紫府神宫，将肉身炼作道场，内蕴一方小世界，坚不可摧。', 8, '地阶', 800, '🔮', 7260, 1, '2026-11-18 08:58:54', '2026-11-18 09:01:15');
INSERT INTO `content_item` VALUES (26, '龙象大力诀', '每日子时扛石磨骨，积九牛二虎之力于双臂，力可撼岳。', 8, '玄阶', 400, '🐘', 5480, 1, '2026-11-18 08:58:54', '2026-11-18 09:01:15');
INSERT INTO `content_item` VALUES (27, '枯荣禅体', '一念枯、一念荣，枯时如朽木可受万击，荣时生机暴涨还以重拳。', 8, '地阶', 800, '🍂', 6730, 1, '2026-11-18 08:58:54', '2026-11-18 09:01:15');
INSERT INTO `content_item` VALUES (31, '太虚周天诀', '一念引气走周天，三百六十窍窍窍皆通，吐纳之间自成天地。', 9, '天阶', 1500, '🌀', 9340, 1, '2026-11-18 08:58:54', '2026-11-18 09:01:15');
INSERT INTO `content_item` VALUES (32, '清心明性经', '魔宗弟子入门第一课，斩杂念、定道心，心魔不生则万法可修。', 9, '黄阶', 150, '🪷', 4120, 1, '2026-11-18 08:58:54', '2026-11-18 09:01:15');
INSERT INTO `content_item` VALUES (33, '紫气东来诀', '寅时面东而坐，纳第一缕紫气入丹田，修至圆满则气血如朝霞。', 9, '地阶', 800, '🌅', 7680, 1, '2026-11-18 08:58:54', '2026-11-18 09:01:15');
INSERT INTO `content_item` VALUES (34, '九幽噬灵法', '以神魂为钩，吞噬残魂补己身，神识远胜同阶，然夜夜闻哭声。', 9, '天阶', 1500, '👁️', 8890, 1, '2026-11-18 08:58:54', '2026-11-18 09:01:15');
INSERT INTO `content_item` VALUES (35, '无相真空咒', '心中无一物，万法皆是空。敌之神通落于身上，如投石入水。', 9, '玄阶', 400, '🕳️', 5970, 1, '2026-11-18 08:58:54', '2026-11-18 09:01:15');
INSERT INTO `content_item` VALUES (36, '两仪归元诀', '阴阳二气交抱轮转，攻守一体，动若奔雷，静若古井。', 9, '地阶', 800, '☯️', 7420, 1, '2026-11-18 08:58:54', '2026-11-18 09:01:15');
INSERT INTO `content_item` VALUES (37, '燃灯续命篇', '以自身寿元为薪，点燃一盏心灯，灯不灭则命不绝。', 9, '玄阶', 400, '🕯️', 5630, 1, '2026-11-18 08:58:54', '2026-11-18 09:01:15');
INSERT INTO `content_item` VALUES (38, '万象归心图', '观想三千世界尽入方寸，神识铺开可察方圆百里草木之动。', 9, '玄阶', 400, '🌌', 6080, 1, '2026-11-18 08:58:54', '2026-11-18 09:01:15');
INSERT INTO `content_item` VALUES (39, '北冥蓄灵诀', '气海如北冥之渊，蓄灵十倍于常修，久战不竭。', 9, '地阶', 800, '🌊', 7150, 1, '2026-11-18 08:58:54', '2026-11-18 09:01:15');
INSERT INTO `content_item` VALUES (40, '一念千年诀', '识海自成一界，外界一瞬，识海已参悟千载，闭关破境之神物。', 9, '天阶', 1500, '⏳', 9010, 1, '2026-11-18 08:58:54', '2026-11-18 09:01:15');
INSERT INTO `content_item` VALUES (41, '寒潭静照法', '心如寒潭映月，照见己身诸般妄念，妄念一散，灵台自清。', 9, '玄阶', 400, '🌙', 5340, 1, '2026-11-18 08:58:54', '2026-11-18 09:01:15');
INSERT INTO `content_item` VALUES (42, '劫火焚心经', '每夜观想劫火焚心，焚去怯懦，此后临阵不惧、赴死不退。', 9, '地阶', 800, '🔥', 6890, 1, '2026-11-18 08:58:54', '2026-11-18 09:01:15');
INSERT INTO `content_item` VALUES (46, '不周山墟', '天柱折处，残峰悬空，山腹藏有上古神魔断骨，机缘与杀机并存。', 10, '天阶', 0, '⛰️', 9560, 1, '2026-11-18 08:58:54', '2026-11-18 08:58:54');
INSERT INTO `content_item` VALUES (47, '归墟海眼', '万水归流之尽头，海水倒灌天穹，深处可闻先民钟鸣。', 10, '天阶', 0, '🌊', 9280, 1, '2026-11-18 08:58:54', '2026-11-18 08:58:54');
INSERT INTO `content_item` VALUES (48, '枯骨荒原', '白骨堆积成丘，风过如万人低语，昼夜颠倒，尸傀游荡。', 10, '玄阶', 0, '🦴', 6340, 1, '2026-11-18 08:58:54', '2026-11-18 08:58:54');
INSERT INTO `content_item` VALUES (49, '昆仑遗宫', '雪线之上的白玉宫阙，门前立无面石像，擅入者皆成石俑。', 10, '地阶', 0, '🏯', 8120, 1, '2026-11-18 08:58:54', '2026-11-18 08:58:54');
INSERT INTO `content_item` VALUES (50, '落星谷', '千年前天外陨星坠此，谷中石皆有星纹，触之可窥一线天机。', 10, '玄阶', 0, '☄️', 5820, 1, '2026-11-18 08:58:54', '2026-11-18 08:58:54');
INSERT INTO `content_item` VALUES (51, '幽冥鬼市', '子时方现的街市，鬼商贩卖活人不敢要的东西，只收寿元。', 10, '地阶', 0, '🏮', 7630, 1, '2026-11-18 08:58:54', '2026-11-18 08:58:54');
INSERT INTO `content_item` VALUES (52, '万剑坟场', '上古剑修尽殁于此，残剑插地如林，剑气未散，日夜铮鸣。', 10, '天阶', 0, '⚔️', 9740, 1, '2026-11-18 08:58:54', '2026-11-18 08:58:54');
INSERT INTO `content_item` VALUES (53, '沉舟海窟', '千艘古船沉于海底，船中货物保存如新，唯无人敢取。', 10, '玄阶', 0, '🚢', 5980, 1, '2026-11-18 08:58:54', '2026-11-18 08:58:54');
INSERT INTO `content_item` VALUES (54, '雷泽古林', '古木参天皆被雷火焚成焦炭，每逢雨夜雷声复起。', 10, '地阶', 0, '🌩️', 7180, 1, '2026-11-18 08:58:54', '2026-11-18 08:58:54');
INSERT INTO `content_item` VALUES (55, '血月荒祠', '每三十年血月临空，祠堂自开，祭品便是闯入者。', 10, '天阶', 0, '🌕', 8920, 1, '2026-11-18 08:58:54', '2026-11-18 08:58:54');
INSERT INTO `content_item` VALUES (56, '镜湖倒影界', '湖面映出的世界，与真实世界镜像颠倒，入者易迷失归途。', 10, '玄阶', 0, '🪞', 6150, 1, '2026-11-18 08:58:54', '2026-11-18 08:58:54');
INSERT INTO `content_item` VALUES (57, '天梯石阶', '九万九千级石阶通往云端，每一级都记着一位陨落者的名字。', 10, '地阶', 0, '🪜', 7840, 1, '2026-11-18 08:58:54', '2026-11-18 08:58:54');
INSERT INTO `content_item` VALUES (61, '九重问心阶', '一阶一问，九问九答，答不出的问题会化作利刃割开记忆。', 11, '地阶', 0, '🪜', 7560, 1, '2026-11-18 08:58:54', '2026-11-18 08:58:54');
INSERT INTO `content_item` VALUES (62, '镜中己身', '与另一个自己交手，他知晓你所有招式的破绽——因为他就是你。', 11, '天阶', 0, '🪞', 9030, 1, '2026-11-18 08:58:54', '2026-11-18 08:58:54');
INSERT INTO `content_item` VALUES (63, '黄粱一梦阵', '入阵即过完一生，醒来不过半炷香，然九成人不愿醒。', 11, '地阶', 0, '💭', 7840, 1, '2026-11-18 08:58:54', '2026-11-18 08:58:54');
INSERT INTO `content_item` VALUES (64, '七情困锁', '喜、怒、忧、思、悲、恐、惊各成一关，破一关割一情。', 11, '玄阶', 0, '🎭', 6420, 1, '2026-11-18 08:58:54', '2026-11-18 08:58:54');
INSERT INTO `content_item` VALUES (65, '无相试心台', '台上无物，唯有一面空镜，照出的不是你，而是你想要成为的人。', 11, '天阶', 0, '🔮', 8760, 1, '2026-11-18 08:58:54', '2026-11-18 08:58:54');
INSERT INTO `content_item` VALUES (66, '血池炼魂场', '魂魄入血池反复煎熬，熬得住则神识凝如实质。', 11, '地阶', 0, '🩸', 7310, 1, '2026-11-18 08:58:54', '2026-11-18 08:58:54');
INSERT INTO `content_item` VALUES (67, '百鬼夜行图', '画中百鬼齐出，需在画中活过一夜，鸡鸣方能脱身。', 11, '玄阶', 0, '👻', 5980, 1, '2026-11-18 08:58:54', '2026-11-18 08:58:54');
INSERT INTO `content_item` VALUES (68, '枯井回声境', '向井中呼喊，回应你的声音会说出你此生最不堪的往事。', 11, '黄阶', 0, '🕳️', 4270, 1, '2026-11-18 08:58:54', '2026-11-18 08:58:54');
INSERT INTO `content_item` VALUES (69, '轮回九世劫', '九世轮回，世世横死，第九世若仍执剑，方见真我。', 11, '天阶', 0, '⏳', 9180, 1, '2026-11-18 08:58:54', '2026-11-18 08:58:54');
INSERT INTO `content_item` VALUES (70, '寒冰绝念关', '心跳一停，幻境自破；心若不静，先冻住的是自己。', 11, '玄阶', 0, '❄️', 6150, 1, '2026-11-18 08:58:54', '2026-11-18 08:58:54');
INSERT INTO `content_item` VALUES (71, '万念俱灰台', '所有念想被抽走的一瞬，便是破境之机，亦是道消之始。', 11, '地阶', 0, '🌑', 7420, 1, '2026-11-18 08:58:54', '2026-11-18 08:58:54');
INSERT INTO `content_item` VALUES (76, '大回春丹', '断肢可续、五脏可补，疗伤圣药，一枚值一座小宗门。', 12, '地阶', 0, '💊', 8320, 1, '2026-11-18 08:58:54', '2026-11-18 08:58:54');
INSERT INTO `content_item` VALUES (77, '小还丹', '散修囊中常备之物，止血生肌，服之立见效。', 12, '黄阶', 0, '🟡', 4890, 1, '2026-11-18 08:58:54', '2026-11-18 08:58:54');
INSERT INTO `content_item` VALUES (78, '复脉养元丹', '重伤垂危者服之，脉象先稳，元气后补，为疗伤争取三日。', 12, '玄阶', 0, '🫀', 6740, 1, '2026-11-18 08:58:54', '2026-11-18 08:58:54');
INSERT INTO `content_item` VALUES (79, '碧灵清心丸', '解百毒、清心火，走火入魔初起服之，可将魔念压回识海。', 12, '地阶', 0, '🟢', 7480, 1, '2026-11-18 08:58:54', '2026-11-18 08:58:54');
INSERT INTO `content_item` VALUES (80, '续命金丹', '以百年寿元为丹引，为将死之人续命一年，一年之内不可再服。', 12, '天阶', 0, '⚜️', 8940, 1, '2026-11-18 08:58:54', '2026-11-18 08:58:54');
INSERT INTO `content_item` VALUES (81, '洗髓还元丹', '洗去体内丹毒与旧伤根，服后如获新生，然过程痛不欲生。', 12, '地阶', 0, '🫧', 7820, 1, '2026-11-18 08:58:54', '2026-11-18 08:58:54');
INSERT INTO `content_item` VALUES (82, '止血散', '最寻常的疗伤之药，碾碎敷于伤口，血即止住。', 12, '黄阶', 0, '🧂', 4120, 1, '2026-11-18 08:58:54', '2026-11-18 08:58:54');
INSERT INTO `content_item` VALUES (83, '固本培元丹', '体虚气弱者服之，如以温汤灌田，三日之内气力自复。', 12, '玄阶', 0, '🌾', 5960, 1, '2026-11-18 08:58:54', '2026-11-18 08:58:54');
INSERT INTO `content_item` VALUES (84, '回天造化丹', '只要一息尚存，便可从鬼门关拉回半条命，炼成者寥寥。', 12, '天阶', 0, '✨', 9180, 1, '2026-11-18 08:58:54', '2026-11-18 08:58:54');
INSERT INTO `content_item` VALUES (85, '养血生肌丹', '失血过多者之福音，服后三日便可再战。', 12, '玄阶', 0, '🩸', 6210, 1, '2026-11-18 08:58:54', '2026-11-18 08:58:54');
INSERT INTO `content_item` VALUES (86, '百草敷元膏', '非丹而是膏，涂于伤处，草木生机自皮肤渗入经脉。', 12, '黄阶', 0, '🌱', 3870, 1, '2026-11-18 08:58:54', '2026-11-18 08:58:54');
INSERT INTO `content_item` VALUES (91, '冲虚丹', '助筑基后期冲破虚境，服后三日经脉如鼓胀，慎用。', 13, '玄阶', 0, '🌀', 7140, 1, '2026-11-18 08:58:54', '2026-11-18 08:58:54');
INSERT INTO `content_item` VALUES (92, '化神引', '引动神魂蜕变之丹，服之者十有其三神魂崩散，余者化神。', 13, '天阶', 0, '👁️', 9260, 1, '2026-11-18 08:58:54', '2026-11-18 08:58:54');
INSERT INTO `content_item` VALUES (93, '凝金丹', '将散乱灵力凝为一颗金丹，金丹既成，寿元再增三百。', 13, '地阶', 0, '🟡', 8140, 1, '2026-11-18 08:58:54', '2026-11-18 08:58:54');
INSERT INTO `content_item` VALUES (94, '凿壁丹', '如凿壁透光，专为瓶颈如铁壁者所炼，一凿即通。', 13, '玄阶', 0, '🔨', 6320, 1, '2026-11-18 08:58:54', '2026-11-18 08:58:54');
INSERT INTO `content_item` VALUES (95, '洗尘丹', '洗去修行途中积下的杂浊之气，为下一次破境清场。', 13, '黄阶', 0, '💧', 4380, 1, '2026-11-18 08:58:54', '2026-11-18 08:58:54');
INSERT INTO `content_item` VALUES (96, '九窍通明丹', '服后九窍俱开，灵气往来无碍，破境成功率增三成。', 13, '地阶', 0, '🕳️', 7680, 1, '2026-11-18 08:58:54', '2026-11-18 08:58:54');
INSERT INTO `content_item` VALUES (97, '渡劫护心丹', '天劫临头前服下，可护住心脉不被劫雷震碎。', 13, '天阶', 0, '🌩️', 8940, 1, '2026-11-18 08:58:54', '2026-11-18 08:58:54');
INSERT INTO `content_item` VALUES (98, '破妄丹', '破除心中妄念与自我设限，副作用是三日之内口吐真言。', 13, '玄阶', 0, '🪞', 5870, 1, '2026-11-18 08:58:54', '2026-11-18 08:58:54');
INSERT INTO `content_item` VALUES (99, '固境丹', '境界初成时服之，可将新生境界夯实，免跌落之虞。', 13, '地阶', 0, '🏔️', 7210, 1, '2026-11-18 08:58:54', '2026-11-18 08:58:54');
INSERT INTO `content_item` VALUES (100, '引灵丹', '以丹力牵引外灵入体，为筑基之人铺第一级台阶。', 13, '黄阶', 0, '🌬️', 4050, 1, '2026-11-18 08:58:54', '2026-11-18 08:58:54');
INSERT INTO `content_item` VALUES (101, '魂契丹', '以自身一缕神魂为契，换取一次强行冲关的机会。', 13, '天阶', 0, '🔗', 8760, 1, '2026-11-18 08:58:54', '2026-11-18 08:58:54');
INSERT INTO `content_item` VALUES (106, '斩月弯刀', '刀光如新月一线，斩出时无声无息，敌人往往先倒后闻声。', 14, '地阶', 0, '🌙', 8360, 1, '2026-11-18 08:58:54', '2026-11-18 08:58:54');
INSERT INTO `content_item` VALUES (107, '九幽噬魂幡', '幡动则百鬼出，吞噬敌之神魂，为魔宗镇派重器。', 14, '天阶', 0, '🏴', 9120, 1, '2026-11-18 08:58:54', '2026-11-18 08:58:54');
INSERT INTO `content_item` VALUES (108, '裂山锤', '一锤落下山崩地裂，重而不失准，力修最爱。', 14, '玄阶', 0, '🔨', 6240, 1, '2026-11-18 08:58:54', '2026-11-18 08:58:54');
INSERT INTO `content_item` VALUES (109, '血饮枪', '枪尖饮血则愈利，一场大战之后枪身赤红如烙铁。', 14, '地阶', 0, '🔱', 7530, 1, '2026-11-18 08:58:54', '2026-11-18 08:58:54');
INSERT INTO `content_item` VALUES (110, '青莲剑', '剑身刻莲纹，出剑气成莲华，清正而不容邪祟。', 14, '天阶', 0, '🪷', 8740, 1, '2026-11-18 08:58:54', '2026-11-18 08:58:54');
INSERT INTO `content_item` VALUES (111, '夺魂钉', '七枚一套，钉入则锁魂，离体则魂散，防不胜防。', 14, '玄阶', 0, '📌', 6080, 1, '2026-11-18 08:58:54', '2026-11-18 08:58:54');
INSERT INTO `content_item` VALUES (112, '落雷锥', '掷出引天雷附于锥身，专破护身结界。', 14, '地阶', 0, '⚡', 7280, 1, '2026-11-18 08:58:54', '2026-11-18 08:58:54');
INSERT INTO `content_item` VALUES (113, '缚龙索', '上古缚龙之索，越是挣扎勒得越紧，捆人亦捆兽。', 14, '地阶', 0, '🪢', 6950, 1, '2026-11-18 08:58:54', '2026-11-18 08:58:54');
INSERT INTO `content_item` VALUES (114, '焚天扇', '一扇起风、二扇生火、三扇燎野，非大能不可轻挥。', 14, '天阶', 0, '🪭', 8620, 1, '2026-11-18 08:58:54', '2026-11-18 08:58:54');
INSERT INTO `content_item` VALUES (115, '铁骨鞭', '以妖骨节节串成，抽人不见血，伤在筋骨与神魂。', 14, '玄阶', 0, '🦴', 5470, 1, '2026-11-18 08:58:54', '2026-11-18 08:58:54');
INSERT INTO `content_item` VALUES (116, '飞蝗针', '一次可散出三百六十枚细针，蚁多咬死象。', 14, '黄阶', 0, '📍', 4260, 1, '2026-11-18 08:58:54', '2026-11-18 08:58:54');
INSERT INTO `content_item` VALUES (121, '太虚玄光罩', '罩起如琉璃，可挡三次同阶全力一击，三次之后自碎。', 15, '天阶', 0, '🔵', 8940, 1, '2026-11-18 08:58:54', '2026-11-18 08:58:54');
INSERT INTO `content_item` VALUES (122, '金刚护心镜', '贴于胸前者，可卸三成力于身外，唯惧背后偷袭。', 15, '玄阶', 0, '🪞', 6470, 1, '2026-11-18 08:58:54', '2026-11-18 08:58:54');
INSERT INTO `content_item` VALUES (123, '九幽尸衣', '以千年尸茧织成，刀剑不穿、火烧不烂，着之者气息如死人。', 15, '地阶', 0, '👘', 7360, 1, '2026-11-18 08:58:54', '2026-11-18 08:58:54');
INSERT INTO `content_item` VALUES (124, '缠丝软甲', '千根蚕丝缠成，轻若无物，贴身可挡暗器与流矢。', 15, '黄阶', 0, '🕸️', 4590, 1, '2026-11-18 08:58:54', '2026-11-18 08:58:54');
INSERT INTO `content_item` VALUES (125, '山河盾', '盾上刻山河地理，受击时万里山川共担其力。', 15, '天阶', 0, '🏔️', 9180, 1, '2026-11-18 08:58:54', '2026-11-18 08:58:54');
INSERT INTO `content_item` VALUES (126, '寒玉障壁', '掷出成障，寒气凝壁，破之需三击同处。', 15, '玄阶', 0, '❄️', 6080, 1, '2026-11-18 08:58:54', '2026-11-18 08:58:54');
INSERT INTO `content_item` VALUES (127, '不动明王钟', '钟起声波成域，域中万法皆缓三分，攻守两用。', 15, '地阶', 0, '🔔', 7590, 1, '2026-11-18 08:58:54', '2026-11-18 08:58:54');
INSERT INTO `content_item` VALUES (128, '替身符偶', '刻主人生辰的木偶，替主人受一次死击即成齑粉。', 15, '玄阶', 0, '🎎', 6830, 1, '2026-11-18 08:58:54', '2026-11-18 08:58:54');
INSERT INTO `content_item` VALUES (129, '紫金钵盂', '钵口朝天可罩自身，水火不侵，唯行动迟缓。', 15, '地阶', 0, '🍚', 7040, 1, '2026-11-18 08:58:54', '2026-11-18 08:58:54');
INSERT INTO `content_item` VALUES (130, '血魂护主牌', '以心头血养之，主人垂危时自动挡下致命一击。', 15, '天阶', 0, '🩸', 8860, 1, '2026-11-18 08:58:54', '2026-11-18 08:58:54');
INSERT INTO `content_item` VALUES (131, '藤甲护身', '山藤老根编成，箭矢难入，然遇火即焚，需谨慎。', 15, '黄阶', 0, '🌿', 3720, 1, '2026-11-18 08:58:54', '2026-11-18 08:58:54');
INSERT INTO `content_item` VALUES (136, '玄冰白鹤', '自极北寒渊来，双翼展开可凝云成冰，飞行无声。', 16, '地阶', 0, '🕊️', 7280, 1, '2026-11-18 08:58:54', '2026-11-18 08:58:54');
INSERT INTO `content_item` VALUES (137, '幽冥蝠王', '夜行如影，散播阴气遮蔽天光，最宜潜行潜入。', 16, '玄阶', 0, '🦇', 6340, 1, '2026-11-18 08:58:54', '2026-11-18 08:58:54');
INSERT INTO `content_item` VALUES (138, '金翅大鹏', '一翅九万里，振翅可起飓风，非大能者镇不住其性。', 16, '天阶', 0, '🦅', 9660, 1, '2026-11-18 08:58:54', '2026-11-18 08:58:54');
INSERT INTO `content_item` VALUES (139, '云纹青鸾', '青鸾过处云雾自生，可藏行迹，性情温顺通人意。', 16, '地阶', 0, '🪶', 7690, 1, '2026-11-18 08:58:54', '2026-11-18 08:58:54');
INSERT INTO `content_item` VALUES (140, '赤鬃焰马', '踏火而行，四蹄过处留一串燃痕，奔行百里不歇。', 16, '玄阶', 0, '🐎', 5870, 1, '2026-11-18 08:58:54', '2026-11-18 08:58:54');
INSERT INTO `content_item` VALUES (141, '雷翼飞蛟', '生双翼，御雷而行，落雷之处焦土遍野。', 16, '天阶', 0, '🐉', 9210, 1, '2026-11-18 08:58:54', '2026-11-18 08:58:54');
INSERT INTO `content_item` VALUES (142, '纸鹤灵', '符纸所折，载人不足百斤，然价廉易得，散修最爱。', 16, '黄阶', 0, '📃', 3920, 1, '2026-11-18 08:58:54', '2026-11-18 08:58:54');
INSERT INTO `content_item` VALUES (143, '紫翼天蝠', '翼生紫纹，飞行时周身紫雾弥漫，可迷敌目。', 16, '玄阶', 0, '🦇', 5610, 1, '2026-11-18 08:58:54', '2026-11-18 08:58:54');
INSERT INTO `content_item` VALUES (144, '风隼', '身小而疾，御之者如乘风，传讯千里可日还。', 16, '黄阶', 0, '🦅', 4180, 1, '2026-11-18 08:58:54', '2026-11-18 08:58:54');
INSERT INTO `content_item` VALUES (151, '玄甲铁犀', '皮坚如铁，横身一挡可替主人受三击，性慢而忠。', 17, '地阶', 0, '🦏', 7140, 1, '2026-11-18 08:58:54', '2026-11-18 08:58:54');
INSERT INTO `content_item` VALUES (152, '九尾天狐', '狐尾每增一尾便多一幻术，护主时以幻遮身，以媚惑敌。', 17, '天阶', 0, '🦊', 9370, 1, '2026-11-18 08:58:54', '2026-11-18 08:58:54');
INSERT INTO `content_item` VALUES (153, '石胎守卫', '以山石封神魂而成，不眠不休守在洞府门口三百载。', 17, '地阶', 0, '🗿', 7460, 1, '2026-11-18 08:58:54', '2026-11-18 08:58:54');
INSERT INTO `content_item` VALUES (154, '赤眼蛟蜥', '两眼赤红如灯，能吐毒雾成墙，护主时全身鳞甲炸立。', 17, '玄阶', 0, '🦎', 6180, 1, '2026-11-18 08:58:54', '2026-11-18 08:58:54');
INSERT INTO `content_item` VALUES (155, '千年树妖', '根须盘地，可自地底缚敌，护院最是牢靠。', 17, '地阶', 0, '🌳', 6890, 1, '2026-11-18 08:58:54', '2026-11-18 08:58:54');
INSERT INTO `content_item` VALUES (156, '白骨犬', '枯骨所化，不知痛、不畏死，主人一声令下便冲阵。', 17, '黄阶', 0, '🐕', 4260, 1, '2026-11-18 08:58:54', '2026-11-18 08:58:54');
INSERT INTO `content_item` VALUES (157, '玄龟老祖', '背负玄甲，寿逾万年，护身结界可抵元婴一击。', 17, '天阶', 0, '🐢', 9050, 1, '2026-11-18 08:58:54', '2026-11-18 08:58:54');
INSERT INTO `content_item` VALUES (158, '墨麒麟', '无角之麟，气息厚重压场，邪祟见之不敢近。', 17, '天阶', 0, '🐐', 8940, 1, '2026-11-18 08:58:54', '2026-11-18 08:58:54');
INSERT INTO `content_item` VALUES (159, '照影猫', '九命之猫，能窥人心念，主人遇险前必先炸毛。', 17, '黄阶', 0, '🐈', 3970, 1, '2026-11-18 08:58:54', '2026-11-18 08:58:54');
INSERT INTO `content_item` VALUES (160, '铁背苍猿', '臂能举鼎，护主时挡在最前，挨打愈多怒气愈盛。', 17, '玄阶', 0, '🦍', 5640, 1, '2026-11-18 08:58:54', '2026-11-18 08:58:54');
INSERT INTO `content_item` VALUES (166, '万法源流考', '考证诸天功法源流，一册在手，可辨天下功法之根脚。', 6, '天阶', 0, '📚', 8860, 1, '2026-11-18 08:58:54', '2026-11-18 08:58:54');
INSERT INTO `content_item` VALUES (167, '山河地理志', '记载九州灵脉、秘境、灵材产地，行商修士必备。', 6, '玄阶', 0, '🗺️', 6410, 1, '2026-11-18 08:58:54', '2026-11-18 08:58:54');
INSERT INTO `content_item` VALUES (168, '百炼丹方集', '丹修手抄药方八百余则，多处批注：此方慎用。', 6, '地阶', 0, '⚗️', 7730, 1, '2026-11-18 08:58:54', '2026-11-18 08:58:54');
INSERT INTO `content_item` VALUES (169, '神兵谱', '录古今法宝名器，附其铸造者之辛酸旧事。', 6, '地阶', 0, '🗡️', 7560, 1, '2026-11-18 08:58:54', '2026-11-18 08:58:54');
INSERT INTO `content_item` VALUES (170, '上古神魔录', '录神魔之战始末，读之者常于梦中见血。', 6, '天阶', 0, '👁️', 9180, 1, '2026-11-18 08:58:54', '2026-11-18 08:58:54');
INSERT INTO `content_item` VALUES (171, '灵兽驯养经', '自筑基期至化神期的驯兽之法，附灵兽脾性一览。', 6, '玄阶', 0, '🐾', 5980, 1, '2026-11-18 08:58:54', '2026-11-18 08:58:54');
INSERT INTO `content_item` VALUES (172, '阵道真解', '三百六十阵图详解，破阵者当先识阵。', 6, '地阶', 0, '🕸️', 7090, 1, '2026-11-18 08:58:54', '2026-11-18 08:58:54');
INSERT INTO `content_item` VALUES (173, '星象推演录', '以星轨推演大劫之期，无人敢信，又无人敢不看。', 6, '玄阶', 0, '🌟', 6230, 1, '2026-11-18 08:58:54', '2026-11-18 08:58:54');
INSERT INTO `content_item` VALUES (174, '残卷·太初篇', '仅余七页，却引得三派为此血战一场。', 6, '天阶', 0, '📜', 9410, 1, '2026-11-18 08:58:54', '2026-11-18 08:58:54');
INSERT INTO `content_item` VALUES (175, '草木灵材典', '录天下灵草三千种，附图辨真伪，采药人赖此活命。', 6, '黄阶', 0, '🌱', 4120, 1, '2026-11-18 08:58:54', '2026-11-18 08:58:54');
INSERT INTO `content_item` VALUES (181, '桃都山', '山有大桃木盘曲三千里，上栖金鸡，日出则天下鸡皆鸣。', 10, '地阶', 0, '🍑', 6890, 1, '2026-11-18 08:58:54', '2026-11-18 08:58:54');
INSERT INTO `content_item` VALUES (182, '焚天火域', '地火奔涌不熄，火中藏有火灵，浴火炼器者视之为宝地。', 10, '玄阶', 0, '🌋', 6050, 1, '2026-11-18 08:58:54', '2026-11-18 08:58:54');
INSERT INTO `content_item` VALUES (183, '九幽黄泉渡', '黄泉之上无舟自渡，渡口舟子只问一句：可悔？', 10, '天阶', 0, '⛵', 9170, 1, '2026-11-18 08:58:54', '2026-11-18 08:58:54');
INSERT INTO `content_item` VALUES (184, '听雨古城', '城郭犹在，人皆不见，唯雨声终年不歇，雨落处碑文自现。', 10, '黄阶', 0, '🌧️', 4460, 1, '2026-11-18 08:58:54', '2026-11-18 08:58:54');
INSERT INTO `content_item` VALUES (185, '星陨海沟', '海沟深不见底，陨星沉眠于此，每逢月圆泛出幽光如潮。', 10, '地阶', 0, '🌌', 7210, 1, '2026-11-18 08:58:54', '2026-11-18 08:58:54');
INSERT INTO `content_item` VALUES (188, '七情幻界', '喜、怒、忧、思、悲、恐、惊轮番加身，能守一情不动者，方出此境。', 11, '地阶', 0, '🎭', 8310, 1, '2026-11-18 08:58:54', '2026-11-18 08:58:54');
INSERT INTO `content_item` VALUES (189, '镜花水月阵', '所见皆为倒影，所击皆为镜面，破阵之钥从来不在手中。', 11, '玄阶', 0, '🪞', 6120, 1, '2026-11-18 08:58:54', '2026-11-18 08:58:54');
INSERT INTO `content_item` VALUES (190, '千世轮回劫', '一入此境历千世生死，每世皆忘前尘，能于第三世自悟者万中无一。', 11, '天阶', 0, '🕸️', 9380, 1, '2026-11-18 08:58:54', '2026-11-18 08:58:54');
INSERT INTO `content_item` VALUES (191, '无间杀阵', '四面八方皆杀机，不得停、不得退，唯有向前斩出一条血路。', 11, '地阶', 0, '🗡️', 7891, 1, '2026-11-18 08:58:54', '2026-11-18 09:26:27');
INSERT INTO `content_item` VALUES (192, '问心桥', '桥长九丈，每行一步便问一桩旧事，答错则坠入忘川。', 11, '黄阶', 0, '🌉', 4570, 1, '2026-11-18 08:58:54', '2026-11-18 08:58:54');
INSERT INTO `content_item` VALUES (193, '芥子须弥境', '入一微尘而见万里山河，出时外界不过一炷香，识海却已苍老。', 11, '地阶', 0, '🔍', 7060, 1, '2026-11-18 08:58:54', '2026-11-18 08:58:54');
INSERT INTO `content_item` VALUES (194, '无相幻阵', '此阵不设形、不设声，闯入者所见所闻皆是自己最怕之物。', 11, '玄阶', 0, '🕳️', 6430, 1, '2026-11-18 08:58:54', '2026-11-18 08:58:54');
INSERT INTO `content_item` VALUES (195, '落子天元局', '以自身为棋子入局对弈，对手是阵灵，输一子则少一年寿元。', 11, '天阶', 0, '♟️', 9050, 1, '2026-11-18 08:58:54', '2026-11-18 08:58:54');
INSERT INTO `content_item` VALUES (196, '无常梦乡', '梦中富贵荣华、妻儿绕膝，醒来方知身已过期三日。', 11, '黄阶', 0, '🌙', 4180, 1, '2026-11-18 08:58:54', '2026-11-18 08:58:54');
INSERT INTO `content_item` VALUES (197, '千机傀儡廊', '廊中傀儡皆按上古宗师招式出手，过廊可尽习百家之技。', 11, '玄阶', 0, '🎎', 6790, 1, '2026-11-18 08:58:54', '2026-11-18 08:58:54');
INSERT INTO `content_item` VALUES (198, '倒悬天梯', '天梯倒挂于虚空，上一步便少一寸修为，登顶者修为散尽却道心圆成。', 11, '地阶', 0, '🪜', 7320, 1, '2026-11-18 08:58:54', '2026-11-18 08:58:54');
INSERT INTO `content_item` VALUES (199, '一梦浮生阁', '于阁中睡一觉，醒来或已顿悟，或已白发。', 11, '玄阶', 0, '🛏️', 5560, 1, '2026-11-18 08:58:54', '2026-11-18 08:58:54');
INSERT INTO `content_item` VALUES (203, '生骨续脉丹', '断骨可接，经脉可续，服后三日痛如千万蚁行，此后行动如初。', 12, '地阶', 0, '🦴', 7340, 1, '2026-11-18 08:58:54', '2026-11-18 08:58:54');
INSERT INTO `content_item` VALUES (204, '青囊回春散', '医修随身之物，撒于伤口知痛即止血，不知痛者已是无救。', 12, '黄阶', 0, '🌿', 4980, 1, '2026-11-18 08:58:54', '2026-11-18 08:58:54');
INSERT INTO `content_item` VALUES (205, '百毒化清丸', '万毒攻心时服之，可将毒素尽数逼入足底，七日不得行路。', 12, '玄阶', 0, '🫧', 6170, 1, '2026-11-18 08:58:54', '2026-11-18 08:58:54');
INSERT INTO `content_item` VALUES (206, '雪魄凝神丹', '寒渊雪莲炼成，神魂飘摇时含之，识海如落雪般静定。', 12, '地阶', 0, '❄️', 7560, 1, '2026-11-18 08:58:54', '2026-11-18 08:58:54');
INSERT INTO `content_item` VALUES (207, '龙血生肌膏', '取蛟龙心头血调膏，刀伤剑创一夜可愈，唯留赤纹如龙鳞。', 12, '玄阶', 0, '🩸', 6620, 1, '2026-11-18 08:58:54', '2026-11-18 08:58:54');
INSERT INTO `content_item` VALUES (208, '回天再造丹', '肉白骨、起沉疴，然服之者须以三成修为相偿。', 12, '天阶', 0, '✨', 9140, 1, '2026-11-18 08:58:54', '2026-11-18 08:58:54');
INSERT INTO `content_item` VALUES (209, '清心莲子羹', '丹药中难得的温和之物，服之可解药毒、安六神。', 12, '黄阶', 0, '🪷', 3610, 1, '2026-11-18 08:58:54', '2026-11-18 08:58:54');
INSERT INTO `content_item` VALUES (210, '不灭金身丹', '服后皮肉生金纹，十息之内外伤不侵，唯惧内伤。', 12, '地阶', 0, '🛡️', 7130, 1, '2026-11-18 08:58:54', '2026-11-18 08:58:54');
INSERT INTO `content_item` VALUES (211, '续命灯芯丸', '以灯芯草裹寿元为丸，重创垂死者可再争一炷香。', 12, '玄阶', 0, '🕯️', 5890, 1, '2026-11-18 08:58:54', '2026-11-18 08:58:54');
INSERT INTO `content_item` VALUES (212, '鹿茸养元丹', '温养气血，久病体虚者服之，面色自红润如少年。', 12, '黄阶', 0, '🦌', 3860, 1, '2026-11-18 08:58:54', '2026-11-18 08:58:54');
INSERT INTO `content_item` VALUES (213, '九幽止血散', '魔宗行军常备，血涌如泉者一撒即止，唯药性霸道，用之者夜半怕冷。', 12, '玄阶', 0, '🩹', 5420, 1, '2026-11-18 08:58:54', '2026-11-18 08:58:54');
INSERT INTO `content_item` VALUES (218, '冲关破境丹', '瓶颈将破未破时服之，一念冲关，成则登堂，败则道基受损。', 13, '地阶', 0, '⚡', 8060, 1, '2026-11-18 08:58:54', '2026-11-18 08:58:54');
INSERT INTO `content_item` VALUES (219, '洗髓易骨丹', '褪去凡胎浊骨，脱胎换骨一回，痛彻骨髓，此后修行一日千里。', 13, '天阶', 0, '🦴', 8970, 1, '2026-11-18 08:58:54', '2026-11-18 08:58:54');
INSERT INTO `content_item` VALUES (220, '紫府开窍丹', '神识蒙昧者服之，可强开紫府一窍，从此所见天地清明三分。', 13, '地阶', 0, '🔮', 7280, 1, '2026-11-18 08:58:54', '2026-11-18 08:58:54');
INSERT INTO `content_item` VALUES (221, '燃血冲霄丹', '燃烧精血换取一时疯涨的灵力，境界可越一级，代价是十年寿数。', 13, '玄阶', 0, '🩸', 6540, 1, '2026-11-18 08:58:54', '2026-11-18 08:58:54');
INSERT INTO `content_item` VALUES (222, '金丹化纹丹', '金丹将凝者服之，可于丹上烙下一道天纹，威能陡增。', 13, '天阶', 0, '🌕', 8690, 1, '2026-11-18 08:58:54', '2026-11-18 08:58:54');
INSERT INTO `content_item` VALUES (223, '心魔破障丹', '专克突破时的心魔，服之心如铁石，唯余一念。', 13, '玄阶', 0, '🪨', 5980, 1, '2026-11-18 08:58:54', '2026-11-18 08:58:54');
INSERT INTO `content_item` VALUES (224, '悟道菩提子', '菩提树下结子，含于舌下入定，顿悟之机比苦修多出七分。', 13, '地阶', 0, '🌳', 7610, 1, '2026-11-18 08:58:54', '2026-11-18 08:58:54');
INSERT INTO `content_item` VALUES (225, '筑基固本丸', '筑基期弟子常备，可稳固根基，减三成走火入魔之险。', 13, '黄阶', 0, '🪷', 4350, 1, '2026-11-18 08:58:54', '2026-11-18 08:58:54');
INSERT INTO `content_item` VALUES (226, '淬灵散', '碎灵玉为粉，服之如灌灵泉，一夜涨百日之功，然根基虚浮。', 13, '黄阶', 0, '💠', 3970, 1, '2026-11-18 08:58:54', '2026-11-18 08:58:54');
INSERT INTO `content_item` VALUES (227, '九转归元丹', '九次炼化九次弃之，最后一炉只余一枚，服之境界归元圆满。', 13, '天阶', 0, '♻️', 9250, 1, '2026-11-18 08:58:54', '2026-11-18 08:58:54');
INSERT INTO `content_item` VALUES (228, '天河灌顶丹', '服之如天河倒灌泥丸宫，灵力暴涨三成，过则伤经脉。', 13, '地阶', 0, '💧', 7040, 1, '2026-11-18 08:58:54', '2026-11-18 08:58:54');
INSERT INTO `content_item` VALUES (229, '枯木逢春丹', '道基崩损者服之，可将残基重凝，然十年内不可再进境。', 13, '玄阶', 0, '🌱', 5680, 1, '2026-11-18 08:58:54', '2026-11-18 08:58:54');
INSERT INTO `content_item` VALUES (233, '噬魂血刀', '刀身以万人血祭而成，每斩一人便长一线，握刀者耳畔常闻低语。', 14, '天阶', 0, '🗡️', 9620, 1, '2026-11-18 08:58:54', '2026-11-18 08:58:54');
INSERT INTO `content_item` VALUES (234, '九幽冥火幡', '幡起幽火漫天，火不燃皮肉，专烧神魂，中者不觉痛便已魂灭。', 14, '天阶', 0, '🔥', 8830, 1, '2026-11-18 08:58:54', '2026-11-18 08:58:54');
INSERT INTO `content_item` VALUES (235, '断岳重剑', '剑宽三尺、重八千斤，一剑落下山岳为开，唯需炼体有成者方可执。', 14, '地阶', 0, '⚔️', 7590, 1, '2026-11-18 08:58:54', '2026-11-18 08:58:54');
INSERT INTO `content_item` VALUES (236, '摄魂钉', '三寸乌钉，打入眉心可摄人神魂，钉在墙上便能审其所知。', 14, '玄阶', 0, '📌', 6340, 1, '2026-11-18 08:58:54', '2026-11-18 08:58:54');
INSERT INTO `content_item` VALUES (237, '千机弩', '一次上弦三十六矢，矢出如雨，淬毒之物更难防。', 14, '黄阶', 0, '🏹', 4870, 1, '2026-11-18 08:58:54', '2026-11-18 08:58:54');
INSERT INTO `content_item` VALUES (238, '焚天印', '印成之时天火降世，落印之处方圆百丈化为焦土。', 14, '天阶', 0, '🔺', 9310, 1, '2026-11-18 08:58:54', '2026-11-18 08:58:54');
INSERT INTO `content_item` VALUES (239, '寒螭鞭', '蛟筋所制，鞭出带霜，抽中者伤口即刻冻裂如瓷器。', 14, '地阶', 0, '🐍', 7120, 1, '2026-11-18 08:58:54', '2026-11-18 08:58:54');
INSERT INTO `content_item` VALUES (240, '破军枪', '枪有杀气，愈战愈烈，破军之名取其一往无回。', 14, '地阶', 0, '🔱', 7860, 1, '2026-11-18 08:58:54', '2026-11-18 08:58:54');
INSERT INTO `content_item` VALUES (241, '落魂铃', '轻摇一声人心神恍惚，三摇人魂不归，故魔宗弟子慎用。', 14, '玄阶', 0, '🔔', 6580, 1, '2026-11-18 08:58:54', '2026-11-18 08:58:54');
INSERT INTO `content_item` VALUES (242, '斩月飞轮', '月牙双轮回旋，出必见血，入则回掌，最难缠的杀器。', 14, '玄阶', 0, '🌗', 6040, 1, '2026-11-18 08:58:54', '2026-11-18 08:58:54');
INSERT INTO `content_item` VALUES (243, '血煞屠戮剑', '剑饮其主之血方肯出鞘，愈伤愈狠，与主共生共死。', 14, '天阶', 0, '🩸', 9480, 1, '2026-11-18 08:58:54', '2026-11-18 08:58:54');
INSERT INTO `content_item` VALUES (244, '灵蜂针囊', '囊中养有千只灵蜂针，一放则如群蜂扑人，最难躲闪。', 14, '黄阶', 0, '🐝', 4230, 1, '2026-11-18 08:58:54', '2026-11-18 08:58:54');
INSERT INTO `content_item` VALUES (248, '宗门戒律录', '铁律三百条，首条曰：不得欺师灭祖。', 6, '黄阶', 0, '📕', 4380, 1, '2026-11-18 08:58:54', '2026-11-18 08:58:54');

-- ----------------------------
-- Table structure for cultivation_log
-- ----------------------------
DROP TABLE IF EXISTS `cultivation_log`;
CREATE TABLE `cultivation_log`  (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '主键',
  `username` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT '修炼人（关联 user.username）',
  `method_key` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT '法门标识：mogu/xuedan/xueji/duoshe/tuntian',
  `method_name` varchar(30) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT '法门名快照',
  `outcome` varchar(10) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT '结果：great 大成 / good 小成 / backlash 反噬',
  `delta` bigint NOT NULL DEFAULT 0 COMMENT '本次修为增减（负数为反噬）',
  `cost_stones` bigint NOT NULL DEFAULT 0 COMMENT '消耗灵石',
  `cost_contribution` bigint NOT NULL DEFAULT 0 COMMENT '消耗贡献值',
  `story` varchar(500) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NULL DEFAULT NULL COMMENT '修炼异象文案',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '修炼时间',
  PRIMARY KEY (`id`) USING BTREE,
  INDEX `idx_cl_user`(`username` ASC) USING BTREE,
  INDEX `idx_cl_method`(`username` ASC, `method_key` ASC) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 19 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_general_ci COMMENT = '魔功殿·修炼记录' ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of cultivation_log
-- ----------------------------
INSERT INTO `cultivation_log` VALUES (1, 'admin', 'mogu', '魔窟苦修', 'good', 109, 0, 0, '洞中忽有阴风绕体不走，你顺势引风入体，炼作一缕魔元，修为 +109。', '2026-11-18 09:23:28');
INSERT INTO `cultivation_log` VALUES (2, 'admin', 'mogu', '魔窟苦修', 'good', 139, 0, 0, '洞中忽有阴风绕体不走，你顺势引风入体，炼作一缕魔元，修为 +139。', '2026-11-18 09:24:01');
INSERT INTO `cultivation_log` VALUES (3, 'ywh', 'mogu', '魔窟苦修', 'good', 188, 0, 0, '魔窟石壁上留有前任看窟人的爪痕与一行小字：「煞气伤身，慢吞为宜」。你依言慢吞，修为 +188。', '2026-11-18 09:24:32');
INSERT INTO `cultivation_log` VALUES (4, 'ywh', 'duoshe', '夺舍夺元', 'great', 809, 0, 0, '子夜，散修洞府门户大开，护山大阵早已失效。你夺其金丹，吞其修为，天亮之前功成身退——修为暴涨 +809，江湖上只多了一具枯坐的躯壳。', '2026-11-18 09:24:45');
INSERT INTO `cultivation_log` VALUES (5, 'admin', 'xuedan', '吞噬血丹', 'good', 330, 100, 0, '丹香入鼻，魔气自生。你盘坐到天亮，只觉经脉宽阔了一分，修为 +330。', '2026-11-18 09:24:47');
INSERT INTO `cultivation_log` VALUES (6, 'admin', 'xueji', '血祭秘法', 'good', 859, 0, 200, '血火猩红，祭品哀鸣，修为缓缓上涨 +859。只是收功时你发现，左手无名指多了一道血纹——那是祭品的「收据」。', '2026-11-18 09:24:48');
INSERT INTO `cultivation_log` VALUES (7, 'ywh', 'mogu', '魔窟苦修', 'good', 149, 0, 0, '魔窟石壁上留有前任看窟人的爪痕与一行小字：「煞气伤身，慢吞为宜」。你依言慢吞，修为 +149。', '2026-11-18 09:27:08');
INSERT INTO `cultivation_log` VALUES (8, 'ywh', 'duoshe', '夺舍夺元', 'great', 1317, 0, 0, '子夜，散修洞府门户大开，护山大阵早已失效。你夺其金丹，吞其修为，天亮之前功成身退——修为暴涨 +1317，江湖上只多了一具枯坐的躯壳。', '2026-11-18 09:27:20');
INSERT INTO `cultivation_log` VALUES (9, 'admin', 'mogu', '魔窟苦修', 'good', 125, 0, 0, '洞中忽有阴风绕体不走，你顺势引风入体，炼作一缕魔元，修为 +125。', '2026-11-18 09:30:53');
INSERT INTO `cultivation_log` VALUES (10, 'ywh', 'mogu', '魔窟苦修', 'good', 81, 0, 0, '你在魔窟最深处寻得一处废弃丹室，废丹炉里的残火尚有余温。就着残火吐纳一夜，修为 +81。', '2026-11-18 09:31:10');
INSERT INTO `cultivation_log` VALUES (11, 'ywh', 'duoshe', '夺舍夺元', 'backlash', -320, 0, 0, '夺舍到一半，那散修睁开眼笑了：「等你很久了。」你落荒而逃，修为 -320。', '2026-11-18 09:31:13');
INSERT INTO `cultivation_log` VALUES (12, 'ywh', 'mogu', '魔窟苦修', 'good', 171, 0, 0, '魔窟石壁上留有前任看窟人的爪痕与一行小字：「煞气伤身，慢吞为宜」。你依言慢吞，修为 +171。', '2026-11-18 09:44:44');
INSERT INTO `cultivation_log` VALUES (13, 'ywh', 'duoshe', '夺舍夺元', 'backlash', -772, 0, 0, '护山大阵根本没失效——那是阵眼在装死。你被一道雷符劈出三里地，修为 -772，从此江湖多了个笑柄。', '2026-11-18 09:44:47');
INSERT INTO `cultivation_log` VALUES (14, 'ywh', 'xueji', '血祭秘法', 'good', 414, 0, 200, '魔坛认了你，精血化魔气入体，修为 +414。丹堂长老路过看了你一眼，没说话，走了。', '2026-11-18 09:45:17');
INSERT INTO `cultivation_log` VALUES (15, 'admin', 'forum_post', '开坛讲道', 'good', 150, 20, 0, '血月当空，你借月色开坛论法。散场时收坛的手都在抖——不是累的，是悟的。修为 +150。', '2026-11-18 09:51:02');
INSERT INTO `cultivation_log` VALUES (16, 'admin', 'forum_incense', '香火供奉', 'good', 40, 10, 0, '一炷香，一场道。你把听懂的半截反刍了三遍，修为 +40。', '2026-11-18 09:51:34');
INSERT INTO `cultivation_log` VALUES (17, 'admin', 'forum_counter', '血辩驳道', 'great', 176, 0, 0, '对方讲到你第三问就变了脸色。你趁势追击，威压之下竟悟出几分门道——修为 +176。', '2026-11-18 09:51:35');
INSERT INTO `cultivation_log` VALUES (18, 'admin', 'forum_incense', '香火供奉', 'good', 15, 10, 0, '你跪听了一场讲道，起身时只觉周身魔气凝了一分。香灰落进袖口也没顾上掸。修为 +15。', '2026-11-18 09:52:58');

-- ----------------------------
-- Table structure for forum_income
-- ----------------------------
DROP TABLE IF EXISTS `forum_income`;
CREATE TABLE `forum_income`  (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '主键',
  `username` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT '收益人',
  `stones` bigint NOT NULL DEFAULT 0 COMMENT '灵石收益',
  `contribution` bigint NOT NULL DEFAULT 0 COMMENT '贡献值收益',
  `source` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT '来源：incense 香火分成',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '入账时间',
  PRIMARY KEY (`id`) USING BTREE,
  INDEX `idx_fi_user`(`username` ASC) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 3 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_general_ci COMMENT = '血辩台·帖主分成账本' ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of forum_income
-- ----------------------------
INSERT INTO `forum_income` VALUES (1, '玉面罗刹', 0, 5, 'incense', '2026-11-18 09:51:34');
INSERT INTO `forum_income` VALUES (2, '阿蛮', 0, 5, 'incense', '2026-11-18 09:52:58');

-- ----------------------------
-- Table structure for forum_like
-- ----------------------------
DROP TABLE IF EXISTS `forum_like`;
CREATE TABLE `forum_like`  (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '主键',
  `post_id` bigint NOT NULL COMMENT '帖子 id（forum_post.id）',
  `username` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT '动作发起人',
  `action` varchar(16) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT '动作：incense 香火供奉 / counter 驳道',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '动作时间',
  PRIMARY KEY (`id`) USING BTREE,
  UNIQUE INDEX `uk_fl_post_user_action`(`post_id` ASC, `username` ASC, `action` ASC) USING BTREE,
  INDEX `idx_fl_user`(`username` ASC) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 4 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_general_ci COMMENT = '血辩台·动作记录' ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of forum_like
-- ----------------------------
INSERT INTO `forum_like` VALUES (1, 6, 'admin', 'incense', '2026-11-18 09:51:34');
INSERT INTO `forum_like` VALUES (2, 7, 'admin', 'counter', '2026-11-18 09:51:35');
INSERT INTO `forum_like` VALUES (3, 8, 'admin', 'incense', '2026-11-18 09:52:58');

-- ----------------------------
-- Table structure for forum_post
-- ----------------------------
DROP TABLE IF EXISTS `forum_post`;
CREATE TABLE `forum_post`  (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '主键',
  `author` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT '发帖人',
  `title` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT '帖名',
  `content` varchar(2000) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT '正文',
  `views` bigint NOT NULL DEFAULT 0 COMMENT '围观量',
  `likes` bigint NOT NULL DEFAULT 0 COMMENT '道心相印（点赞）',
  `counters` bigint NOT NULL DEFAULT 0 COMMENT '被驳次数（血辩台驳道）',
  `status` tinyint NOT NULL DEFAULT 1 COMMENT '状态：1 显示 / 0 屏蔽',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '发帖时间',
  PRIMARY KEY (`id`) USING BTREE,
  INDEX `idx_post_time`(`create_time` ASC) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 17 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_general_ci COMMENT = '论道帖' ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of forum_post
-- ----------------------------
INSERT INTO `forum_post` VALUES (1, '血无常', '【置顶】宗门戒律第一条：不得欺师灭祖', '戒律三百条，此为第一条。违者：废修为、逐出宗门、追杀千里。望诸弟子谨记。', 5200, 1314, 0, 1, '2026-11-18 08:58:54');
INSERT INTO `forum_post` VALUES (2, '白骨真人', '论炼体与炼心孰优孰劣', '炼体者皮糙肉厚一力破万法，炼心者神识如网千里锁敌。依老夫看，都没我一根骨头硬。不服者执法堂领教。', 3400, 880, 0, 1, '2026-11-18 08:58:54');
INSERT INTO `forum_post` VALUES (3, '幽冥子', '幽冥鬼市亲历：我只带了三成寿元进去', '子时入市的道友切记：鬼商报价只砍一轮，第二轮他还价就是看上你的寿元了。附避坑清单，阅后即焚。', 4600, 720, 0, 1, '2026-11-18 08:58:54');
INSERT INTO `forum_post` VALUES (4, '赤炎老祖', '求破境丹真伪鉴定', '丹坊新收一枚破境丹，丹纹三圈、气味微腥。有人说是赝品，有人说是丹纹独树一帜。懂行的道友掌掌眼。', 2100, 450, 0, 1, '2026-11-18 08:58:54');
INSERT INTO `forum_post` VALUES (5, '千面魔君', '万剑坟场捡剑指南（勿外传）', '戌时剑鸣最弱，从东南坡绕开剑气林，见残剑先拜三拜。此帖发完我去坟场蹲点，看看是谁在偷师。', 5800, 903, 0, 1, '2026-11-18 08:58:54');
INSERT INTO `forum_post` VALUES (6, '玉面罗刹', '血煞堂招新，只收心狠手辣者', '本堂扩招。要求：一敢下手，二不废话，三听指挥。修为不限，金丹以上可直接面见堂主。', 3900, 667, 0, 1, '2026-11-18 08:58:54');
INSERT INTO `forum_post` VALUES (7, '苏九黎', '心魔幻阵第七层卡了三个月，求破', '每次都死在\"故人相认\"那一幕。明知是幻，偏偏醒不过来。过来人道友给个法子，愿以丹方相谢。', 1800, 512, 1, 1, '2026-11-18 08:58:54');
INSERT INTO `forum_post` VALUES (8, '阿蛮', '论道规则：辱骂道友者罚扫藏经阁三月', '新来的道友看过来：论道讲的是以理服人，骂人一时爽，藏经阁扫地扫断腰。文明论道，从你我做起。', 900, 234, 0, 1, '2026-11-18 08:58:54');
INSERT INTO `forum_post` VALUES (16, 'admin', '驳「血丹万能论」', '血丹固好，然丹毒积于经脉，十年必发。吾观丹堂三例，皆死于贪丹。', 0, 0, 0, 1, '2026-11-18 09:51:02');

-- ----------------------------
-- Table structure for quest
-- ----------------------------
DROP TABLE IF EXISTS `quest`;
CREATE TABLE `quest`  (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '主键',
  `quest_type` varchar(10) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL DEFAULT 'sect' COMMENT '类型：sect 宗门悬赏 / personal 个人悬赏',
  `publisher` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NULL DEFAULT NULL COMMENT '发布人（宗门悬赏为 NULL，个人悬赏为用户名）',
  `title` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT '任务名',
  `description` varchar(500) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NULL DEFAULT NULL COMMENT '任务详情',
  `category` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT '分类：斩妖/夺宝/护送/炼丹/寻物/戒律/其它',
  `difficulty` varchar(10) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT '难度：简单/普通/困难/地狱',
  `min_realm` varchar(10) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL DEFAULT '炼气' COMMENT '修为门槛：炼气~魔尊，低于该境界不可接取',
  `max_accept` int NOT NULL DEFAULT 1 COMMENT '接取名额（完成/进行中占用名额，放弃后释放）',
  `reward_contribution` bigint NOT NULL DEFAULT 0 COMMENT '贡献值奖励（宗门悬赏）',
  `reward_stones` bigint NOT NULL DEFAULT 0 COMMENT '灵石奖励（宗门悬赏，可与贡献值兼得）',
  `reward_item` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NULL DEFAULT NULL COMMENT '物品奖励（个人悬赏：天才地宝/法宝等）',
  `icon` varchar(16) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NULL DEFAULT NULL COMMENT '图标（emoji）',
  `status` tinyint NOT NULL DEFAULT 1 COMMENT '状态：1 上架 / 0 下架',
  `accept_count` bigint NOT NULL DEFAULT 0 COMMENT '累计接取次数（热度展示）',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '发布时间',
  PRIMARY KEY (`id`) USING BTREE,
  INDEX `idx_quest_type`(`quest_type` ASC) USING BTREE,
  INDEX `idx_quest_category`(`category` ASC) USING BTREE,
  INDEX `idx_quest_status`(`status` ASC) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 23 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_general_ci COMMENT = '任务阁·任务牌' ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of quest
-- ----------------------------
INSERT INTO `quest` VALUES (1, 'sect', NULL, '清剿血狼坡狼群', '血狼坡狼群近来愈发猖獗，劫掠过往行商。斩狼二十，取狼王左耳为凭。', '斩妖', '普通', '筑基', 10, 300, 20, NULL, '⚔️', 1, 321, '2026-11-18 08:58:54');
INSERT INTO `quest` VALUES (2, 'sect', NULL, '夜探万剑坟场斩剑灵', '坟场剑灵夜半出鞘伤人。入得进去，斩得剑灵三尊，归来者皆道中之人。', '斩妖', '困难', '金丹', 5, 800, 60, NULL, '🗡️', 1, 150, '2026-11-18 08:58:54');
INSERT INTO `quest` VALUES (3, 'sect', NULL, '讨伐沉渊魔蛟', '沉渊之底魔蛟苏醒，掀翻渔船七十二。此任务九死一生，性命自负，宗门不收尸。', '斩妖', '地狱', '元婴', 3, 2000, 200, NULL, '🐉', 1, 21, '2026-11-18 08:58:54');
INSERT INTO `quest` VALUES (4, 'sect', NULL, '幽冥鬼市购破境丹', '鬼市子时开市，丹价一日三涨。替宗主购得破境丹两枚，真伪自辨，吃亏自负。', '夺宝', '普通', '筑基', 8, 350, 30, NULL, '⚗️', 1, 261, '2026-11-18 08:58:54');
INSERT INTO `quest` VALUES (5, 'sect', NULL, '万剑坟场拾遗残剑', '剑冢边缘偶有残剑浮土而出。拾得三柄有灵残剑，上缴藏经阁即可。', '夺宝', '简单', '炼气', 20, 150, 10, NULL, '⚒️', 1, 412, '2026-11-18 08:58:54');
INSERT INTO `quest` VALUES (6, 'sect', NULL, '护送丹车队过乱星岭', '炼丹堂三车血参要过乱星岭，岭上散修劫道成风。人货俱全者，赏。', '护送', '普通', '筑基', 6, 400, 25, NULL, '🛡️', 1, 191, '2026-11-18 08:58:54');
INSERT INTO `quest` VALUES (7, 'sect', NULL, '护送新弟子入宗', '山下接引八名记名弟子入宗。要求：人不丢，心不歪，路上不许讲鬼故事。', '护送', '简单', '炼气', 20, 100, 5, NULL, '🧭', 1, 526, '2026-11-18 08:58:54');
INSERT INTO `quest` VALUES (8, 'sect', NULL, '为炼丹堂采百年血参', '断魂崖阴面生百年血参七株，须寅时采摘，日头一出便枯。', '炼丹', '简单', '炼气', 15, 120, 8, NULL, '🌿', 1, 481, '2026-11-18 08:58:54');
INSERT INTO `quest` VALUES (9, 'sect', NULL, '炼制三炉回春丹', '丹房拨药材若干，成丹三炉。炸炉者扣当月例钱，成丹者丹堂记功。', '炼丹', '普通', '筑基', 10, 450, 35, NULL, '🔥', 1, 231, '2026-11-18 08:58:54');
INSERT INTO `quest` VALUES (10, 'sect', NULL, '寻找失落的化神诀残页', '化神诀下半卷失踪百年，线索只有一句：剑鸣最弱时，向东南坡去。', '寻物', '困难', '金丹', 4, 700, 80, NULL, '📜', 1, 88, '2026-11-18 08:58:54');
INSERT INTO `quest` VALUES (11, 'sect', NULL, '寻回走失的噬魂兽', '执法堂豢养的噬魂兽趁夜出逃，会学人哭。找回者赏，被吓哭者不赏。', '寻物', '普通', '筑基', 10, 300, 20, NULL, '🐺', 1, 211, '2026-11-18 08:58:54');
INSERT INTO `quest` VALUES (12, 'sect', NULL, '罚扫藏经阁三月', '自领此任者，须是触犯戒律以功抵过之身。扫帚自备，藏经阁长老验收。', '戒律', '简单', '炼气', 3, 80, 3, NULL, '🧹', 1, 68, '2026-11-18 08:58:54');
INSERT INTO `quest` VALUES (16, 'personal', '赤炎老祖', '寻九叶凤凰草', '炼一炉自用丹缺一味主药。九叶凤凰草，叶背带火纹者为真。找到即刻交割，一手草一手宝。', '炼丹', '普通', '筑基', 2, 0, 0, '百年血参两株', '🌿', 1, 95, '2026-11-18 08:58:54');
INSERT INTO `quest` VALUES (17, 'personal', '墨鸦', '取回坠入万蛇窟的佩剑', '执法堂制式魔剑坠崖，剑通灵性，认主不认贼。取得原剑归还者，另有谢礼。', '寻物', '困难', '金丹', 1, 0, 0, '上古剑丸·青蚀', '⚔️', 1, 37, '2026-11-18 08:58:54');
INSERT INTO `quest` VALUES (18, 'personal', '苏九黎', '心魔幻阵陪练', '卡在第七层三个月了，需要一位道友陪我进幻阵走一遍。要求：道心稳固，见故人不至于当场泪崩。', '其它', '普通', '筑基', 3, 0, 0, '千机堂秘制安神香十支', '🌫️', 1, 120, '2026-11-18 08:58:54');
INSERT INTO `quest` VALUES (19, 'personal', '千面魔君', '辨认真伪魔宗古图', '得一残图，真伪难辨。持图去鬼市需一位懂古篆的道友随行鉴定。真图者，谢礼从优。', '寻物', '困难', '金丹', 1, 0, 0, '魔宗秘藏古图（若为真）', '🗺️', 1, 42, '2026-11-18 08:58:54');
INSERT INTO `quest` VALUES (20, 'personal', '玉面罗刹', '血煞堂外哨换防三日', '本堂外哨连值日久，寻三位道友替岗三日。只求尽责，不求勇武。', '护送', '简单', '炼气', 3, 0, 0, '血煞堂护身符一枚', '🛡️', 1, 210, '2026-11-18 08:58:54');
INSERT INTO `quest` VALUES (21, 'personal', '阿蛮', '寻会讲故事的道友', '藏经阁扫地太闷。寻一位会讲志怪故事的道友，每日酉时来扫帚堆边说书半个时辰。', '其它', '简单', '炼气', 1, 0, 0, '阿蛮娘亲手做的酱肘子（管够）', '🍖', 1, 66, '2026-11-18 08:58:54');

-- ----------------------------
-- Table structure for search_log
-- ----------------------------
DROP TABLE IF EXISTS `search_log`;
CREATE TABLE `search_log`  (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '主键，自增',
  `keyword` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT '搜索关键词',
  `category_id` bigint NULL DEFAULT NULL COMMENT '分类过滤条件（可空）',
  `result_count` int NOT NULL DEFAULT 0 COMMENT '本次结果条数',
  `username` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NULL DEFAULT NULL COMMENT '发起搜索的用户（可空）',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '搜索时间',
  PRIMARY KEY (`id`) USING BTREE,
  INDEX `idx_keyword`(`keyword` ASC) USING BTREE,
  INDEX `idx_create_time`(`create_time` ASC) USING BTREE
) ENGINE = InnoDB CHARACTER SET = utf8mb4 COLLATE = utf8mb4_general_ci COMMENT = '首页搜索日志表' ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of search_log
-- ----------------------------

-- ----------------------------
-- Table structure for sect_member
-- ----------------------------
DROP TABLE IF EXISTS `sect_member`;
CREATE TABLE `sect_member`  (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '主键',
  `name` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT '道号',
  `realm` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT '境界',
  `title` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NULL DEFAULT NULL COMMENT '称号/职位',
  `hall` varchar(30) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NULL DEFAULT NULL COMMENT '所属堂口',
  `power` bigint NOT NULL DEFAULT 0 COMMENT '战力',
  `contribution` bigint NOT NULL DEFAULT 0 COMMENT '宗门贡献',
  `icon` varchar(16) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NULL DEFAULT NULL COMMENT '头像 emoji',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '入门时间',
  PRIMARY KEY (`id`) USING BTREE,
  UNIQUE INDEX `uk_member_name`(`name` ASC) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 16 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_general_ci COMMENT = '宗门榜·弟子名录' ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of sect_member
-- ----------------------------
INSERT INTO `sect_member` VALUES (1, '血无常', '魔尊', '宗主', '主殿', 9999999, 999999, '😈', '2026-11-18 08:58:54');
INSERT INTO `sect_member` VALUES (2, '阎罗娘子', '渡劫', '副宗主', '血煞堂', 8800000, 620000, '🌙', '2026-11-18 08:58:54');
INSERT INTO `sect_member` VALUES (3, '白骨真人', '渡劫', '执法长老', '执法堂', 7600000, 540000, '💀', '2026-11-18 08:58:54');
INSERT INTO `sect_member` VALUES (4, '千面魔君', '大乘', '内务长老', '千机堂', 5900000, 410000, '🎭', '2026-11-18 08:58:54');
INSERT INTO `sect_member` VALUES (5, '幽冥子', '大乘', '长老', '幽冥堂', 5200000, 380000, '🌑', '2026-11-18 08:58:54');
INSERT INTO `sect_member` VALUES (6, '玉面罗刹', '合体', '堂主', '血煞堂', 3600000, 260000, '🌺', '2026-11-18 08:58:54');
INSERT INTO `sect_member` VALUES (7, '赤炎老祖', '合体', '丹殿长老', '炼丹堂', 3300000, 245000, '🔥', '2026-11-18 08:58:54');
INSERT INTO `sect_member` VALUES (8, '噬魂叟', '炼虚', '长老', '幽冥堂', 2100000, 180000, '👁️', '2026-11-18 08:58:54');
INSERT INTO `sect_member` VALUES (9, '墨鸦', '炼虚', '首席弟子', '执法堂', 1800000, 160000, '🐦', '2026-11-18 08:58:54');
INSERT INTO `sect_member` VALUES (10, '苏九黎', '化神', '内门弟子', '千机堂', 900000, 95000, '🦋', '2026-11-18 08:58:54');
INSERT INTO `sect_member` VALUES (11, '谢无咎', '化神', '外门弟子', '血煞堂', 850000, 88000, '⚔️', '2026-11-18 08:58:54');
INSERT INTO `sect_member` VALUES (12, '阿蛮', '金丹', '记名弟子', '炼丹堂', 260000, 30000, '🍖', '2026-11-18 08:58:54');

-- ----------------------------
-- Table structure for user
-- ----------------------------
DROP TABLE IF EXISTS `user`;
CREATE TABLE `user`  (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '主键，自增',
  `username` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT '用户名（3-20 位字母/数字/下划线，唯一）',
  `password` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT '密码，MD5 32 位十六进制存储',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`) USING BTREE,
  UNIQUE INDEX `uk_username`(`username` ASC) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 4 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_general_ci COMMENT = '用户表' ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of user
-- ----------------------------
INSERT INTO `user` VALUES (1, 'admin', 'e10adc3949ba59abbe56e057f20f883e', '2026-11-18 08:58:54', '2026-11-18 08:58:54');
INSERT INTO `user` VALUES (2, 'test', 'e10adc3949ba59abbe56e057f20f883e', '2026-11-18 08:58:54', '2026-11-18 08:58:54');
INSERT INTO `user` VALUES (3, 'ywh', '99a541b1767705fc56501698fb871e5f', '2026-11-18 09:01:59', '2026-11-18 09:01:59');

-- ----------------------------
-- Table structure for user_content
-- ----------------------------
DROP TABLE IF EXISTS `user_content`;
CREATE TABLE `user_content`  (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '主键',
  `user_id` bigint NOT NULL COMMENT '所属用户',
  `content_id` bigint NOT NULL COMMENT '内容条目 id',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '收藏时间',
  PRIMARY KEY (`id`) USING BTREE,
  UNIQUE INDEX `uk_user_content`(`user_id` ASC, `content_id` ASC) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 257 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_general_ci COMMENT = '用户个人副本/收藏表' ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of user_content
-- ----------------------------
INSERT INTO `user_content` VALUES (1, 2, 1, '2026-11-18 08:58:54');
INSERT INTO `user_content` VALUES (2, 2, 166, '2026-11-18 08:58:54');
INSERT INTO `user_content` VALUES (3, 2, 167, '2026-11-18 08:58:54');
INSERT INTO `user_content` VALUES (4, 2, 168, '2026-11-18 08:58:54');
INSERT INTO `user_content` VALUES (5, 2, 169, '2026-11-18 08:58:54');
INSERT INTO `user_content` VALUES (6, 2, 170, '2026-11-18 08:58:54');
INSERT INTO `user_content` VALUES (7, 2, 171, '2026-11-18 08:58:54');
INSERT INTO `user_content` VALUES (8, 2, 172, '2026-11-18 08:58:54');
INSERT INTO `user_content` VALUES (9, 2, 173, '2026-11-18 08:58:54');
INSERT INTO `user_content` VALUES (10, 2, 174, '2026-11-18 08:58:54');
INSERT INTO `user_content` VALUES (11, 2, 175, '2026-11-18 08:58:54');
INSERT INTO `user_content` VALUES (12, 2, 248, '2026-11-18 08:58:54');
INSERT INTO `user_content` VALUES (13, 2, 2, '2026-11-18 08:58:54');
INSERT INTO `user_content` VALUES (14, 2, 16, '2026-11-18 08:58:54');
INSERT INTO `user_content` VALUES (15, 2, 17, '2026-11-18 08:58:54');
INSERT INTO `user_content` VALUES (16, 2, 18, '2026-11-18 08:58:54');
INSERT INTO `user_content` VALUES (17, 2, 19, '2026-11-18 08:58:54');
INSERT INTO `user_content` VALUES (18, 2, 20, '2026-11-18 08:58:54');
INSERT INTO `user_content` VALUES (19, 2, 21, '2026-11-18 08:58:54');
INSERT INTO `user_content` VALUES (20, 2, 22, '2026-11-18 08:58:54');
INSERT INTO `user_content` VALUES (21, 2, 23, '2026-11-18 08:58:54');
INSERT INTO `user_content` VALUES (22, 2, 24, '2026-11-18 08:58:54');
INSERT INTO `user_content` VALUES (23, 2, 25, '2026-11-18 08:58:54');
INSERT INTO `user_content` VALUES (24, 2, 26, '2026-11-18 08:58:54');
INSERT INTO `user_content` VALUES (25, 2, 27, '2026-11-18 08:58:54');
INSERT INTO `user_content` VALUES (26, 2, 3, '2026-11-18 08:58:54');
INSERT INTO `user_content` VALUES (27, 2, 4, '2026-11-18 08:58:54');
INSERT INTO `user_content` VALUES (28, 2, 31, '2026-11-18 08:58:54');
INSERT INTO `user_content` VALUES (29, 2, 32, '2026-11-18 08:58:54');
INSERT INTO `user_content` VALUES (30, 2, 33, '2026-11-18 08:58:54');
INSERT INTO `user_content` VALUES (31, 2, 34, '2026-11-18 08:58:54');
INSERT INTO `user_content` VALUES (32, 2, 35, '2026-11-18 08:58:54');
INSERT INTO `user_content` VALUES (33, 2, 36, '2026-11-18 08:58:54');
INSERT INTO `user_content` VALUES (34, 2, 37, '2026-11-18 08:58:54');
INSERT INTO `user_content` VALUES (35, 2, 38, '2026-11-18 08:58:54');
INSERT INTO `user_content` VALUES (36, 2, 39, '2026-11-18 08:58:54');
INSERT INTO `user_content` VALUES (37, 2, 40, '2026-11-18 08:58:54');
INSERT INTO `user_content` VALUES (38, 2, 41, '2026-11-18 08:58:54');
INSERT INTO `user_content` VALUES (39, 2, 42, '2026-11-18 08:58:54');
INSERT INTO `user_content` VALUES (40, 2, 5, '2026-11-18 08:58:54');
INSERT INTO `user_content` VALUES (41, 2, 46, '2026-11-18 08:58:54');
INSERT INTO `user_content` VALUES (42, 2, 47, '2026-11-18 08:58:54');
INSERT INTO `user_content` VALUES (43, 2, 48, '2026-11-18 08:58:54');
INSERT INTO `user_content` VALUES (44, 2, 49, '2026-11-18 08:58:54');
INSERT INTO `user_content` VALUES (45, 2, 50, '2026-11-18 08:58:54');
INSERT INTO `user_content` VALUES (46, 2, 51, '2026-11-18 08:58:54');
INSERT INTO `user_content` VALUES (47, 2, 52, '2026-11-18 08:58:54');
INSERT INTO `user_content` VALUES (48, 2, 53, '2026-11-18 08:58:54');
INSERT INTO `user_content` VALUES (49, 2, 54, '2026-11-18 08:58:54');
INSERT INTO `user_content` VALUES (50, 2, 55, '2026-11-18 08:58:54');
INSERT INTO `user_content` VALUES (51, 2, 56, '2026-11-18 08:58:54');
INSERT INTO `user_content` VALUES (52, 2, 57, '2026-11-18 08:58:54');
INSERT INTO `user_content` VALUES (53, 2, 181, '2026-11-18 08:58:54');
INSERT INTO `user_content` VALUES (54, 2, 182, '2026-11-18 08:58:54');
INSERT INTO `user_content` VALUES (55, 2, 183, '2026-11-18 08:58:54');
INSERT INTO `user_content` VALUES (56, 2, 184, '2026-11-18 08:58:54');
INSERT INTO `user_content` VALUES (57, 2, 185, '2026-11-18 08:58:54');
INSERT INTO `user_content` VALUES (58, 2, 6, '2026-11-18 08:58:54');
INSERT INTO `user_content` VALUES (59, 2, 61, '2026-11-18 08:58:54');
INSERT INTO `user_content` VALUES (60, 2, 62, '2026-11-18 08:58:54');
INSERT INTO `user_content` VALUES (61, 2, 63, '2026-11-18 08:58:54');
INSERT INTO `user_content` VALUES (62, 2, 64, '2026-11-18 08:58:54');
INSERT INTO `user_content` VALUES (63, 2, 65, '2026-11-18 08:58:54');
INSERT INTO `user_content` VALUES (64, 2, 66, '2026-11-18 08:58:54');
INSERT INTO `user_content` VALUES (65, 2, 67, '2026-11-18 08:58:54');
INSERT INTO `user_content` VALUES (66, 2, 68, '2026-11-18 08:58:54');
INSERT INTO `user_content` VALUES (67, 2, 69, '2026-11-18 08:58:54');
INSERT INTO `user_content` VALUES (68, 2, 70, '2026-11-18 08:58:54');
INSERT INTO `user_content` VALUES (69, 2, 71, '2026-11-18 08:58:54');
INSERT INTO `user_content` VALUES (70, 2, 188, '2026-11-18 08:58:54');
INSERT INTO `user_content` VALUES (71, 2, 189, '2026-11-18 08:58:54');
INSERT INTO `user_content` VALUES (72, 2, 190, '2026-11-18 08:58:54');
INSERT INTO `user_content` VALUES (73, 2, 191, '2026-11-18 08:58:54');
INSERT INTO `user_content` VALUES (74, 2, 192, '2026-11-18 08:58:54');
INSERT INTO `user_content` VALUES (75, 2, 193, '2026-11-18 08:58:54');
INSERT INTO `user_content` VALUES (76, 2, 194, '2026-11-18 08:58:54');
INSERT INTO `user_content` VALUES (77, 2, 195, '2026-11-18 08:58:54');
INSERT INTO `user_content` VALUES (78, 2, 196, '2026-11-18 08:58:54');
INSERT INTO `user_content` VALUES (79, 2, 197, '2026-11-18 08:58:54');
INSERT INTO `user_content` VALUES (80, 2, 198, '2026-11-18 08:58:54');
INSERT INTO `user_content` VALUES (81, 2, 199, '2026-11-18 08:58:54');
INSERT INTO `user_content` VALUES (82, 2, 7, '2026-11-18 08:58:54');
INSERT INTO `user_content` VALUES (83, 2, 76, '2026-11-18 08:58:54');
INSERT INTO `user_content` VALUES (84, 2, 77, '2026-11-18 08:58:54');
INSERT INTO `user_content` VALUES (85, 2, 78, '2026-11-18 08:58:54');
INSERT INTO `user_content` VALUES (86, 2, 79, '2026-11-18 08:58:54');
INSERT INTO `user_content` VALUES (87, 2, 80, '2026-11-18 08:58:54');
INSERT INTO `user_content` VALUES (88, 2, 81, '2026-11-18 08:58:54');
INSERT INTO `user_content` VALUES (89, 2, 82, '2026-11-18 08:58:54');
INSERT INTO `user_content` VALUES (90, 2, 83, '2026-11-18 08:58:54');
INSERT INTO `user_content` VALUES (91, 2, 84, '2026-11-18 08:58:54');
INSERT INTO `user_content` VALUES (92, 2, 85, '2026-11-18 08:58:54');
INSERT INTO `user_content` VALUES (93, 2, 86, '2026-11-18 08:58:54');
INSERT INTO `user_content` VALUES (94, 2, 203, '2026-11-18 08:58:54');
INSERT INTO `user_content` VALUES (95, 2, 204, '2026-11-18 08:58:54');
INSERT INTO `user_content` VALUES (96, 2, 205, '2026-11-18 08:58:54');
INSERT INTO `user_content` VALUES (97, 2, 206, '2026-11-18 08:58:54');
INSERT INTO `user_content` VALUES (98, 2, 207, '2026-11-18 08:58:54');
INSERT INTO `user_content` VALUES (99, 2, 208, '2026-11-18 08:58:54');
INSERT INTO `user_content` VALUES (100, 2, 209, '2026-11-18 08:58:54');
INSERT INTO `user_content` VALUES (101, 2, 210, '2026-11-18 08:58:54');
INSERT INTO `user_content` VALUES (102, 2, 211, '2026-11-18 08:58:54');
INSERT INTO `user_content` VALUES (103, 2, 212, '2026-11-18 08:58:54');
INSERT INTO `user_content` VALUES (104, 2, 213, '2026-11-18 08:58:54');
INSERT INTO `user_content` VALUES (105, 2, 8, '2026-11-18 08:58:54');
INSERT INTO `user_content` VALUES (106, 2, 91, '2026-11-18 08:58:54');
INSERT INTO `user_content` VALUES (107, 2, 92, '2026-11-18 08:58:54');
INSERT INTO `user_content` VALUES (108, 2, 93, '2026-11-18 08:58:54');
INSERT INTO `user_content` VALUES (109, 2, 94, '2026-11-18 08:58:54');
INSERT INTO `user_content` VALUES (110, 2, 95, '2026-11-18 08:58:54');
INSERT INTO `user_content` VALUES (111, 2, 96, '2026-11-18 08:58:54');
INSERT INTO `user_content` VALUES (112, 2, 97, '2026-11-18 08:58:54');
INSERT INTO `user_content` VALUES (113, 2, 98, '2026-11-18 08:58:54');
INSERT INTO `user_content` VALUES (114, 2, 99, '2026-11-18 08:58:54');
INSERT INTO `user_content` VALUES (115, 2, 100, '2026-11-18 08:58:54');
INSERT INTO `user_content` VALUES (116, 2, 101, '2026-11-18 08:58:54');
INSERT INTO `user_content` VALUES (117, 2, 218, '2026-11-18 08:58:54');
INSERT INTO `user_content` VALUES (118, 2, 219, '2026-11-18 08:58:54');
INSERT INTO `user_content` VALUES (119, 2, 220, '2026-11-18 08:58:54');
INSERT INTO `user_content` VALUES (120, 2, 221, '2026-11-18 08:58:54');
INSERT INTO `user_content` VALUES (121, 2, 222, '2026-11-18 08:58:54');
INSERT INTO `user_content` VALUES (122, 2, 223, '2026-11-18 08:58:54');
INSERT INTO `user_content` VALUES (123, 2, 224, '2026-11-18 08:58:54');
INSERT INTO `user_content` VALUES (124, 2, 225, '2026-11-18 08:58:54');
INSERT INTO `user_content` VALUES (125, 2, 226, '2026-11-18 08:58:54');
INSERT INTO `user_content` VALUES (126, 2, 227, '2026-11-18 08:58:54');
INSERT INTO `user_content` VALUES (127, 2, 228, '2026-11-18 08:58:54');
INSERT INTO `user_content` VALUES (128, 2, 229, '2026-11-18 08:58:54');
INSERT INTO `user_content` VALUES (129, 2, 9, '2026-11-18 08:58:54');
INSERT INTO `user_content` VALUES (130, 2, 106, '2026-11-18 08:58:54');
INSERT INTO `user_content` VALUES (131, 2, 107, '2026-11-18 08:58:54');
INSERT INTO `user_content` VALUES (132, 2, 108, '2026-11-18 08:58:54');
INSERT INTO `user_content` VALUES (133, 2, 109, '2026-11-18 08:58:54');
INSERT INTO `user_content` VALUES (134, 2, 110, '2026-11-18 08:58:54');
INSERT INTO `user_content` VALUES (135, 2, 111, '2026-11-18 08:58:54');
INSERT INTO `user_content` VALUES (136, 2, 112, '2026-11-18 08:58:54');
INSERT INTO `user_content` VALUES (137, 2, 113, '2026-11-18 08:58:54');
INSERT INTO `user_content` VALUES (138, 2, 114, '2026-11-18 08:58:54');
INSERT INTO `user_content` VALUES (139, 2, 115, '2026-11-18 08:58:54');
INSERT INTO `user_content` VALUES (140, 2, 116, '2026-11-18 08:58:54');
INSERT INTO `user_content` VALUES (141, 2, 233, '2026-11-18 08:58:54');
INSERT INTO `user_content` VALUES (142, 2, 234, '2026-11-18 08:58:54');
INSERT INTO `user_content` VALUES (143, 2, 235, '2026-11-18 08:58:54');
INSERT INTO `user_content` VALUES (144, 2, 236, '2026-11-18 08:58:54');
INSERT INTO `user_content` VALUES (145, 2, 237, '2026-11-18 08:58:54');
INSERT INTO `user_content` VALUES (146, 2, 238, '2026-11-18 08:58:54');
INSERT INTO `user_content` VALUES (147, 2, 239, '2026-11-18 08:58:54');
INSERT INTO `user_content` VALUES (148, 2, 240, '2026-11-18 08:58:54');
INSERT INTO `user_content` VALUES (149, 2, 241, '2026-11-18 08:58:54');
INSERT INTO `user_content` VALUES (150, 2, 242, '2026-11-18 08:58:54');
INSERT INTO `user_content` VALUES (151, 2, 243, '2026-11-18 08:58:54');
INSERT INTO `user_content` VALUES (152, 2, 244, '2026-11-18 08:58:54');
INSERT INTO `user_content` VALUES (153, 2, 10, '2026-11-18 08:58:54');
INSERT INTO `user_content` VALUES (154, 2, 121, '2026-11-18 08:58:54');
INSERT INTO `user_content` VALUES (155, 2, 122, '2026-11-18 08:58:54');
INSERT INTO `user_content` VALUES (156, 2, 123, '2026-11-18 08:58:54');
INSERT INTO `user_content` VALUES (157, 2, 124, '2026-11-18 08:58:54');
INSERT INTO `user_content` VALUES (158, 2, 125, '2026-11-18 08:58:54');
INSERT INTO `user_content` VALUES (159, 2, 126, '2026-11-18 08:58:54');
INSERT INTO `user_content` VALUES (160, 2, 127, '2026-11-18 08:58:54');
INSERT INTO `user_content` VALUES (161, 2, 128, '2026-11-18 08:58:54');
INSERT INTO `user_content` VALUES (162, 2, 129, '2026-11-18 08:58:54');
INSERT INTO `user_content` VALUES (163, 2, 130, '2026-11-18 08:58:54');
INSERT INTO `user_content` VALUES (164, 2, 131, '2026-11-18 08:58:54');
INSERT INTO `user_content` VALUES (165, 2, 11, '2026-11-18 08:58:54');
INSERT INTO `user_content` VALUES (166, 2, 136, '2026-11-18 08:58:54');
INSERT INTO `user_content` VALUES (167, 2, 137, '2026-11-18 08:58:54');
INSERT INTO `user_content` VALUES (168, 2, 138, '2026-11-18 08:58:54');
INSERT INTO `user_content` VALUES (169, 2, 139, '2026-11-18 08:58:54');
INSERT INTO `user_content` VALUES (170, 2, 140, '2026-11-18 08:58:54');
INSERT INTO `user_content` VALUES (171, 2, 141, '2026-11-18 08:58:54');
INSERT INTO `user_content` VALUES (172, 2, 142, '2026-11-18 08:58:54');
INSERT INTO `user_content` VALUES (173, 2, 143, '2026-11-18 08:58:54');
INSERT INTO `user_content` VALUES (174, 2, 144, '2026-11-18 08:58:54');
INSERT INTO `user_content` VALUES (175, 2, 12, '2026-11-18 08:58:54');
INSERT INTO `user_content` VALUES (176, 2, 151, '2026-11-18 08:58:54');
INSERT INTO `user_content` VALUES (177, 2, 152, '2026-11-18 08:58:54');
INSERT INTO `user_content` VALUES (178, 2, 153, '2026-11-18 08:58:54');
INSERT INTO `user_content` VALUES (179, 2, 154, '2026-11-18 08:58:54');
INSERT INTO `user_content` VALUES (180, 2, 155, '2026-11-18 08:58:54');
INSERT INTO `user_content` VALUES (181, 2, 156, '2026-11-18 08:58:54');
INSERT INTO `user_content` VALUES (182, 2, 157, '2026-11-18 08:58:54');
INSERT INTO `user_content` VALUES (183, 2, 158, '2026-11-18 08:58:54');
INSERT INTO `user_content` VALUES (184, 2, 159, '2026-11-18 08:58:54');
INSERT INTO `user_content` VALUES (185, 2, 160, '2026-11-18 08:58:54');

-- ----------------------------
-- Table structure for user_profile
-- ----------------------------
DROP TABLE IF EXISTS `user_profile`;
CREATE TABLE `user_profile`  (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '主键，自增',
  `username` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT '用户名（唯一，关联 user.username）',
  `nickname` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT '道号（展示昵称）',
  `icon` varchar(8) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NULL DEFAULT NULL COMMENT '头像 emoji（后端默认 ?‍?）',
  `realm` varchar(10) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NULL DEFAULT '炼气' COMMENT '境界：炼气~魔尊',
  `cultivation` bigint NOT NULL DEFAULT 0 COMMENT '修为值（魔功殿修炼累计）',
  `hall` varchar(10) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NULL DEFAULT '血煞堂' COMMENT '所属堂口',
  `bio` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NULL DEFAULT '' COMMENT '道语签名',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`) USING BTREE,
  UNIQUE INDEX `uk_username`(`username` ASC) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 5 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_general_ci COMMENT = '用户个人档案表（洞府）' ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of user_profile
-- ----------------------------
INSERT INTO `user_profile` VALUES (1, 'ywh', 'ywh', '🧙', '筑基', 2037, '血煞堂', '初入魔宗，道心未定。', '2026-11-18 09:02:09', '2026-11-18 09:45:17');
INSERT INTO `user_profile` VALUES (2, 'admin', 'admin', '🧙', '筑基', 2824, '血煞堂', '初入魔宗，道心未定。', '2026-11-18 09:21:57', '2026-11-18 09:52:58');
INSERT INTO `user_profile` VALUES (3, '玉面罗刹', '玉面罗刹', '🧙', '炼气', 0, '血煞堂', '初入魔宗，道心未定。', '2026-11-18 09:51:33', '2026-11-18 09:51:33');
INSERT INTO `user_profile` VALUES (4, '阿蛮', '阿蛮', '🧙', '炼气', 0, '血煞堂', '初入魔宗，道心未定。', '2026-11-18 09:52:58', '2026-11-18 09:52:58');

-- ----------------------------
-- Table structure for user_quest
-- ----------------------------
DROP TABLE IF EXISTS `user_quest`;
CREATE TABLE `user_quest`  (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '主键',
  `username` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT '接取人（关联 user.username）',
  `quest_id` bigint NOT NULL COMMENT '任务 id（关联 quest.id）',
  `status` tinyint NOT NULL DEFAULT 0 COMMENT '状态：0 进行中 / 1 已完成 / 2 已放弃',
  `reward_contribution` bigint NOT NULL DEFAULT 0 COMMENT '完成时所得贡献值快照',
  `reward_stones` bigint NOT NULL DEFAULT 0 COMMENT '完成时所得灵石快照',
  `reward_item` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NULL DEFAULT NULL COMMENT '完成时所得物品快照（个人悬赏）',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '接取时间',
  `finish_time` datetime NULL DEFAULT NULL COMMENT '完成 / 放弃时间',
  PRIMARY KEY (`id`) USING BTREE,
  INDEX `idx_uq_user`(`username` ASC) USING BTREE,
  INDEX `idx_uq_quest`(`quest_id` ASC) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 17 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_general_ci COMMENT = '任务阁·弟子接取记录' ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of user_quest
-- ----------------------------
INSERT INTO `user_quest` VALUES (1, 'admin', 5, 1, 150, 10, NULL, '2026-11-18 09:24:13', '2026-11-18 09:24:13');
INSERT INTO `user_quest` VALUES (2, 'admin', 7, 1, 100, 5, NULL, '2026-11-18 09:24:26', '2026-11-18 09:24:27');
INSERT INTO `user_quest` VALUES (3, 'admin', 8, 1, 120, 8, NULL, '2026-11-18 09:24:27', '2026-11-18 09:24:27');
INSERT INTO `user_quest` VALUES (4, 'admin', 5, 1, 150, 10, NULL, '2026-11-18 09:24:28', '2026-11-18 09:24:28');
INSERT INTO `user_quest` VALUES (5, 'admin', 1, 1, 300, 20, NULL, '2026-11-18 09:24:28', '2026-11-18 09:24:28');
INSERT INTO `user_quest` VALUES (6, 'admin', 4, 1, 350, 30, NULL, '2026-11-18 09:24:29', '2026-11-18 09:24:29');
INSERT INTO `user_quest` VALUES (7, 'admin', 9, 1, 450, 35, NULL, '2026-11-18 09:24:30', '2026-11-18 09:24:30');
INSERT INTO `user_quest` VALUES (8, 'admin', 11, 1, 300, 20, NULL, '2026-11-18 09:24:30', '2026-11-18 09:24:30');
INSERT INTO `user_quest` VALUES (9, 'admin', 6, 1, 400, 25, NULL, '2026-11-18 09:24:31', '2026-11-18 09:24:31');
INSERT INTO `user_quest` VALUES (10, 'admin', 12, 1, 80, 3, NULL, '2026-11-18 09:24:33', '2026-11-18 09:24:33');
INSERT INTO `user_quest` VALUES (11, 'ywh', 7, 2, 0, 0, NULL, '2026-11-18 09:28:02', '2026-11-18 09:28:14');
INSERT INTO `user_quest` VALUES (12, 'ywh', 7, 1, 100, 5, NULL, '2026-11-18 09:33:26', '2026-11-18 09:34:46');
INSERT INTO `user_quest` VALUES (13, 'admin', 7, 1, 100, 5, NULL, '2026-11-18 09:33:32', '2026-11-18 09:33:33');
INSERT INTO `user_quest` VALUES (14, 'admin', 12, 0, 0, 0, NULL, '2026-11-18 09:34:25', NULL);
INSERT INTO `user_quest` VALUES (15, 'admin', 7, 1, 100, 5, NULL, '2026-11-18 09:35:13', '2026-11-18 09:35:28');
INSERT INTO `user_quest` VALUES (16, 'ywh', 7, 1, 100, 5, NULL, '2026-11-18 09:45:10', '2026-11-18 09:45:13');

-- ----------------------------
-- Table structure for user_skill
-- ----------------------------
DROP TABLE IF EXISTS `user_skill`;
CREATE TABLE `user_skill`  (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '主键',
  `username` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT '参悟人（关联 user.username）',
  `item_id` bigint NOT NULL COMMENT '功法条目 id（关联 content_item.id）',
  `cost` bigint NOT NULL DEFAULT 0 COMMENT '参悟时消耗的贡献值快照',
  `title` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT '功法名快照',
  `grade` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NULL DEFAULT NULL COMMENT '品阶快照',
  `icon` varchar(16) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NULL DEFAULT NULL COMMENT '图标快照',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '参悟时间',
  PRIMARY KEY (`id`) USING BTREE,
  INDEX `idx_us_user`(`username` ASC) USING BTREE,
  INDEX `idx_us_item`(`item_id` ASC) USING BTREE
) ENGINE = InnoDB CHARACTER SET = utf8mb4 COLLATE = utf8mb4_general_ci COMMENT = '功法阁·弟子参悟记录' ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of user_skill
-- ----------------------------

SET FOREIGN_KEY_CHECKS = 1;
