# go-admin-ui

go-admin 平台的前端。Fork 自 [go-admin-team/go-admin-ui](https://github.com/go-admin-team/go-admin-ui)，适配后端 go-admin 的 API。

## 技术栈

- Vue 2.6
- Element UI 2.13
- vue-cli 4.5
- Node 16（CI 镜像锁死 `.nvmrc`）

## 本地开发

```bash
npm install
npm run dev        # http://localhost:9527
```

`.env.development` 默认指向 `http://localhost:8000`，本地后端跑起来后直接生效。

## 构建

```bash
npm run build:prod
```

产物在 `dist/`，里面有个 `index.html` + 带 hash 的 chunk。Docker 镜像里 nginx 配的 `try_files` 兜底到 `index.html`，所以前端路由刷新不会 404。

## Docker 构建

多阶段：

```dockerfile
FROM node:16-bookworm-slim AS builder
WORKDIR /src
COPY package*.json ./
RUN npm ci
COPY . .
RUN npm run build:prod

FROM nginx:1.25-alpine
COPY nginx.conf /etc/nginx/conf.d/default.conf
COPY --from=builder /src/dist /usr/share/nginx/html
```

`nginx.conf` 关键点：

```nginx
location / {
    try_files $uri $uri/ /index.html;
}
location /api/ {
    proxy_pass http://go-admin:8000;
}
```

`/api/` 反代到后端 Service 名 `go-admin`，端口 8000。

## CI

`.github/workflows/ci.yml` 三阶段：

| 阶段    | 工具                        | 失败行为 |
|---------|-----------------------------|----------|
| `lint`  | `eslint`                    | 阻塞     |
| `test`  | `npm test`（实际只跑 lint） | 阻塞     |
| `build` | `docker buildx`             | 阻塞     |

**注意**：现在的 `npm test` 只是占位（vue-cli 4 + Jest 7 的兼容性问题折腾太久没解决，先 lint 保证代码风格）。单元测试覆盖率实际为 0，业务逻辑基本在后端。

Node 16 镜像体积大是因为要装 `python3` 和 `g++` 用来编译 `node-sass`。Node 18 的 OpenSSL 3.0 砍了 webpack 4 用的 MD4 hash，所以 CI 里要加 `NODE_OPTIONS=--openssl-legacy-provider` 才能跑通，权衡之后选了 Node 16 一了百了。

## 部署

跟后端一起，详见 [infra-gitops](https://github.com/AmazingYe-oss/infra-gitops)。镜像 tag 在 `infra-gitops/go-admin-ui-chart/values-*.yaml` 维护，由 `go-admin-ui` 的 `gitops-bump` job 自动更新。

## 已知局限

- Vue 2 + Element UI 已经 EOL，没升级 Vue 3 主要是时间不允许。
- 没做 i18n，多语言靠后端字典接口。
- 没有 Storybook，组件文档写在每个组件文件头的注释里。

## 相关仓库

| 仓库 | 作用 |
|------|------|
| [go-admin](https://github.com/AmazingYe-oss/go-admin) | 后端服务 |
| [infra-gitops](https://github.com/AmazingYe-oss/infra-gitops) | ArgoCD + Helm 配置 |

## License

MIT