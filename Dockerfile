# ================================
# 第一阶段：构建环境 (Builder Stage)
# ================================
# 使用轻量级的 Node 18 Alpine 镜像作为构建基础
FROM node:18-alpine AS builder

# 设置工作目录
WORKDIR /app

# 1. 缓存优化：先复制依赖描述文件并安装
# 只要依赖不发生变化，后续修改代码重新构建时，Docker 会复用这一层缓存
COPY package.json ./
RUN npm install --registry=https://registry.npmmirror.com --legacy-peer-deps && npm cache clean --force

# 2. 复制源码并执行构建
COPY . .
RUN NODE_OPTIONS=--openssl-legacy-provider npm run build:prod

# ================================
# 第二阶段：运行环境 (Runtime Stage)
# ================================
# 使用极简的 Nginx Alpine 镜像作为最终运行环境
FROM nginx:alpine AS runtime

# 3. 安全加固：清理默认的 Nginx 配置并创建自定义配置
# 注意：你需要在项目根目录提供一个 nginx.conf 文件
COPY docker/nginx.conf /etc/nginx/conf.d/default.conf

# 从 builder 阶段复制构建好的静态文件（通常是 dist 或 build 目录）
COPY --from=builder /app/dist /usr/share/nginx/html

# 暴露 80 端口
EXPOSE 80

# 启动 Nginx 服务（前台运行模式）
CMD ["nginx", "-g", "daemon off;"]