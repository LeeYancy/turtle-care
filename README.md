# TurtleCare - AI智能养龟管家

AI驱动的个人养龟专家系统 V1.0

## 架构图

```
                    ┌─────────────────────────────────────────────────┐
                    │                   用户终端                        │
                    │  Flutter App (Android/iOS/Web)                  │
                    └──────────────────────┬──────────────────────────┘
                                           │ HTTPS
                                           ▼
                    ┌─────────────────────────────────────────────────┐
                    │                Nginx 反向代理                     │
                    │  ┌─────────────┐  ┌──────────────────────────┐  │
                    │  │  /static/   │  │  /api/  → backend:8080   │  │
                    │  │  Flutter Web│  │  /actuator/ → health     │  │
                    │  └─────────────┘  └──────────────────────────┘  │
                    └──────────────────────┬──────────────────────────┘
                                           │
                     ┌─────────────────────┼─────────────────────┐
                     │                     │                     │
                     ▼                     ▼                     ▼
          ┌──────────────────┐  ┌──────────────────┐  ┌──────────────────┐
          │  Spring Boot API │  │    PostgreSQL    │  │      Redis       │
          │  (Port 8080)     │  │  (Port 5432)     │  │  (Port 6379)     │
          │                  │  │                  │  │                  │
          │  ┌────────────┐  │  │  tc_user         │  │  Rate Limiting   │
          │  │ Auth (JWT) │  │  │  tc_turtle       │  │  Token Cache     │
          │  ├────────────┤  │  │  tc_health_*     │  │  Session         │
          │  │ Turtle Mgmt│  │  │  tc_chat_msg     │  │                  │
          │  ├────────────┤  │  │  tc_task         │  │                  │
          │  │ AI Service │  │  │  tc_health_score │  │                  │
          │  ├────────────┤  │  │                  │  │                  │
          │  │ Task Mgmt  │  │  │  Flyway Migration│  │                  │
          │  └────────────┘  │  └──────────────────┘  └──────────────────┘
          │        │         │
          │        ▼         │
          │  ┌───────────┐   │
          │  │ LLM Client │  │
          │  │ (Mock/OG)  │  │
          │  └───────────┘   │
          └──────────────────┘
                   │
                   ▼
          ┌──────────────────┐
          │  Aliyun OSS      │
          │  (Image Storage)  │
          └──────────────────┘
```

## 技术栈

| 层级 | 技术 | 版本 |
|------|------|------|
| 前端 | Flutter / Riverpod | 3.22+ |
| 后端 | Spring Boot / MyBatis Plus | 3.2.5 |
| 数据库 | PostgreSQL | 16 |
| 缓存 | Redis | 7 |
| AI | GPT-4o-mini / Claude 3 Haiku | - |
| API文档 | springdoc-openapi (Swagger UI) | 2.5.0 |
| CI/CD | GitHub Actions | - |
| 部署 | Docker Compose | - |
| 代码质量 | Checkstyle / SpotBugs / JaCoCo | - |

## API 端点

| 方法 | 路径 | 描述 | 认证 |
|------|------|------|------|
| POST | `/api/v1/auth/register` | 用户注册（手机号） | 否 |
| POST | `/api/v1/auth/login` | 用户登录 | 否 |
| POST | `/api/v1/turtles` | 创建龟档案 | 是 |
| GET | `/api/v1/turtles/active` | 获取当前活跃龟 | 是 |
| GET | `/api/v1/turtles` | 获取龟档案列表 | 是 |
| PUT | `/api/v1/turtles/{turtleId}` | 更新龟档案 | 是 |
| POST | `/api/v1/ai/health/analyze` | AI健康分析 | 是 |
| POST | `/api/v1/ai/chat` | AI智能问答 | 是 |
| GET | `/api/v1/ai/health/history/{turtleId}` | 健康分析历史 | 是 |
| GET | `/api/v1/tasks/today` | 今日任务 | 是 |
| GET | `/api/v1/tasks/week` | 本周任务 | 是 |
| POST | `/api/v1/tasks/{taskId}/complete` | 完成任务 | 是 |
| POST | `/api/v1/tasks/{taskId}/uncomplete` | 取消完成任务 | 是 |

**Swagger UI**: 启动后端后访问 `http://localhost:8080/swagger-ui.html`

## 开发环境搭建

### 前置要求

- JDK 17+
- Node.js 18+ (用于 Flutter Dart)
- Flutter SDK 3.22+
- Docker & Docker Compose
- Git

### 1. 克隆项目

```bash
git clone <repo-url> turtle-care
cd turtle-care
```

### 2. 启动基础设施

```bash
# 启动 PostgreSQL + Redis
docker compose up -d postgres redis

# 验证服务状态
docker compose ps
```

### 3. 启动后端

```bash
cd backend

# (首次) 生成 Gradle Wrapper
gradle wrapper

# 运行
./gradlew bootRun
```

后端启动后：
- API: `http://localhost:8080/api/v1/`
- Swagger UI: `http://localhost:8080/swagger-ui.html`
- 健康检查: `http://localhost:8080/actuator/health`

### 4. 启动前端

```bash
cd frontend

# 安装依赖
flutter pub get

# 生成代码 (Riverpod/Freezed/JsonSerializable)
dart run build_runner build --delete-conflicting-outputs

# 运行 (需要连接模拟器或真机)
flutter run
```

### 5. 代码质量检查

```bash
cd backend

# Checkstyle
./gradlew checkstyleMain checkstyleTest

# SpotBugs
./gradlew spotbugsMain spotbugsTest

# 测试 + 覆盖率报告
./gradlew test jacocoReport

# 查看覆盖率报告
open build/reports/jacoco/test/html/index.html
```

```bash
cd frontend

# 格式检查
dart format --output=none --set-exit-if-changed .

# 静态分析
flutter analyze

# 测试
flutter test --coverage
```

## Docker 部署

### 开发环境 (全栈一键启动)

```bash
# 构建并启动所有服务
docker compose up -d --build

# 查看日志
docker compose logs -f backend

# 停止
docker compose down
```

### 生产环境

```bash
# 1. 创建环境变量文件
cp .env.example .env.production
# 编辑 .env.production 填入生产配置

# 2. 部署
bash scripts/deploy-staging.sh      # Staging
bash scripts/deploy-production.sh   # Production (需要确认)

# 3. 数据库备份
bash scripts/backup-db.sh
```

### Docker 架构

| 服务 | 容器名 | 端口 | 说明 |
|------|--------|------|------|
| PostgreSQL | turtlecare-postgres | 5432 | 主数据库 |
| Redis | turtlecare-redis | 6379 | 缓存 + 限流 |
| Backend | turtlecare-backend | 8080 | Spring Boot API |
| Nginx | turtlecare-nginx | 80 | 反向代理 + 静态资源 |

## CI/CD 流水线

### CI Backend (`ci-backend.yml`)
- 触发: push/PR 到 main/develop (backend 目录变更)
- 步骤: Checkstyle → SpotBugs → Build → Test → JaCoCo 覆盖率

### CI Frontend (`ci-frontend.yml`)
- 触发: push/PR 到 main/develop (frontend 目录变更)
- 步骤: Format Check → Analyze → Test → Build APK

### CD Deploy (`cd-deploy.yml`)
- 触发: push 到 main / 手动触发
- 步骤: 构建 Docker 镜像 → 推送到 GHCR → SSH 部署到 Staging/Production

## 项目结构

```
turtle-care/
├── .github/
│   └── workflows/
│       ├── ci-backend.yml          # 后端 CI 流水线
│       ├── ci-frontend.yml         # 前端 CI 流水线
│       └── cd-deploy.yml           # CD 部署流水线
├── backend/
│   ├── config/
│   │   ├── checkstyle/checkstyle.xml
│   │   └── spotbugs/spotbugs-exclude.xml
│   ├── src/
│   │   ├── main/java/com/turtlecare/
│   │   │   ├── common/             # 公共模块 (安全/异常/配置)
│   │   │   └── module/             # 业务模块
│   │   │       ├── ai/             # AI 健康分析 + 聊天
│   │   │       ├── task/           # 养龟任务管理
│   │   │       ├── turtle/         # 龟档案管理
│   │   │       └── user/           # 用户认证
│   │   ├── main/resources/
│   │   │   ├── application.yml
│   │   │   ├── db/migration/       # Flyway 迁移脚本
│   │   │   └── mapper/             # MyBatis XML 映射
│   │   └── test/
│   │       └── java/com/turtlecare/integration/  # 集成测试
│   ├── Dockerfile                  # 多阶段构建
│   └── build.gradle
├── frontend/
│   ├── lib/
│   │   ├── app/                    # App入口/路由/主题
│   │   ├── core/                   # 核心能力 (API/存储)
│   │   └── presentation/features/  # 页面 (认证/首页/龟档/AI/任务)
│   ├── Dockerfile                  # Flutter Web + Nginx
│   └── pubspec.yaml
├── docker/
│   └── nginx/                      # Nginx 配置
├── scripts/
│   ├── deploy-staging.sh
│   ├── deploy-production.sh
│   └── backup-db.sh
├── .editorconfig
├── .gitignore
├── docker-compose.yml              # 开发环境
├── docker-compose.prod.yml         # 生产环境
└── README.md
```

## License

MIT
