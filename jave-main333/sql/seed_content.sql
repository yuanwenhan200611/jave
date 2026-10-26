-- ============================================================
--  seed_content.sql —— 首页内容条目批量种子（古风修仙风格）
--  覆盖：炼体功法 / 心法口诀 / 上古秘境 / 幻境试炼 / 回春丹 / 破境丹 /
--        攻击法宝 / 防御法宝 / 飞行灵兽 / 守护灵兽 / 典籍
--  特点：按 title 判重（NOT EXISTS），可反复执行；不删已有数据
--  使用：mysql -uroot -p123456 --default-character-set=utf8mb4 < sql/seed_content.sql
-- ============================================================
USE `login_db`;

-- 1. 炼体功法 -------------------------------------------------
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

-- 2. 心法口诀 -------------------------------------------------
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

-- 3. 上古秘境 -------------------------------------------------
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
  UNION ALL SELECT '桃都山', '山有大桃木盘曲三千里，上栖金鸡，日出则天下鸡皆鸣。', '地阶', '🍑', 6890, '上古秘境'
  UNION ALL SELECT '焚天火域', '地火奔涌不熄，火中藏有火灵，浴火炼器者视之为宝地。', '玄阶', '🌋', 6050, '上古秘境'
  UNION ALL SELECT '九幽黄泉渡', '黄泉之上无舟自渡，渡口舟子只问一句：可悔？', '天阶', '⛵', 9170, '上古秘境'
  UNION ALL SELECT '听雨古城', '城郭犹在，人皆不见，唯雨声终年不歇，雨落处碑文自现。', '黄阶', '🌧️', 4460, '上古秘境'
  UNION ALL SELECT '星陨海沟', '海沟深不见底，陨星沉眠于此，每逢月圆泛出幽光如潮。', '地阶', '🌌', 7210, '上古秘境'
) AS t
JOIN `category` c ON c.name = t.cat AND c.level = 2
WHERE NOT EXISTS (SELECT 1 FROM `content_item` x WHERE x.title = t.title);

-- 4. 幻境试炼 -------------------------------------------------
INSERT INTO `content_item` (`title`, `description`, `category_id`, `grade`, `icon`, `view_count`)
SELECT t.title, t.description, c.id, t.grade, t.icon, t.view_count
FROM (
  SELECT '七情幻界' AS title, '喜、怒、忧、思、悲、恐、惊轮番加身，能守一情不动者，方出此境。' AS description, '地阶' AS grade, '🎭' AS icon, 8310 AS view_count, '幻境试炼' AS cat
  UNION ALL SELECT '镜花水月阵', '所见皆为倒影，所击皆为镜面，破阵之钥从来不在手中。', '玄阶', '🪞', 6120, '幻境试炼'
  UNION ALL SELECT '千世轮回劫', '一入此境历千世生死，每世皆忘前尘，能于第三世自悟者万中无一。', '天阶', '🕸️', 9380, '幻境试炼'
  UNION ALL SELECT '无间杀阵', '四面八方皆杀机，不得停、不得退，唯有向前斩出一条血路。', '地阶', '🗡️', 7890, '幻境试炼'
  UNION ALL SELECT '问心桥', '桥长九丈，每行一步便问一桩旧事，答错则坠入忘川。', '黄阶', '🌉', 4570, '幻境试炼'
  UNION ALL SELECT '芥子须弥境', '入一微尘而见万里山河，出时外界不过一炷香，识海却已苍老。', '地阶', '🔍', 7060, '幻境试炼'
  UNION ALL SELECT '无相幻阵', '此阵不设形、不设声，闯入者所见所闻皆是自己最怕之物。', '玄阶', '🕳️', 6430, '幻境试炼'
  UNION ALL SELECT '落子天元局', '以自身为棋子入局对弈，对手是阵灵，输一子则少一年寿元。', '天阶', '♟️', 9050, '幻境试炼'
  UNION ALL SELECT '无常梦乡', '梦中富贵荣华、妻儿绕膝，醒来方知身已过期三日。', '黄阶', '🌙', 4180, '幻境试炼'
  UNION ALL SELECT '千机傀儡廊', '廊中傀儡皆按上古宗师招式出手，过廊可尽习百家之技。', '玄阶', '🎎', 6790, '幻境试炼'
  UNION ALL SELECT '倒悬天梯', '天梯倒挂于虚空，上一步便少一寸修为，登顶者修为散尽却道心圆成。', '地阶', '🪜', 7320, '幻境试炼'
  UNION ALL SELECT '一梦浮生阁', '于阁中睡一觉，醒来或已顿悟，或已白发。', '玄阶', '🛏️', 5560, '幻境试炼'
) AS t
JOIN `category` c ON c.name = t.cat AND c.level = 2
WHERE NOT EXISTS (SELECT 1 FROM `content_item` x WHERE x.title = t.title);

-- 5. 丹药 · 回春丹 --------------------------------------------
INSERT INTO `content_item` (`title`, `description`, `category_id`, `grade`, `icon`, `view_count`)
SELECT t.title, t.description, c.id, t.grade, t.icon, t.view_count
FROM (
  SELECT '九转还魂丹' AS title, '九转炉中九死九生，魂魄将散者服之可归位，然药引难觅。' AS description, '天阶' AS grade, '⚗️' AS icon, 8820 AS view_count, '回春丹' AS cat
  UNION ALL SELECT '生骨续脉丹', '断骨可接，经脉可续，服后三日痛如千万蚁行，此后行动如初。', '地阶', '🦴', 7340, '回春丹'
  UNION ALL SELECT '青囊回春散', '医修随身之物，撒于伤口知痛即止血，不知痛者已是无救。', '黄阶', '🌿', 4980, '回春丹'
  UNION ALL SELECT '百毒化清丸', '万毒攻心时服之，可将毒素尽数逼入足底，七日不得行路。', '玄阶', '🫧', 6170, '回春丹'
  UNION ALL SELECT '雪魄凝神丹', '寒渊雪莲炼成，神魂飘摇时含之，识海如落雪般静定。', '地阶', '❄️', 7560, '回春丹'
  UNION ALL SELECT '龙血生肌膏', '取蛟龙心头血调膏，刀伤剑创一夜可愈，唯留赤纹如龙鳞。', '玄阶', '🩸', 6620, '回春丹'
  UNION ALL SELECT '回天再造丹', '肉白骨、起沉疴，然服之者须以三成修为相偿。', '天阶', '✨', 9140, '回春丹'
  UNION ALL SELECT '清心莲子羹', '丹药中难得的温和之物，服之可解药毒、安六神。', '黄阶', '🪷', 3610, '回春丹'
  UNION ALL SELECT '不灭金身丹', '服后皮肉生金纹，十息之内外伤不侵，唯惧内伤。', '地阶', '🛡️', 7130, '回春丹'
  UNION ALL SELECT '续命灯芯丸', '以灯芯草裹寿元为丸，重创垂死者可再争一炷香。', '玄阶', '🕯️', 5890, '回春丹'
  UNION ALL SELECT '鹿茸养元丹', '温养气血，久病体虚者服之，面色自红润如少年。', '黄阶', '🦌', 3860, '回春丹'
  UNION ALL SELECT '九幽止血散', '魔宗行军常备，血涌如泉者一撒即止，唯药性霸道，用之者夜半怕冷。', '玄阶', '🩹', 5420, '回春丹'
) AS t
JOIN `category` c ON c.name = t.cat AND c.level = 2
WHERE NOT EXISTS (SELECT 1 FROM `content_item` x WHERE x.title = t.title);

-- 6. 丹药 · 破境丹 --------------------------------------------
INSERT INTO `content_item` (`title`, `description`, `category_id`, `grade`, `icon`, `view_count`)
SELECT t.title, t.description, c.id, t.grade, t.icon, t.view_count
FROM (
  SELECT '冲关破境丹' AS title, '瓶颈将破未破时服之，一念冲关，成则登堂，败则道基受损。' AS description, '地阶' AS grade, '⚡' AS icon, 8060 AS view_count, '破境丹' AS cat
  UNION ALL SELECT '洗髓易骨丹', '褪去凡胎浊骨，脱胎换骨一回，痛彻骨髓，此后修行一日千里。', '天阶', '🦴', 8970, '破境丹'
  UNION ALL SELECT '紫府开窍丹', '神识蒙昧者服之，可强开紫府一窍，从此所见天地清明三分。', '地阶', '🔮', 7280, '破境丹'
  UNION ALL SELECT '燃血冲霄丹', '燃烧精血换取一时疯涨的灵力，境界可越一级，代价是十年寿数。', '玄阶', '🩸', 6540, '破境丹'
  UNION ALL SELECT '金丹化纹丹', '金丹将凝者服之，可于丹上烙下一道天纹，威能陡增。', '天阶', '🌕', 8690, '破境丹'
  UNION ALL SELECT '心魔破障丹', '专克突破时的心魔，服之心如铁石，唯余一念。', '玄阶', '🪨', 5980, '破境丹'
  UNION ALL SELECT '悟道菩提子', '菩提树下结子，含于舌下入定，顿悟之机比苦修多出七分。', '地阶', '🌳', 7610, '破境丹'
  UNION ALL SELECT '筑基固本丸', '筑基期弟子常备，可稳固根基，减三成走火入魔之险。', '黄阶', '🪷', 4350, '破境丹'
  UNION ALL SELECT '淬灵散', '碎灵玉为粉，服之如灌灵泉，一夜涨百日之功，然根基虚浮。', '黄阶', '💠', 3970, '破境丹'
  UNION ALL SELECT '九转归元丹', '九次炼化九次弃之，最后一炉只余一枚，服之境界归元圆满。', '天阶', '♻️', 9250, '破境丹'
  UNION ALL SELECT '天河灌顶丹', '服之如天河倒灌泥丸宫，灵力暴涨三成，过则伤经脉。', '地阶', '💧', 7040, '破境丹'
  UNION ALL SELECT '枯木逢春丹', '道基崩损者服之，可将残基重凝，然十年内不可再进境。', '玄阶', '🌱', 5680, '破境丹'
) AS t
JOIN `category` c ON c.name = t.cat AND c.level = 2
WHERE NOT EXISTS (SELECT 1 FROM `content_item` x WHERE x.title = t.title);

-- 7. 法宝 · 攻击法宝 ------------------------------------------
INSERT INTO `content_item` (`title`, `description`, `category_id`, `grade`, `icon`, `view_count`)
SELECT t.title, t.description, c.id, t.grade, t.icon, t.view_count
FROM (
  SELECT '噬魂血刀' AS title, '刀身以万人血祭而成，每斩一人便长一线，握刀者耳畔常闻低语。' AS description, '天阶' AS grade, '🗡️' AS icon, 9620 AS view_count, '攻击法宝' AS cat
  UNION ALL SELECT '九幽冥火幡', '幡起幽火漫天，火不燃皮肉，专烧神魂，中者不觉痛便已魂灭。', '天阶', '🔥', 8830, '攻击法宝'
  UNION ALL SELECT '断岳重剑', '剑宽三尺、重八千斤，一剑落下山岳为开，唯需炼体有成者方可执。', '地阶', '⚔️', 7590, '攻击法宝'
  UNION ALL SELECT '摄魂钉', '三寸乌钉，打入眉心可摄人神魂，钉在墙上便能审其所知。', '玄阶', '📌', 6340, '攻击法宝'
  UNION ALL SELECT '千机弩', '一次上弦三十六矢，矢出如雨，淬毒之物更难防。', '黄阶', '🏹', 4870, '攻击法宝'
  UNION ALL SELECT '焚天印', '印成之时天火降世，落印之处方圆百丈化为焦土。', '天阶', '🔺', 9310, '攻击法宝'
  UNION ALL SELECT '寒螭鞭', '蛟筋所制，鞭出带霜，抽中者伤口即刻冻裂如瓷器。', '地阶', '🐍', 7120, '攻击法宝'
  UNION ALL SELECT '破军枪', '枪有杀气，愈战愈烈，破军之名取其一往无回。', '地阶', '🔱', 7860, '攻击法宝'
  UNION ALL SELECT '落魂铃', '轻摇一声人心神恍惚，三摇人魂不归，故魔宗弟子慎用。', '玄阶', '🔔', 6580, '攻击法宝'
  UNION ALL SELECT '斩月飞轮', '月牙双轮回旋，出必见血，入则回掌，最难缠的杀器。', '玄阶', '🌗', 6040, '攻击法宝'
  UNION ALL SELECT '血煞屠戮剑', '剑饮其主之血方肯出鞘，愈伤愈狠，与主共生共死。', '天阶', '🩸', 9480, '攻击法宝'
  UNION ALL SELECT '灵蜂针囊', '囊中养有千只灵蜂针，一放则如群蜂扑人，最难躲闪。', '黄阶', '🐝', 4230, '攻击法宝'
) AS t
JOIN `category` c ON c.name = t.cat AND c.level = 2
WHERE NOT EXISTS (SELECT 1 FROM `content_item` x WHERE x.title = t.title);

-- 8. 法宝 · 防御法宝 ------------------------------------------
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

-- 9. 灵兽 · 飞行灵兽 ------------------------------------------
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

-- 10. 灵兽 · 守护灵兽 -----------------------------------------
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

-- 11. 典籍 ----------------------------------------------------
INSERT INTO `content_item` (`title`, `description`, `category_id`, `grade`, `icon`, `view_count`)
SELECT t.title, t.description, t.cid AS category_id, t.grade, t.icon, t.view_count
FROM (
  SELECT '魔宗起居注' AS title, '历代宗主手札，字里行间藏着宗门最大的秘密与最深的债。' AS description, 6 AS cid, '地阶' AS grade, '📖' AS icon, 7420 AS view_count
  UNION ALL SELECT '万法源流考', '考证诸天功法源流，一册在手，可辨天下功法之根脚。', 6, '天阶', '📚', 8860
  UNION ALL SELECT '山河地理志', '记载九州灵脉、秘境、灵材产地，行商修士必备。', 6, '玄阶', '🗺️', 6410
  UNION ALL SELECT '百炼丹方集', '丹修手抄药方八百余则，多处批注：此方慎用。', 6, '地阶', '⚗️', 7730
  UNION ALL SELECT '神兵谱', '录古今法宝名器，附其铸造者之辛酸旧事。', 6, '地阶', '🗡️', 7560
  UNION ALL SELECT '宗门戒律录', '铁律三百条，首条曰：不得欺师灭祖。', 6, '黄阶', '📕', 4380
  UNION ALL SELECT '上古神魔录', '录神魔之战始末，读之者常于梦中见血。', 6, '天阶', '👁️', 9180
  UNION ALL SELECT '灵兽驯养经', '自筑基期至化神期的驯兽之法，附灵兽脾性一览。', 6, '玄阶', '🐾', 5980
  UNION ALL SELECT '阵道真解', '三百六十阵图详解，破阵者当先识阵。', 6, '地阶', '🕸️', 7090
  UNION ALL SELECT '星象推演录', '以星轨推演大劫之期，无人敢信，又无人敢不看。', 6, '玄阶', '🌟', 6230
  UNION ALL SELECT '残卷·太初篇', '仅余七页，却引得三派为此血战一场。', 6, '天阶', '📜', 9410
  UNION ALL SELECT '草木灵材典', '录天下灵草三千种，附图辨真伪，采药人赖此活命。', 6, '黄阶', '🌱', 4120
) AS t
WHERE NOT EXISTS (SELECT 1 FROM `content_item` x WHERE x.title = t.title);

-- 12. 校验 ----------------------------------------------------
SELECT c.name AS 分类, COUNT(i.id) AS 条目数
FROM `category` c
LEFT JOIN `content_item` i ON i.category_id = c.id
WHERE c.id IN (8,9,10,11,12,13,14,15,16,17)
   OR (c.name = '典籍' AND c.level = 1)
GROUP BY c.id, c.name
ORDER BY c.id;
SELECT COUNT(*) AS 条目总数 FROM `content_item`;

-- 13. 个人副本（登录 test 账号查看 / 答辩演示，不影响他人）
INSERT INTO `user` (`username`, `password`)
SELECT 'test', 'e10adc3949ba59abbe56e057f20f883e'
WHERE NOT EXISTS (SELECT 1 FROM `user` WHERE `username` = 'test');

CREATE TABLE IF NOT EXISTS `user_content` (
  `id`          BIGINT   NOT NULL AUTO_INCREMENT COMMENT '主键',
  `user_id`     BIGINT   NOT NULL                COMMENT '所属用户',
  `content_id`  BIGINT   NOT NULL                COMMENT '内容条目 id',
  `create_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '收藏时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_user_content` (`user_id`, `content_id`)
) ENGINE = InnoDB
  DEFAULT CHARSET = utf8mb4
  COLLATE = utf8mb4_general_ci
  COMMENT = '用户个人副本/收藏表';

INSERT IGNORE INTO `user_content` (`user_id`, `content_id`)
SELECT u.id, i.id FROM `user` u CROSS JOIN `content_item` i WHERE u.username = 'test';

SELECT COUNT(*) AS 个人副本条目 FROM `user_content`;
