# Go-Admin-UI · 前端 GitOps 交付

> Vue 2 + Element UI 前端项目，通过多阶段 Docker 构建打包为 Nginx 静态站点，接入 GitLab CI + ArgoCD GitOps 流水线。

## 项目简介

本项目基于 [go-admin-ui](https://github.com/go-admin-team/go-admin-ui)（Vue 2 + Element UI 后台管理前端），在其之上搭建了完整的 CI/CD 交付流水线。

**重点不是前端代码，而是交付能力：** 从 NPM 依赖管理、多阶段 Docker 构建、GitLab CI 自动化到 ArgoCD GitOps 部署。

## 技术栈

| 层级 | 技术 |
|---|---|
| 框架 | Vue 2 + Element UI + Vue CLI 4 |
| 构建 | webpack 4 + Babel |
| 容器化 | Docker 多阶段构建（node:18 builder + nginx:alpine runtime） |
| CI/CD | GitLab CI/CD + GitLab Container Registry |
| GitOps | ArgoCD + Helm |
| 部署 | Nginx 静态站点 |

## 仓库结构

```
go-admin-ui/
├── src/                    # 源码（views/api/components/router/store/layout）
├── public/                 # 静态资源
├── build/                  # 构建配置
├── Dockerfile              # 多阶段构建（107MB）
├── docker/nginx.conf       # Nginx 配置
├── .gitlab-ci.yml          # CI 流水线
├── vue.config.js           # Vue CLI 配置
└── package.json
```

## Dockerfile 构建优化

| 构建方式 | 镜像大小 | 说明 |
|---|---|---|
| 单阶段构建 | ~1.2GB | 包含 node_modules + 源码 |
| 多阶段构建 | 107MB | 仅 Nginx + dist 产物 |

## 构建过程踩坑记录

| 问题 | 解决方案 |
|---|---|
| package-lock.json 不存在 | 用 `npm install` 替代 `npm ci` |
| eslint peer dependency 冲突 | 加 `--legacy-peer-deps` |
| 构建脚本名称不是 build | 改为 `npm run build:prod` |
| Node.js 18 OpenSSL 3.0 不兼容 | 加 `NODE_OPTIONS=--openssl-legacy-provider` |

## GitLab CI 流水线

```
lint → install → build → scan → push
```

- **lint**: ESLint 代码检查
- **install**: npm install（淘宝镜像加速）
- **build**: 生产构建（gzip 压缩）
- **scan**: Trivy 漏洞扫描
- **push**: 推送到 GitLab Container Registry

## 相关仓库

- 后端：[go-admin](https://gitlab.com/AmazingYe-oss/go-admin)
- GitOps 配置：infra-gitops（ArgoCD ApplicationSet + Helm Chart）

## License

MIT
