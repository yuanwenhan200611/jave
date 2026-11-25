# AGENTS.md — 项目上下文备忘（给 AI / 下次重置后自己看）

> 本文件存在的唯一目的：**电脑每次重启会被重置，下次开机要能直接照做，不要重新推理。**
> 只读这一份 + 双击 `start.bat` 即可，不要再去翻源码猜结构。

## 一句话定位
全栈「登录页」示例项目，前端 Vue3+Vite，后端 Spring Boot。
根目录：`C:\Users\Administrator\Desktop\jave-main\jave-main`
（注意：文件夹名 `jave-main` 是 `java-main` 的笔误，不用改，记住就行。）

## 目录结构
```
jave-main/
├── start.bat            # 一键启动（GBK 编码，相对路径）
├── pause.bat            # 一键停止（GBK 编码）
├── AGENTS.md            # 本文件
├── README.md            # 给人看的运行说明
├── login-vue/           # 前端：Vue3 + Vite6
│   ├── package.json     # 仅 vue / @vitejs/plugin-vue / vite / vite-plugin-singlefile
│   ├── package-lock.json
│   ├── vite.config.js   # host 127.0.0.1:5173，/api 代理到 http://localhost:8081
│   └── src/...
└── springBootTest/      # 后端：Spring Boot 3.4.5 (Java 17 target)
    ├── mvnw / mvnw.cmd  # Maven Wrapper（本机没有全局 mvn，必须用这个）
    ├── pom.xml
    ├── .mvn/maven.config # 已加 -T 1C 并行构建，加速
    └── src/main/resources/
        ├── application.properties      # spring.profiles.active=dev
        ├── application-dev.properties  # server.port=8081
        └── ...（MySQL 数据源配置在 application.properties）
```

## 关键事实（必记）
- **前端端口 5173**，**后端端口 8081**。前端 dev 下 `/api` 代理到 8081。
- **前端未引入 vue-router**：`App.vue` 用 `view` 状态机切换 `'login' | 'register' | 'home' | 'secret' | 'skill' | 'rank' | 'forum'`，登录成功后进首页，顶部导航（共享组件 `src/components/SectNav.vue`）在宗门各页面间切换。
  现有视图：home / secret / skill / cultivation / quest / market / rank / forum / profile（SECT_VIEWS 同步维护）。
  → 新增页面时继续用 `view` 状态机，或届时再引入 vue-router（需 `npm i vue-router`）。
- **宗门四堂（2026-11-09 已上线）**：
  - 功法阁 `SkillPage.vue`：复用 /api/home/search 按功法分类检索，分堂 tab = 功法的二级分类；
  - 秘境 `SecretPage.vue`：「随机探秘」走 POST /api/secret/roam（天机引路费 200 贡献值，每次必收；旧的免费 /api/sect/explore 已下线）；
    随机探秘奖励走寒酸口径（45% 空手而归），秘境永不产出贡献值；指定秘境破界门票每次照收，无「已开辟免费重游」；
  - 宗门榜 `RankPage.vue`（2026-11-25 完善）：GET /api/sect/rank?username=&sortBy=power|contribution&tier=elder|disciple|all
    + GET /api/sect/halls?username=&tier=（sect_member 表 NPC + **当前登录玩家实时折算**，战力/贡献双榜 ×
    **长老榜/弟子榜双辈分榜**、前三领奖台、「我的名次」（本榜内）+ 距上一名差距、**身份筛选 chips**、
    境界层级 + 小层次图例、道号/境界/层次/身份/堂口搜索、刷新按钮）。默认进长老榜；玩家境界不够时显示「去弟子榜」引导。
    → 玩家**不写 sect_member 表**（避免污染种子数据）：SectService.buildMeEntry 复用 ProfileService.getProfile 取数，
    战力 = 修为×10 + 已习功法数×2000 + 已完成任务数×1000 + 10000 底薪，贡献 = 洞府口径的累计贡献值；
    VO 为 `vo/RankEntryVO`（多带 me/cultivation/username/tier/tierLabel/elder/stage/realmFull 字段）。改数值只动 SectService 顶部 4 个常量。
  - **境界分层统一口径（2026-11-25）**：后端 `util/RealmTier.java`、前端 `src/utils/realm.js` 两份同源定义。
    十大境界不变：炼气/筑基/金丹=弟子境，元婴/化神=真传境，炼虚/合体/大乘/渡劫=长老境，魔尊=至尊境。
    分榜规则：**炼虚及以上进长老榜**（长老境+至尊境），化神及以下进弟子榜。
    **每个大境界再分小层次（STAGES）**：炼气一层~九层；筑基/金丹/元婴/化神/合体/大乘 初期/中期/后期/巅峰；
    炼虚 小成/大成/圆满/巅峰；渡劫 一劫/三劫/五劫/七劫/九劫；魔尊 一重/三重/五重/七重/九重。
    修为门槛 REALM_THRESHOLD 也在 RealmTier（CultivationService 已改为引用），`stageOf(realm,cultivation)`
    按境界区间折算层次，`fullRealm()` 拼完整境界（如「炼虚小成」）。sect_member 加 `stage` 列（幂等加列见两个 sql）。
    CultivationService.REALMS、QuestService.REALM_ORDER、ProfileService.REALMS、洞府境界下拉都已改为引用统一定义，
    **不要再各处硬写境界数组**。改境界顺序/分层/层次只动这两份工具文件，且必须前后端同步。
    → 展示完整境界的页面（RankPage/ProfilePage/HomePage/CultivationPage/ForumPage）统一用
    `fullRealm(realm, stageOf(realm, cultivation))`，玩家没有独立 stage 字段，一律按修为现算；
    **注意 fullRealm 第二参数是层次字符串不是修为数**，曾因传成 cultivation 导致只显示大境界，已修。
  - **宗门人物种子（2026-11-25 扩充至 78 人）**：`sql/seed_sect.sql` + `sql/ensure_db.sql` 同步维护（判重插入，可反复执行）。
    长老榜 39：宗主/副宗主各1、太上长老5、内门长老10、外门长老15、执法/内务/丹殿长老/堂主/长老/首席弟子若干；
    弟子榜 39：圣子1、圣女1、真传弟子10、内门弟子9、外门弟子11、记名弟子7（+ admin 玩家实时折算入榜 → 40）。
    加新人只改这两份 sql 的 INSERT UNION ALL 列（含 stage），改完手动 `mysql < sql/seed_sect.sql` 施用到库。
    前端身份筛选 GRADE_ORDER/GRADE_ICON 在 RankPage.vue，新身份记得补进去（否则图标回落为「·」）。
  - 血辩台 `ForumPage.vue`（原论道，2026-11-18 魔宗化改造）：GET /api/forum/posts（username 可选，返回 incensedIds/counteredIds）
    + POST /api/forum/posts（开坛讲道：20 灵石设坛，修为 +60~150，60s 调息）
    + POST /api/forum/posts/{id}/incense（香火供奉：10 灵石，自己 +15~40 修为，帖主 +5 贡献分成）
    + POST /api/forum/posts/{id}/counter（驳道：押 50 修为，45% 胜 +120~300 / 败 -50）。
    论道即修炼：消耗/修为统一走 CultivationService.settle 落 cultivation_log（兼作调息判定）；
    帖主分成落 forum_income（魔功殿/洞府余额口径均已计入）；动作防重靠 forum_like 表 UNIQUE(post_id,username,action)。
  → 对应建表与种子在 sql/seed_sect.sql（ensure_db.sql 已并入，start.bat 自愈无忧）。新 Mapper 必须加 @Mapper 注解，否则启动报 bean not found。
- **魔功殿·增修为（2026-11-18 已上线）** `CultivationPage.vue`：五种魔宗法门修炼增修为（魔窟苦修/吞噬血丹/血祭秘法/夺舍夺元/吞天魔功，
  各有冷却与反噬概率），接口 GET /api/cultivation/info + POST /api/cultivation/practice（CultivationService/CultivationController）。
  修为存 `user_profile.cultivation`（ensure_db.sql 第 11 节幂等加列），跨门槛自动晋升境界（只升不降）；
  流水存 `cultivation_log`（兼作冷却判定）。
  经济闭环：任务阁赚灵石/贡献 → 魔功殿花灵石/贡献换修为；洞府 contributionAvailable 已扣魔功殿消耗。
  法门概率/收益/冷却全部硬编码在 CultivationService 的 METHODS/rollOutcome/rollDelta，要调数值只改这一个文件。
- **坊市·交易市场（2026-11-23 已上线）** `MarketPage.vue`：魔宗风格买卖页（灵石经济第三极）。
  - GET /api/market/list?username=&category= → 灵石余额 + 在售货品 + 分类角标 + 储物空间可寄售藏品（含估价）
  - POST /api/market/buy { username, itemId } → 扣灵石；法宝/残篇/神通入储物空间，功法免贡收录（user_skill, cost=0），丹药当场服用（cultivation_log, method_key=market）
  - POST /api/market/sell { username, rewardId } → 坊市牙人按品阶估价回购，得灵石；卖出后 secret_reward.status=1，从储物空间消失
  - POST /api/market/list-item { username, rewardId, price } → 玩家私摊：自由标价（牙人估价 0.5~3 倍，估价为确定性公式，前端展示与后端校验一致），挂单时 secret_reward.status=2（寄售中，不在储物空间）
  - POST /api/market/cancel { username, itemId } → 撤单，藏品状态回 0；已成交不可撤
  - 私摊成交：其他弟子买走时双向结算（买家 -price、卖家 +price、各记一条 market_order）；自家摊位不可自买自卖
  - 游方散修：每次 GET /list 有 18% 概率挑走一件「价格 ≤ 估价×1.5」的玩家私摊，单人也有成交机会
  - GET /api/market/orders?username= → 交易手札（market_order，buy/sell 流水）
  - 摊位货品存 `market_item`（NPC 摊主：噬魂老魔/白骨夫人/鬼手药王/玄阴子… + 玩家私摊 seller_type=user / reward_id 关联藏品），在售 NPC 货 < 10 件时 MarketService.restock() 自动随机补货；
    品阶权重 黄50/玄30/地15/天5，价格按品阶×类型系数；药名/价格/概率全硬编码在 MarketService。
  - 灵石账本：买卖都记 `forum_income`（source=market，买为负、卖为正），因此 CultivationService.stonesBalance 与洞府余额口径自动一致，不需要改动。
- **后端强依赖 MySQL**：`jdbc:mysql://localhost:3306/login_db`，用户 `root`，密码 `123456`。
  → **本机已安装 MySQL 8 且开机自启**（客户端在 `C:\Program Files\MySQL\MySQL Server 8.0\bin\mysql.exe`）。
  `login_db` 与 `user` 表通过 `sql/login_db.sql` 建好（完整版，含 DROP，手动重建用）。
  **`start.bat` 启动时会自动执行 `sql/ensure_db.sql`**（幂等：CREATE ... IF NOT EXISTS +
  演示账号仅在缺失时插入），所以**环境重置后库被清空也能一键自愈，不用再手动跑 SQL**。
  → 演示账号 admin / test，密码均为 123456（MD5=e10adc3949ba59abbe56e057f20f883e）。
- **MySQL 数据目录已迁到 D:（防重置丢数据）**：原 `datadir` 在 `C:\ProgramData\MySQL\...\Data`（C 盘会被重置清掉 → 之前 login_db 老是丢）。
  **2026-11-09 已重新把 datadir 改到 `D:\MySQLData`**（`my.ini` 第 97 行 `datadir=D:/MySQLData`，备份 `my.ini.bak` 在同目录），
  ACL 已授权 `NT SERVICE\MySQL80` / SYSTEM / Administrators / Everyone。
  ⚠️ 历史教训：2026-11 前的一次重置把之前的 D:\MySQLData 迁移连同 my.ini 一起弄丢了，login_db 被清空、
  前端 `login-vue/src/assets/home-bg.jpg`（未提交 git 的本地文件）也丢了，均已修复。
  → 防丢失已做两件事：① 背景图已提交进 git（commit 83e1451）；② datadir 重新指向 D 盘（本次已验证 @@datadir=D:\MySQLData）。
  若某次重置把 my.ini 也还原成 C:（极端情况），`start.bat` 的 `ensure_db.sql` 仍会自动重建 login_db（仅演示账号），
  应用照常可用，只是自注册账号需重新建——属兜底，正常不会触发。
- **工具链**（本机已具备）：Node v22、npm 10、Java Zulu 21（跑 Java17 target 没问题）、Maven 走 Wrapper。
- **每次重启会删 `node_modules` 和 `target`**，但 `~/.m2`（Maven 仓库）和 npm 缓存**不会被删**。
  → 所以 `npm ci` 和 `mvnw` 基本是缓存命中，不会满世界重新下载（除非整台机器被重装镜像）。
- 脚本一律用**相对路径** + `%~dp0`，放哪都能跑；`.bat` 必须是 **GBK 编码**（中文注释/控制台中文）。
- **`.mvn/wrapper/maven-wrapper.jar` 曾丢失导致 mvnw 报 classworlds ClassNotFound**，2026-10-16 已从
  Maven Central 重新下载放回。若再报同样错误，先检查这个 jar 是否还在。

## 怎么做（标准启动流程）
1. 双击 `start.bat`（或命令行 `start.bat`）。
2. 它会：检查 node/java → 尝试启动 MySQL 服务（没有就跳过）→ 新窗口 `npm ci`+`npm run dev` 起前端 → 另一个新窗口 `mvnw spring-boot:run`（先离线 `-o`，失败回退在线）起后端 → 等待 5173 端口就绪后**自动打开默认浏览器**到登录页 http://127.0.0.1:5173。
3. 关项目：双击 `pause.bat`，按端口 8081/5173 杀进程。

## 已做的“提速”优化
- `springBootTest/.mvn/maven.config` 写入 `-T 1C`：Maven 并行构建，明显快。
- 前端用 `npm ci --prefer-offline --no-audit --no-fund --progress=false`：锁定版本 + 走缓存，比 `npm install` 快且确定。
- 前端与后端各开独立窗口、**并行**拉起；拉起后自动等前端端口就绪并打开浏览器（「点一下就进网页」）。
- 后端 `spring-boot:run -DskipTests`：跳过测试，省时间。
- 离线优先（`-o`），缓存齐全时最快；缓存缺失自动回退在线。

## 还缺什么 / 建议（下次可补）
1. ~~MySQL 运行时~~ 已解决：本机装了 MySQL 8，`login_db` 已初始化。
2. 没有「整仓库」级别的 README，已补一个根 `README.md`。
3. 若希望后端彻底不依赖外网：确保 `.m2/repository` 在重置后仍在；若会被清，首次启动会慢（下依赖），属正常。

## 失败排查速查
- 前端起不来：看 5173 窗口日志；多半是 `npm ci` 网络问题 → 联网后重试。
- 后端起不来且报 JDBC/连接失败：**几乎一定是 MySQL 没开或没建库**，先装/起 MySQL 并执行 `sql/init.sql`。
- 报 `mvn` 不是命令：正常，本就该用 `mvnw.cmd`，别去装全局 mvn。
- 中文乱码：确认 `.bat` 是 GBK；控制台默认 936 即可。

## 已知坑（已修，别再改回）
- **`user` 是 MySQL 保留字**：实体 `User.java` 的 `@TableName` 必须用反引号写成 `` @TableName("`user`") ``，否则 MP 生成的 `INSERT/SELECT ... FROM user` 不带引号会语法错误 → 注册/登录 500。**不要改回 `"user"`。**
- 已加 `common/GlobalExceptionHandler.java`：后端任何未捕获异常都会以 `Result.error(500, 真实信息)` 返回，前端会**直接显示真实报错**而非笼统「服务器错误」，便于定位。
- **Git Bash 里跑 `mvnw`（sh 脚本）会报 classworlds ClassNotFound**——这是 Git Bash 路径转换的坑，与项目无关。
  用户实际走 `start.bat` → cmd → `mvnw.cmd`，已验证可用（2026-10-16）。**排查时别用 Git Bash 跑 mvnw 下结论。**
- **WorkBuddy 沙箱环境会注入 `SERVER__PORT` 环境变量**，Spring Boot 宽松绑定会把它当 `server.port`，
  覆盖 application-dev.properties 的 8081 → 后端起在随机端口或启动失败。真实用户机器无此变量，不受影响；
  仅在本沙箱内手动起后端时需要 `export SERVER__PORT=8081`。
- **前端 UI 已改为「天命大反派·修仙（魔宗）」暗色主题**（2026-10-16）：主题变量集中在
  `login-vue/src/styles/global.css` 的 `:root`，文案散布在 BrandPanel/LoginForm/RegisterForm。
  要换回浅色 SaaS 风就改那几个文件，别只改一处。
