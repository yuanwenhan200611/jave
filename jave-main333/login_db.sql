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

 Date: 09/11/2026 11:58:32
*/

SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;

-- ----------------------------
-- Table structure for category
-- ----------------------------
DROP TABLE IF EXISTS `category`;
CREATE TABLE `category`  (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '涓婚敭锛岃嚜澧',
  `name` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT '鍒嗙被鍚嶇О',
  `parent_id` bigint NOT NULL DEFAULT 0 COMMENT '鐖跺垎绫?id锛? 琛ㄧず椤剁骇',
  `level` int NOT NULL DEFAULT 1 COMMENT '灞傜骇锛? 椤剁骇 / 2 浜岀骇 / 3 涓夌骇...',
  `sort` int NOT NULL DEFAULT 0 COMMENT '鎺掑簭鍊硷紝瓒婂皬瓒婇潬鍓',
  `icon` varchar(16) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NULL DEFAULT NULL COMMENT '鍥炬爣锛坋moji锛',
  `description` varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NULL DEFAULT NULL COMMENT '鍒嗙被鎻忚堪',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '鍒涘缓鏃堕棿',
  PRIMARY KEY (`id`) USING BTREE,
  INDEX `idx_parent`(`parent_id` ASC) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 18 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_general_ci COMMENT = '棣栭〉鍒嗙骇鍒嗙被琛' ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of category
-- ----------------------------
INSERT INTO `category` VALUES (1, '功法', 0, 1, 1, '📜', '诸天功法，皆可习练', '2026-11-09 10:54:53');
INSERT INTO `category` VALUES (2, '秘境', 0, 1, 2, '🗺️', '无尽秘境，待你开辟', '2026-11-09 10:54:53');
INSERT INTO `category` VALUES (3, '丹药', 0, 1, 3, '⚗️', '逆天改命之丹', '2026-11-09 10:54:53');
INSERT INTO `category` VALUES (4, '法宝', 0, 1, 4, '🗡️', '神兵利器，掌中乾坤', '2026-11-09 10:54:53');
INSERT INTO `category` VALUES (5, '灵兽', 0, 1, 5, '🐉', '万兽臣服，皆入麾下', '2026-11-09 10:54:53');
INSERT INTO `category` VALUES (6, '典籍', 0, 1, 6, '📖', '万载传承，尽数收录', '2026-11-09 10:54:53');
INSERT INTO `category` VALUES (8, '炼体功法', 1, 2, 1, '💪', '淬体炼骨，根基之道', '2026-11-09 10:54:53');
INSERT INTO `category` VALUES (9, '心法口诀', 1, 2, 2, '🧘', '凝聚灵力，运转周天', '2026-11-09 10:54:53');
INSERT INTO `category` VALUES (10, '上古秘境', 2, 2, 1, '🗿', '洪荒遗地，机缘无数', '2026-11-09 10:54:53');
INSERT INTO `category` VALUES (11, '幻境试炼', 2, 2, 2, '🌫️', '心魔考验，突破之地', '2026-11-09 10:54:53');
INSERT INTO `category` VALUES (12, '回春丹', 3, 2, 1, '🌿', '疗伤圣药', '2026-11-09 10:54:53');
INSERT INTO `category` VALUES (13, '破境丹', 3, 2, 2, '⚡', '助修士破除瓶颈', '2026-11-09 10:54:53');
INSERT INTO `category` VALUES (14, '攻击法宝', 4, 2, 1, '⚔️', '斩敌破阵', '2026-11-09 10:54:53');
INSERT INTO `category` VALUES (15, '防御法宝', 4, 2, 2, '🛡️', '护体保命', '2026-11-09 10:54:53');
INSERT INTO `category` VALUES (16, '飞行灵兽', 5, 2, 1, '🦅', '翱翔九天', '2026-11-09 10:54:53');
INSERT INTO `category` VALUES (17, '守护灵兽', 5, 2, 2, '🐺', '忠心护主', '2026-11-09 10:54:53');

-- ----------------------------
-- Table structure for content_item
-- ----------------------------
DROP TABLE IF EXISTS `content_item`;
CREATE TABLE `content_item`  (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '涓婚敭锛岃嚜澧',
  `title` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT '鏍囬?',
  `description` varchar(500) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NULL DEFAULT NULL COMMENT '绠?粙',
  `category_id` bigint NOT NULL COMMENT '鎵?睘鍒嗙被 id锛堝彲涓轰换鎰忓眰绾у垎绫伙級',
  `grade` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NULL DEFAULT NULL COMMENT '鍝侀樁锛堝ぉ闃?鍦伴樁/鐜勯樁/榛勯樁绛夛級',
  `icon` varchar(16) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NULL DEFAULT NULL COMMENT '鍥炬爣锛坋moji锛屽睍绀虹敤锛',
  `view_count` bigint NOT NULL DEFAULT 0 COMMENT '娴忚?閲',
  `status` tinyint NOT NULL DEFAULT 1 COMMENT '鐘舵?锛? 涓婃灦 / 0 涓嬫灦',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '鍒涘缓鏃堕棿',
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '鏇存柊鏃堕棿',
  PRIMARY KEY (`id`) USING BTREE,
  INDEX `idx_category`(`category_id` ASC) USING BTREE,
  INDEX `idx_title`(`title` ASC) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 162 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_general_ci COMMENT = '棣栭〉鍐呭?鏉＄洰琛' ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of content_item
-- ----------------------------
INSERT INTO `content_item` VALUES (1, '金刚不坏身', '以周身三百六十骨节为炉，日夜锤打，皮肉如金石，刀斧难伤分毫。', 8, '天阶', '🗿', 9120, 1, '2026-11-09 10:54:53', '2026-11-09 10:54:53');
INSERT INTO `content_item` VALUES (2, '血煞炼骨术', '引凶兽精血入骨，骨中生煞，一击可碎山门。然煞气反噬，心如擂鼓。', 8, '地阶', '🩸', 7840, 1, '2026-11-09 10:54:53', '2026-11-09 10:54:53');
INSERT INTO `content_item` VALUES (3, '春雷淬身诀', '每岁惊蛰引天雷淬体，痛极则生，九淬之后血肉自生雷纹。', 8, '玄阶', '⚡', 6210, 1, '2026-11-09 10:54:53', '2026-11-09 10:54:53');
INSERT INTO `content_item` VALUES (4, '不周山印', '以身作山，重逾万钧，气机一动便压塌一方天地。', 8, '天阶', '⛰️', 8760, 1, '2026-11-09 10:54:53', '2026-11-09 10:54:53');
INSERT INTO `content_item` VALUES (5, '玄龟息法', '吞吐迟缓如龟，可闭气三月不死，肉身生鳞，万毒不侵。', 8, '黄阶', '🐢', 4320, 1, '2026-11-09 10:54:53', '2026-11-09 10:54:53');
INSERT INTO `content_item` VALUES (6, '焚身决', '以真火自焚其身，焚去凡胎浊骨，浴火一遭，胜修十年苦功。', 8, '玄阶', '🔥', 5680, 1, '2026-11-09 10:54:53', '2026-11-09 10:54:53');
INSERT INTO `content_item` VALUES (7, '冰魄寒体', '久居极北寒渊，以身饲冰，血凝成霜，举手投足皆是万里冰封。', 8, '地阶', '❄️', 7010, 1, '2026-11-09 10:54:53', '2026-11-09 10:54:53');
INSERT INTO `content_item` VALUES (8, '万木回春体', '借草木生机淬体，断肢可续，重伤自愈，唯惧烈火焚林。', 8, '黄阶', '🌿', 3890, 1, '2026-11-09 10:54:53', '2026-11-09 10:54:53');
INSERT INTO `content_item` VALUES (9, '修罗战体', '以杀养体，每斩一敌肉躯便厚重一分，杀满千敌可徒手撕蛟。', 8, '天阶', '🗡️', 9451, 1, '2026-11-09 10:54:53', '2026-11-09 11:54:23');
INSERT INTO `content_item` VALUES (10, '紫府真形', '观想紫府神宫，将肉身炼作道场，内蕴一方小世界，坚不可摧。', 8, '地阶', '🔮', 7260, 1, '2026-11-09 10:54:53', '2026-11-09 10:54:53');
INSERT INTO `content_item` VALUES (11, '龙象大力诀', '每日子时扛石磨骨，积九牛二虎之力于双臂，力可撼岳。', 8, '玄阶', '🐘', 5480, 1, '2026-11-09 10:54:53', '2026-11-09 10:54:53');
INSERT INTO `content_item` VALUES (12, '枯荣禅体', '一念枯、一念荣，枯时如朽木可受万击，荣时生机暴涨还以重拳。', 8, '地阶', '🍂', 6730, 1, '2026-11-09 10:54:53', '2026-11-09 10:54:53');
INSERT INTO `content_item` VALUES (16, '太虚周天诀', '一念引气走周天，三百六十窍窍窍皆通，吐纳之间自成天地。', 9, '天阶', '🌀', 9341, 1, '2026-11-09 10:54:53', '2026-11-09 11:55:27');
INSERT INTO `content_item` VALUES (17, '清心明性经', '魔宗弟子入门第一课，斩杂念、定道心，心魔不生则万法可修。', 9, '黄阶', '🪷', 4120, 1, '2026-11-09 10:54:53', '2026-11-09 10:54:53');
INSERT INTO `content_item` VALUES (18, '紫气东来诀', '寅时面东而坐，纳第一缕紫气入丹田，修至圆满则气血如朝霞。', 9, '地阶', '🌅', 7680, 1, '2026-11-09 10:54:53', '2026-11-09 10:54:53');
INSERT INTO `content_item` VALUES (19, '九幽噬灵法', '以神魂为钩，吞噬残魂补己身，神识远胜同阶，然夜夜闻哭声。', 9, '天阶', '👁️', 8890, 1, '2026-11-09 10:54:53', '2026-11-09 10:54:53');
INSERT INTO `content_item` VALUES (20, '无相真空咒', '心中无一物，万法皆是空。敌之神通落于身上，如投石入水。', 9, '玄阶', '🕳️', 5970, 1, '2026-11-09 10:54:53', '2026-11-09 10:54:53');
INSERT INTO `content_item` VALUES (21, '两仪归元诀', '阴阳二气交抱轮转，攻守一体，动若奔雷，静若古井。', 9, '地阶', '☯️', 7420, 1, '2026-11-09 10:54:53', '2026-11-09 10:54:53');
INSERT INTO `content_item` VALUES (22, '燃灯续命篇', '以自身寿元为薪，点燃一盏心灯，灯不灭则命不绝。', 9, '玄阶', '🕯️', 5630, 1, '2026-11-09 10:54:53', '2026-11-09 10:54:53');
INSERT INTO `content_item` VALUES (23, '万象归心图', '观想三千世界尽入方寸，神识铺开可察方圆百里草木之动。', 9, '玄阶', '🌌', 6080, 1, '2026-11-09 10:54:53', '2026-11-09 10:54:53');
INSERT INTO `content_item` VALUES (24, '北冥蓄灵诀', '气海如北冥之渊，蓄灵十倍于常修，久战不竭。', 9, '地阶', '🌊', 7150, 1, '2026-11-09 10:54:53', '2026-11-09 10:54:53');
INSERT INTO `content_item` VALUES (25, '一念千年诀', '识海自成一界，外界一瞬，识海已参悟千载，闭关破境之神物。', 9, '天阶', '⏳', 9010, 1, '2026-11-09 10:54:53', '2026-11-09 10:54:53');
INSERT INTO `content_item` VALUES (26, '寒潭静照法', '心如寒潭映月，照见己身诸般妄念，妄念一散，灵台自清。', 9, '玄阶', '🌙', 5340, 1, '2026-11-09 10:54:53', '2026-11-09 10:54:53');
INSERT INTO `content_item` VALUES (27, '劫火焚心经', '每夜观想劫火焚心，焚去怯懦，此后临阵不惧、赴死不退。', 9, '地阶', '🔥', 6890, 1, '2026-11-09 10:54:53', '2026-11-09 10:54:53');
INSERT INTO `content_item` VALUES (31, '不周山墟', '天柱折处，残峰悬空，山腹藏有上古神魔断骨，机缘与杀机并存。', 10, '天阶', '⛰️', 9560, 1, '2026-11-09 10:54:53', '2026-11-09 10:54:53');
INSERT INTO `content_item` VALUES (32, '归墟海眼', '万水归流之尽头，海水倒灌天穹，深处可闻先民钟鸣。', 10, '天阶', '🌊', 9280, 1, '2026-11-09 10:54:53', '2026-11-09 10:54:53');
INSERT INTO `content_item` VALUES (33, '枯骨荒原', '白骨堆积成丘，风过如万人低语，昼夜颠倒，尸傀游荡。', 10, '玄阶', '🦴', 6340, 1, '2026-11-09 10:54:53', '2026-11-09 10:54:53');
INSERT INTO `content_item` VALUES (34, '昆仑遗宫', '雪线之上的白玉宫阙，门前立无面石像，擅入者皆成石俑。', 10, '地阶', '🏯', 8120, 1, '2026-11-09 10:54:53', '2026-11-09 10:54:53');
INSERT INTO `content_item` VALUES (35, '落星谷', '千年前天外陨星坠此，谷中石皆有星纹，触之可窥一线天机。', 10, '玄阶', '☄️', 5820, 1, '2026-11-09 10:54:53', '2026-11-09 10:54:53');
INSERT INTO `content_item` VALUES (36, '幽冥鬼市', '子时方现的街市，鬼商贩卖活人不敢要的东西，只收寿元。', 10, '地阶', '🏮', 7630, 1, '2026-11-09 10:54:53', '2026-11-09 10:54:53');
INSERT INTO `content_item` VALUES (37, '万剑坟场', '上古剑修尽殁于此，残剑插地如林，剑气未散，日夜铮鸣。', 10, '天阶', '⚔️', 9740, 1, '2026-11-09 10:54:53', '2026-11-09 10:54:53');
INSERT INTO `content_item` VALUES (38, '沉舟海窟', '千艘古船沉于海底，船中货物保存如新，唯无人敢取。', 10, '玄阶', '🚢', 5980, 1, '2026-11-09 10:54:53', '2026-11-09 10:54:53');
INSERT INTO `content_item` VALUES (39, '雷泽古林', '古木参天皆被雷火焚成焦炭，每逢雨夜雷声复起。', 10, '地阶', '🌩️', 7180, 1, '2026-11-09 10:54:53', '2026-11-09 10:54:53');
INSERT INTO `content_item` VALUES (40, '血月荒祠', '每三十年血月临空，祠堂自开，祭品便是闯入者。', 10, '天阶', '🌕', 8920, 1, '2026-11-09 10:54:53', '2026-11-09 10:54:53');
INSERT INTO `content_item` VALUES (41, '镜湖倒影界', '湖面映出的世界，与真实世界镜像颠倒，入者易迷失归途。', 10, '玄阶', '🪞', 6150, 1, '2026-11-09 10:54:53', '2026-11-09 10:54:53');
INSERT INTO `content_item` VALUES (42, '天梯石阶', '九万九千级石阶通往云端，每一级都记着一位陨落者的名字。', 10, '地阶', '🪜', 7841, 1, '2026-11-09 10:54:53', '2026-11-09 11:54:25');
INSERT INTO `content_item` VALUES (46, '心魔幻阵', '闯过者道心通明，闯不过者道基尽毁，阵中映出的全是自己最怕的模样。', 11, '玄阶', '🌫️', 8210, 1, '2026-11-09 10:54:53', '2026-11-09 10:54:53');
INSERT INTO `content_item` VALUES (47, '九重问心阶', '一阶一问，九问九答，答不出的问题会化作利刃割开记忆。', 11, '地阶', '🪜', 7560, 1, '2026-11-09 10:54:53', '2026-11-09 10:54:53');
INSERT INTO `content_item` VALUES (48, '镜中己身', '与另一个自己交手，他知晓你所有招式的破绽——因为他就是你。', 11, '天阶', '🪞', 9030, 1, '2026-11-09 10:54:53', '2026-11-09 10:54:53');
INSERT INTO `content_item` VALUES (49, '黄粱一梦阵', '入阵即过完一生，醒来不过半炷香，然九成人不愿醒。', 11, '地阶', '💭', 7840, 1, '2026-11-09 10:54:53', '2026-11-09 10:54:53');
INSERT INTO `content_item` VALUES (50, '七情困锁', '喜、怒、忧、思、悲、恐、惊各成一关，破一关割一情。', 11, '玄阶', '🎭', 6420, 1, '2026-11-09 10:54:53', '2026-11-09 10:54:53');
INSERT INTO `content_item` VALUES (51, '无相试心台', '台上无物，唯有一面空镜，照出的不是你，而是你想要成为的人。', 11, '天阶', '🔮', 8760, 1, '2026-11-09 10:54:53', '2026-11-09 10:54:53');
INSERT INTO `content_item` VALUES (52, '血池炼魂场', '魂魄入血池反复煎熬，熬得住则神识凝如实质。', 11, '地阶', '🩸', 7310, 1, '2026-11-09 10:54:53', '2026-11-09 10:54:53');
INSERT INTO `content_item` VALUES (53, '百鬼夜行图', '画中百鬼齐出，需在画中活过一夜，鸡鸣方能脱身。', 11, '玄阶', '👻', 5980, 1, '2026-11-09 10:54:53', '2026-11-09 10:54:53');
INSERT INTO `content_item` VALUES (54, '枯井回声境', '向井中呼喊，回应你的声音会说出你此生最不堪的往事。', 11, '黄阶', '🕳️', 4270, 1, '2026-11-09 10:54:53', '2026-11-09 10:54:53');
INSERT INTO `content_item` VALUES (55, '轮回九世劫', '九世轮回，世世横死，第九世若仍执剑，方见真我。', 11, '天阶', '⏳', 9180, 1, '2026-11-09 10:54:53', '2026-11-09 10:54:53');
INSERT INTO `content_item` VALUES (56, '寒冰绝念关', '心跳一停，幻境自破；心若不静，先冻住的是自己。', 11, '玄阶', '❄️', 6150, 1, '2026-11-09 10:54:53', '2026-11-09 10:54:53');
INSERT INTO `content_item` VALUES (57, '万念俱灰台', '所有念想被抽走的一瞬，便是破境之机，亦是道消之始。', 11, '地阶', '🌑', 7421, 1, '2026-11-09 10:54:53', '2026-11-09 11:23:29');
INSERT INTO `content_item` VALUES (61, '九转还魂丹', '传说可令陨落修士重生的禁忌丹药，丹成之时天必降雷。', 12, '天阶', '🌿', 9610, 1, '2026-11-09 10:54:53', '2026-11-09 10:54:53');
INSERT INTO `content_item` VALUES (62, '大回春丹', '断肢可续、五脏可补，疗伤圣药，一枚值一座小宗门。', 12, '地阶', '💊', 8320, 1, '2026-11-09 10:54:53', '2026-11-09 10:54:53');
INSERT INTO `content_item` VALUES (63, '小还丹', '散修囊中常备之物，止血生肌，服之立见效。', 12, '黄阶', '🟡', 4890, 1, '2026-11-09 10:54:53', '2026-11-09 10:54:53');
INSERT INTO `content_item` VALUES (64, '复脉养元丹', '重伤垂危者服之，脉象先稳，元气后补，为疗伤争取三日。', 12, '玄阶', '🫀', 6740, 1, '2026-11-09 10:54:53', '2026-11-09 10:54:53');
INSERT INTO `content_item` VALUES (65, '碧灵清心丸', '解百毒、清心火，走火入魔初起服之，可将魔念压回识海。', 12, '地阶', '🟢', 7480, 1, '2026-11-09 10:54:53', '2026-11-09 10:54:53');
INSERT INTO `content_item` VALUES (66, '续命金丹', '以百年寿元为丹引，为将死之人续命一年，一年之内不可再服。', 12, '天阶', '⚜️', 8940, 1, '2026-11-09 10:54:53', '2026-11-09 10:54:53');
INSERT INTO `content_item` VALUES (67, '洗髓还元丹', '洗去体内丹毒与旧伤根，服后如获新生，然过程痛不欲生。', 12, '地阶', '🫧', 7820, 1, '2026-11-09 10:54:53', '2026-11-09 10:54:53');
INSERT INTO `content_item` VALUES (68, '止血散', '最寻常的疗伤之药，碾碎敷于伤口，血即止住。', 12, '黄阶', '🧂', 4120, 1, '2026-11-09 10:54:53', '2026-11-09 10:54:53');
INSERT INTO `content_item` VALUES (69, '固本培元丹', '体虚气弱者服之，如以温汤灌田，三日之内气力自复。', 12, '玄阶', '🌾', 5960, 1, '2026-11-09 10:54:53', '2026-11-09 10:54:53');
INSERT INTO `content_item` VALUES (70, '回天造化丹', '只要一息尚存，便可从鬼门关拉回半条命，炼成者寥寥。', 12, '天阶', '✨', 9180, 1, '2026-11-09 10:54:53', '2026-11-09 10:54:53');
INSERT INTO `content_item` VALUES (71, '养血生肌丹', '失血过多者之福音，服后三日便可再战。', 12, '玄阶', '🩸', 6210, 1, '2026-11-09 10:54:53', '2026-11-09 10:54:53');
INSERT INTO `content_item` VALUES (72, '百草敷元膏', '非丹而是膏，涂于伤处，草木生机自皮肤渗入经脉。', 12, '黄阶', '🌱', 3870, 1, '2026-11-09 10:54:53', '2026-11-09 10:54:53');
INSERT INTO `content_item` VALUES (76, '破境丹', '卡境界者的福音，一枚可搏一次突破契机，成与不成皆看道心。', 13, '地阶', '⚡', 8820, 1, '2026-11-09 10:54:53', '2026-11-09 10:54:53');
INSERT INTO `content_item` VALUES (77, '冲虚丹', '助筑基后期冲破虚境，服后三日经脉如鼓胀，慎用。', 13, '玄阶', '🌀', 7140, 1, '2026-11-09 10:54:53', '2026-11-09 10:54:53');
INSERT INTO `content_item` VALUES (78, '化神引', '引动神魂蜕变之丹，服之者十有其三神魂崩散，余者化神。', 13, '天阶', '👁️', 9260, 1, '2026-11-09 10:54:53', '2026-11-09 10:54:53');
INSERT INTO `content_item` VALUES (79, '凝金丹', '将散乱灵力凝为一颗金丹，金丹既成，寿元再增三百。', 13, '地阶', '🟡', 8140, 1, '2026-11-09 10:54:53', '2026-11-09 10:54:53');
INSERT INTO `content_item` VALUES (80, '凿壁丹', '如凿壁透光，专为瓶颈如铁壁者所炼，一凿即通。', 13, '玄阶', '🔨', 6320, 1, '2026-11-09 10:54:53', '2026-11-09 10:54:53');
INSERT INTO `content_item` VALUES (81, '洗尘丹', '洗去修行途中积下的杂浊之气，为下一次破境清场。', 13, '黄阶', '💧', 4380, 1, '2026-11-09 10:54:53', '2026-11-09 10:54:53');
INSERT INTO `content_item` VALUES (82, '九窍通明丹', '服后九窍俱开，灵气往来无碍，破境成功率增三成。', 13, '地阶', '🕳️', 7680, 1, '2026-11-09 10:54:53', '2026-11-09 10:54:53');
INSERT INTO `content_item` VALUES (83, '渡劫护心丹', '天劫临头前服下，可护住心脉不被劫雷震碎。', 13, '天阶', '🌩️', 8940, 1, '2026-11-09 10:54:53', '2026-11-09 10:54:53');
INSERT INTO `content_item` VALUES (84, '破妄丹', '破除心中妄念与自我设限，副作用是三日之内口吐真言。', 13, '玄阶', '🪞', 5870, 1, '2026-11-09 10:54:53', '2026-11-09 10:54:53');
INSERT INTO `content_item` VALUES (85, '固境丹', '境界初成时服之，可将新生境界夯实，免跌落之虞。', 13, '地阶', '🏔️', 7210, 1, '2026-11-09 10:54:53', '2026-11-09 10:54:53');
INSERT INTO `content_item` VALUES (86, '引灵丹', '以丹力牵引外灵入体，为筑基之人铺第一级台阶。', 13, '黄阶', '🌬️', 4050, 1, '2026-11-09 10:54:53', '2026-11-09 10:54:53');
INSERT INTO `content_item` VALUES (87, '魂契丹', '以自身一缕神魂为契，换取一次强行冲关的机会。', 13, '天阶', '🔗', 8760, 1, '2026-11-09 10:54:53', '2026-11-09 10:54:53');
INSERT INTO `content_item` VALUES (91, '诛仙魔剑', '饮血万千的魔道至宝，出鞘必见血，剑身常凝一层暗红。', 14, '天阶', '⚔️', 9998, 1, '2026-11-09 10:54:53', '2026-11-09 10:54:53');
INSERT INTO `content_item` VALUES (92, '斩月弯刀', '刀光如新月一线，斩出时无声无息，敌人往往先倒后闻声。', 14, '地阶', '🌙', 8360, 1, '2026-11-09 10:54:53', '2026-11-09 10:54:53');
INSERT INTO `content_item` VALUES (93, '九幽噬魂幡', '幡动则百鬼出，吞噬敌之神魂，为魔宗镇派重器。', 14, '天阶', '🏴', 9120, 1, '2026-11-09 10:54:53', '2026-11-09 10:54:53');
INSERT INTO `content_item` VALUES (94, '裂山锤', '一锤落下山崩地裂，重而不失准，力修最爱。', 14, '玄阶', '🔨', 6240, 1, '2026-11-09 10:54:53', '2026-11-09 10:54:53');
INSERT INTO `content_item` VALUES (95, '血饮枪', '枪尖饮血则愈利，一场大战之后枪身赤红如烙铁。', 14, '地阶', '🔱', 7530, 1, '2026-11-09 10:54:53', '2026-11-09 10:54:53');
INSERT INTO `content_item` VALUES (96, '青莲剑', '剑身刻莲纹，出剑气成莲华，清正而不容邪祟。', 14, '天阶', '🪷', 8740, 1, '2026-11-09 10:54:53', '2026-11-09 10:54:53');
INSERT INTO `content_item` VALUES (97, '夺魂钉', '七枚一套，钉入则锁魂，离体则魂散，防不胜防。', 14, '玄阶', '📌', 6080, 1, '2026-11-09 10:54:53', '2026-11-09 10:54:53');
INSERT INTO `content_item` VALUES (98, '落雷锥', '掷出引天雷附于锥身，专破护身结界。', 14, '地阶', '⚡', 7280, 1, '2026-11-09 10:54:53', '2026-11-09 10:54:53');
INSERT INTO `content_item` VALUES (99, '缚龙索', '上古缚龙之索，越是挣扎勒得越紧，捆人亦捆兽。', 14, '地阶', '🪢', 6950, 1, '2026-11-09 10:54:53', '2026-11-09 10:54:53');
INSERT INTO `content_item` VALUES (100, '焚天扇', '一扇起风、二扇生火、三扇燎野，非大能不可轻挥。', 14, '天阶', '🪭', 8620, 1, '2026-11-09 10:54:53', '2026-11-09 10:54:53');
INSERT INTO `content_item` VALUES (101, '铁骨鞭', '以妖骨节节串成，抽人不见血，伤在筋骨与神魂。', 14, '玄阶', '🦴', 5470, 1, '2026-11-09 10:54:53', '2026-11-09 10:54:53');
INSERT INTO `content_item` VALUES (102, '飞蝗针', '一次可散出三百六十枚细针，蚁多咬死象。', 14, '黄阶', '📍', 4260, 1, '2026-11-09 10:54:53', '2026-11-09 10:54:53');
INSERT INTO `content_item` VALUES (106, '玄武宝甲', '取上古玄武甲壳炼制，刀枪不入，唯气闷难久着。', 15, '地阶', '🛡️', 7710, 1, '2026-11-09 10:54:53', '2026-11-09 10:54:53');
INSERT INTO `content_item` VALUES (107, '太虚玄光罩', '罩起如琉璃，可挡三次同阶全力一击，三次之后自碎。', 15, '天阶', '🔵', 8940, 1, '2026-11-09 10:54:53', '2026-11-09 10:54:53');
INSERT INTO `content_item` VALUES (108, '金刚护心镜', '贴于胸前者，可卸三成力于身外，唯惧背后偷袭。', 15, '玄阶', '🪞', 6470, 1, '2026-11-09 10:54:53', '2026-11-09 10:54:53');
INSERT INTO `content_item` VALUES (109, '九幽尸衣', '以千年尸茧织成，刀剑不穿、火烧不烂，着之者气息如死人。', 15, '地阶', '👘', 7360, 1, '2026-11-09 10:54:53', '2026-11-09 10:54:53');
INSERT INTO `content_item` VALUES (110, '缠丝软甲', '千根蚕丝缠成，轻若无物，贴身可挡暗器与流矢。', 15, '黄阶', '🕸️', 4590, 1, '2026-11-09 10:54:53', '2026-11-09 10:54:53');
INSERT INTO `content_item` VALUES (111, '山河盾', '盾上刻山河地理，受击时万里山川共担其力。', 15, '天阶', '🏔️', 9180, 1, '2026-11-09 10:54:53', '2026-11-09 10:54:53');
INSERT INTO `content_item` VALUES (112, '寒玉障壁', '掷出成障，寒气凝壁，破之需三击同处。', 15, '玄阶', '❄️', 6080, 1, '2026-11-09 10:54:53', '2026-11-09 10:54:53');
INSERT INTO `content_item` VALUES (113, '不动明王钟', '钟起声波成域，域中万法皆缓三分，攻守两用。', 15, '地阶', '🔔', 7590, 1, '2026-11-09 10:54:53', '2026-11-09 10:54:53');
INSERT INTO `content_item` VALUES (114, '替身符偶', '刻主人生辰的木偶，替主人受一次死击即成齑粉。', 15, '玄阶', '🎎', 6830, 1, '2026-11-09 10:54:53', '2026-11-09 10:54:53');
INSERT INTO `content_item` VALUES (115, '紫金钵盂', '钵口朝天可罩自身，水火不侵，唯行动迟缓。', 15, '地阶', '🍚', 7040, 1, '2026-11-09 10:54:53', '2026-11-09 10:54:53');
INSERT INTO `content_item` VALUES (116, '血魂护主牌', '以心头血养之，主人垂危时自动挡下致命一击。', 15, '天阶', '🩸', 8860, 1, '2026-11-09 10:54:53', '2026-11-09 10:54:53');
INSERT INTO `content_item` VALUES (117, '藤甲护身', '山藤老根编成，箭矢难入，然遇火即焚，需谨慎。', 15, '黄阶', '🌿', 3720, 1, '2026-11-09 10:54:53', '2026-11-09 10:54:53');
INSERT INTO `content_item` VALUES (121, '赤炎火凤', '南明离火所化，羽落成焰，可载人日行十万八千里。', 16, '天阶', '🦅', 9430, 1, '2026-11-09 10:54:53', '2026-11-09 10:54:53');
INSERT INTO `content_item` VALUES (122, '玄冰白鹤', '自极北寒渊来，双翼展开可凝云成冰，飞行无声。', 16, '地阶', '🕊️', 7280, 1, '2026-11-09 10:54:53', '2026-11-09 10:54:53');
INSERT INTO `content_item` VALUES (123, '幽冥蝠王', '夜行如影，散播阴气遮蔽天光，最宜潜行潜入。', 16, '玄阶', '🦇', 6340, 1, '2026-11-09 10:54:53', '2026-11-09 10:54:53');
INSERT INTO `content_item` VALUES (124, '金翅大鹏', '一翅九万里，振翅可起飓风，非大能者镇不住其性。', 16, '天阶', '🦅', 9660, 1, '2026-11-09 10:54:53', '2026-11-09 10:54:53');
INSERT INTO `content_item` VALUES (125, '云纹青鸾', '青鸾过处云雾自生，可藏行迹，性情温顺通人意。', 16, '地阶', '🪶', 7690, 1, '2026-11-09 10:54:53', '2026-11-09 10:54:53');
INSERT INTO `content_item` VALUES (126, '赤鬃焰马', '踏火而行，四蹄过处留一串燃痕，奔行百里不歇。', 16, '玄阶', '🐎', 5870, 1, '2026-11-09 10:54:53', '2026-11-09 10:54:53');
INSERT INTO `content_item` VALUES (127, '雷翼飞蛟', '生双翼，御雷而行，落雷之处焦土遍野。', 16, '天阶', '🐉', 9210, 1, '2026-11-09 10:54:53', '2026-11-09 10:54:53');
INSERT INTO `content_item` VALUES (128, '纸鹤灵', '符纸所折，载人不足百斤，然价廉易得，散修最爱。', 16, '黄阶', '📃', 3920, 1, '2026-11-09 10:54:53', '2026-11-09 10:54:53');
INSERT INTO `content_item` VALUES (129, '紫翼天蝠', '翼生紫纹，飞行时周身紫雾弥漫，可迷敌目。', 16, '玄阶', '🦇', 5610, 1, '2026-11-09 10:54:53', '2026-11-09 10:54:53');
INSERT INTO `content_item` VALUES (130, '风隼', '身小而疾，御之者如乘风，传讯千里可日还。', 16, '黄阶', '🦅', 4180, 1, '2026-11-09 10:54:53', '2026-11-09 10:54:53');
INSERT INTO `content_item` VALUES (136, '啸月天狼', '月圆之夜战力翻倍的忠勇灵兽，护主之心至死不改。', 17, '玄阶', '🐺', 6820, 1, '2026-11-09 10:54:53', '2026-11-09 10:54:53');
INSERT INTO `content_item` VALUES (137, '玄甲铁犀', '皮坚如铁，横身一挡可替主人受三击，性慢而忠。', 17, '地阶', '🦏', 7140, 1, '2026-11-09 10:54:53', '2026-11-09 10:54:53');
INSERT INTO `content_item` VALUES (138, '九尾天狐', '狐尾每增一尾便多一幻术，护主时以幻遮身，以媚惑敌。', 17, '天阶', '🦊', 9370, 1, '2026-11-09 10:54:53', '2026-11-09 10:54:53');
INSERT INTO `content_item` VALUES (139, '石胎守卫', '以山石封神魂而成，不眠不休守在洞府门口三百载。', 17, '地阶', '🗿', 7460, 1, '2026-11-09 10:54:53', '2026-11-09 10:54:53');
INSERT INTO `content_item` VALUES (140, '赤眼蛟蜥', '两眼赤红如灯，能吐毒雾成墙，护主时全身鳞甲炸立。', 17, '玄阶', '🦎', 6180, 1, '2026-11-09 10:54:53', '2026-11-09 10:54:53');
INSERT INTO `content_item` VALUES (141, '千年树妖', '根须盘地，可自地底缚敌，护院最是牢靠。', 17, '地阶', '🌳', 6890, 1, '2026-11-09 10:54:53', '2026-11-09 10:54:53');
INSERT INTO `content_item` VALUES (142, '白骨犬', '枯骨所化，不知痛、不畏死，主人一声令下便冲阵。', 17, '黄阶', '🐕', 4260, 1, '2026-11-09 10:54:53', '2026-11-09 10:54:53');
INSERT INTO `content_item` VALUES (143, '玄龟老祖', '背负玄甲，寿逾万年，护身结界可抵元婴一击。', 17, '天阶', '🐢', 9050, 1, '2026-11-09 10:54:53', '2026-11-09 10:54:53');
INSERT INTO `content_item` VALUES (144, '墨麒麟', '无角之麟，气息厚重压场，邪祟见之不敢近。', 17, '天阶', '🐐', 8940, 1, '2026-11-09 10:54:53', '2026-11-09 10:54:53');
INSERT INTO `content_item` VALUES (145, '照影猫', '九命之猫，能窥人心念，主人遇险前必先炸毛。', 17, '黄阶', '🐈', 3970, 1, '2026-11-09 10:54:53', '2026-11-09 10:54:53');
INSERT INTO `content_item` VALUES (146, '铁背苍猿', '臂能举鼎，护主时挡在最前，挨打愈多怒气愈盛。', 17, '玄阶', '🦍', 5640, 1, '2026-11-09 10:54:53', '2026-11-09 10:54:53');
INSERT INTO `content_item` VALUES (151, '魔宗起居注', '历代宗主手札，字里行间藏着宗门最大的秘密与最深的债。', 6, '地阶', '📖', 7420, 1, '2026-11-09 10:54:53', '2026-11-09 10:54:53');
INSERT INTO `content_item` VALUES (152, '万法源流考', '考证诸天功法源流，一册在手，可辨天下功法之根脚。', 6, '天阶', '📚', 8860, 1, '2026-11-09 10:54:53', '2026-11-09 10:54:53');
INSERT INTO `content_item` VALUES (153, '山河地理志', '记载九州灵脉、秘境、灵材产地，行商修士必备。', 6, '玄阶', '🗺️', 6410, 1, '2026-11-09 10:54:53', '2026-11-09 10:54:53');
INSERT INTO `content_item` VALUES (154, '百炼丹方集', '丹修手抄药方八百余则，多处批注：此方慎用。', 6, '地阶', '⚗️', 7730, 1, '2026-11-09 10:54:53', '2026-11-09 10:54:53');
INSERT INTO `content_item` VALUES (155, '神兵谱', '录古今法宝名器，附其铸造者之辛酸旧事。', 6, '地阶', '🗡️', 7560, 1, '2026-11-09 10:54:53', '2026-11-09 10:54:53');
INSERT INTO `content_item` VALUES (156, '上古神魔录', '录神魔之战始末，读之者常于梦中见血。', 6, '天阶', '👁️', 9180, 1, '2026-11-09 10:54:53', '2026-11-09 10:54:53');
INSERT INTO `content_item` VALUES (157, '灵兽驯养经', '自筑基期至化神期的驯兽之法，附灵兽脾性一览。', 6, '玄阶', '🐾', 5980, 1, '2026-11-09 10:54:53', '2026-11-09 10:54:53');
INSERT INTO `content_item` VALUES (158, '阵道真解', '三百六十阵图详解，破阵者当先识阵。', 6, '地阶', '🕸️', 7090, 1, '2026-11-09 10:54:53', '2026-11-09 10:54:53');
INSERT INTO `content_item` VALUES (159, '星象推演录', '以星轨推演大劫之期，无人敢信，又无人敢不看。', 6, '玄阶', '🌟', 6230, 1, '2026-11-09 10:54:53', '2026-11-09 10:54:53');
INSERT INTO `content_item` VALUES (160, '残卷·太初篇', '仅余七页，却引得三派为此血战一场。', 6, '天阶', '📜', 9410, 1, '2026-11-09 10:54:53', '2026-11-09 10:54:53');
INSERT INTO `content_item` VALUES (161, '草木灵材典', '录天下灵草三千种，附图辨真伪，采药人赖此活命。', 6, '黄阶', '🌱', 4120, 1, '2026-11-09 10:54:53', '2026-11-09 10:54:53');

-- ----------------------------
-- Table structure for forum_post
-- ----------------------------
DROP TABLE IF EXISTS `forum_post`;
CREATE TABLE `forum_post`  (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '主键',
  `author` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT '发帖人（用户名或道号）',
  `title` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT '帖名',
  `content` varchar(2000) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT '正文',
  `views` bigint NOT NULL DEFAULT 0 COMMENT '围观量',
  `likes` bigint NOT NULL DEFAULT 0 COMMENT '道心相印（点赞）',
  `status` tinyint NOT NULL DEFAULT 1 COMMENT '状态：1 显示 / 0 屏蔽',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '发帖时间',
  PRIMARY KEY (`id`) USING BTREE,
  INDEX `idx_post_time`(`create_time` ASC) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 18 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_general_ci COMMENT = '论道帖' ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of forum_post
-- ----------------------------
INSERT INTO `forum_post` VALUES (1, '血无常', '【置顶】宗门戒律第一条：不得欺师灭祖', '戒律三百条，此为第一条。违者：废修为、逐出宗门、追杀千里。望诸弟子谨记。', 5200, 1314, 1, '2026-11-09 11:09:35');
INSERT INTO `forum_post` VALUES (2, '白骨真人', '论炼体与炼心孰优孰劣', '炼体者皮糙肉厚一力破万法，炼心者神识如网千里锁敌。依老夫看，都没我一根骨头硬。不服者执法堂领教。', 3400, 880, 1, '2026-11-09 11:09:35');
INSERT INTO `forum_post` VALUES (3, '幽冥子', '幽冥鬼市亲历：我只带了三成寿元进去', '子时入市的道友切记：鬼商报价只砍一轮，第二轮他还价就是看上你的寿元了。附避坑清单，阅后即焚。', 4600, 720, 1, '2026-11-09 11:09:35');
INSERT INTO `forum_post` VALUES (4, '赤炎老祖', '求破境丹真伪鉴定', '丹坊新收一枚破境丹，丹纹三圈、气味微腥。有人说是赝品，有人说是丹纹独树一帜。懂行的道友掌掌眼。', 2100, 450, 1, '2026-11-09 11:09:35');
INSERT INTO `forum_post` VALUES (5, '千面魔君', '万剑坟场捡剑指南（勿外传）', '戌时剑鸣最弱，从东南坡绕开剑气林，见残剑先拜三拜。此帖发完我去坟场蹲点，看看是谁在偷师。', 5800, 903, 1, '2026-11-09 11:09:35');
INSERT INTO `forum_post` VALUES (6, '玉面罗刹', '血煞堂招新，只收心狠手辣者', '本堂扩招。要求：一敢下手，二不废话，三听指挥。修为不限，金丹以上可直接面见堂主。', 3900, 666, 1, '2026-11-09 11:09:35');
INSERT INTO `forum_post` VALUES (7, '苏九黎', '心魔幻阵第七层卡了三个月，求破', '每次都死在\"故人相认\"那一幕。明知是幻，偏偏醒不过来。过来人道友给个法子，愿以丹方相谢。', 1800, 512, 1, '2026-11-09 11:09:35');
INSERT INTO `forum_post` VALUES (8, '阿蛮', '论道规则：辱骂道友者罚扫藏经阁三月', '新来的道友看过来：论道讲的是以理服人，骂人一时爽，藏经阁扫地扫断腰。文明论道，从你我做起。', 900, 233, 1, '2026-11-09 11:09:35');

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
) ENGINE = InnoDB AUTO_INCREMENT = 5 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_general_ci COMMENT = '首页搜索日志表' ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of search_log
-- ----------------------------
INSERT INTO `search_log` VALUES (1, '万剑坟场', NULL, 1, NULL, '2026-11-09 10:56:41');
INSERT INTO `search_log` VALUES (2, '诛仙魔剑', NULL, 1, NULL, '2026-11-09 10:56:42');
INSERT INTO `search_log` VALUES (3, '金翅大鹏', NULL, 1, NULL, '2026-11-09 10:56:42');
INSERT INTO `search_log` VALUES (4, '九转还魂丹', NULL, 1, NULL, '2026-11-09 10:56:43');

-- ----------------------------
-- Table structure for sect_member
-- ----------------------------
DROP TABLE IF EXISTS `sect_member`;
CREATE TABLE `sect_member`  (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '主键',
  `name` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT '道号',
  `realm` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT '境界：魔尊/渡劫/大乘/合体/炼虚/化神/元婴/金丹/筑基/炼气',
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
INSERT INTO `sect_member` VALUES (1, '血无常', '魔尊', '宗主', '主殿', 9999999, 999999, '😈', '2026-11-09 11:09:35');
INSERT INTO `sect_member` VALUES (2, '阎罗娘子', '渡劫', '副宗主', '血煞堂', 8800000, 620000, '🌙', '2026-11-09 11:09:35');
INSERT INTO `sect_member` VALUES (3, '白骨真人', '渡劫', '执法长老', '执法堂', 7600000, 540000, '💀', '2026-11-09 11:09:35');
INSERT INTO `sect_member` VALUES (4, '千面魔君', '大乘', '内务长老', '千机堂', 5900000, 410000, '🎭', '2026-11-09 11:09:35');
INSERT INTO `sect_member` VALUES (5, '幽冥子', '大乘', '长老', '幽冥堂', 5200000, 380000, '🌑', '2026-11-09 11:09:35');
INSERT INTO `sect_member` VALUES (6, '玉面罗刹', '合体', '堂主', '血煞堂', 3600000, 260000, '🌺', '2026-11-09 11:09:35');
INSERT INTO `sect_member` VALUES (7, '赤炎老祖', '合体', '丹殿长老', '炼丹堂', 3300000, 245000, '🔥', '2026-11-09 11:09:35');
INSERT INTO `sect_member` VALUES (8, '噬魂叟', '炼虚', '长老', '幽冥堂', 2100000, 180000, '👁️', '2026-11-09 11:09:35');
INSERT INTO `sect_member` VALUES (9, '墨鸦', '炼虚', '首席弟子', '执法堂', 1800000, 160000, '🐦', '2026-11-09 11:09:35');
INSERT INTO `sect_member` VALUES (10, '苏九黎', '化神', '内门弟子', '千机堂', 900000, 95000, '🦋', '2026-11-09 11:09:35');
INSERT INTO `sect_member` VALUES (11, '谢无咎', '化神', '外门弟子', '血煞堂', 850000, 88000, '⚔️', '2026-11-09 11:09:35');
INSERT INTO `sect_member` VALUES (12, '阿蛮', '金丹', '记名弟子', '炼丹堂', 260000, 30000, '🍖', '2026-11-09 11:09:35');

-- ----------------------------
-- Table structure for user
-- ----------------------------
DROP TABLE IF EXISTS `user`;
CREATE TABLE `user`  (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '涓婚敭锛岃嚜澧',
  `username` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT '鐢ㄦ埛鍚嶏紙3-20 浣嶅瓧姣?鏁板瓧/涓嬪垝绾匡紝鍞?竴锛',
  `password` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT '瀵嗙爜锛孧D5 32 浣嶅崄鍏?繘鍒跺瓨鍌',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '鍒涘缓鏃堕棿',
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '鏇存柊鏃堕棿',
  PRIMARY KEY (`id`) USING BTREE,
  UNIQUE INDEX `uk_username`(`username` ASC) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 4 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_general_ci COMMENT = '鐢ㄦ埛琛' ROW_FORMAT = DYNAMIC;

-- ----------------------------
-- Records of user
-- ----------------------------
INSERT INTO `user` VALUES (1, 'admin', 'e10adc3949ba59abbe56e057f20f883e', '2026-10-19 10:59:10', '2026-10-19 10:59:10');
INSERT INTO `user` VALUES (2, 'test', 'e10adc3949ba59abbe56e057f20f883e', '2026-10-19 10:59:10', '2026-10-19 10:59:10');
INSERT INTO `user` VALUES (3, 'ywh', '99a541b1767705fc56501698fb871e5f', '2026-10-19 11:36:25', '2026-10-19 11:36:25');

SET FOREIGN_KEY_CHECKS = 1;
