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
- **前端未引入 vue-router**：`App.vue` 用 `view` 状态机切换 `'login' | 'register' | 'home'`，登录成功后 `view='home'` 跳转首页 `src/components/HomePage.vue`（含导航栏 + 搜索栏，魔宗暗色主题）。会话 `token`/`username` 存 `localStorage`，刷新不丢。首页的搜索/导航/快速入口目前仅前端占位（toast 提示），**后端检索接口与其他页面尚未接入，auth.js 的登录/注册接口保持原样**。
  → 新增页面时继续用 `view` 状态机，或届时再引入 vue-router（需 `npm i vue-router`）。
- **后端强依赖 MySQL**：`jdbc:mysql://localhost:3306/login_db`，用户 `root`，密码 `123456`。
  → **本机已安装 MySQL 8 且开机自启**（客户端在 `C:\Program Files\MySQL\MySQL Server 8.0\bin\mysql.exe`）。
  `login_db` 与 `user` 表通过 `sql/login_db.sql` 建好（完整版，含 DROP，手动重建用）。
  **`start.bat` 启动时会自动执行 `sql/ensure_db.sql`**（幂等：CREATE ... IF NOT EXISTS +
  演示账号仅在缺失时插入），所以**环境重置后库被清空也能一键自愈，不用再手动跑 SQL**。
  → 演示账号 admin / test，密码均为 123456（MD5=e10adc3949ba59abbe56e057f20f883e）。
- **MySQL 数据目录已迁到 D:（防重置丢数据）**：原 `datadir` 在 `C:\ProgramData\MySQL\...\Data`（C 盘会被重置清掉 → 之前 login_db 老是丢）。
  **2026-10-19 已把 datadir 改到 `D:\MySQLData`**（`my.ini` 第 97 行 `datadir=D:/MySQLData`，备份 `my.ini.bak` 在同目录），
  ACL 已授权 `NT SERVICE\MySQL80` / SYSTEM / Administrators / Everyone。**D 盘不在重置范围**，所以
  login_db 及你自己注册的账号、连同 ruoyi 库都能跨重启保留。
  ⚠️ 若某次重置把 my.ini 也还原成 C:（极端情况），`start.bat` 的 `ensure_db.sql` 仍会自动重建 login_db（仅演示账号），
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
