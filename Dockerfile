# 使用 Node.js 22 作为基础镜像
FROM node:22-bullseye

# 安装必要的系统工具 (git, cmake, python3, 编译工具)
RUN apt-get update && apt-get install -y \
    git \
    cmake \
    python3 \
    lsof \
    build-essential \
    openssh-client \
    && rm -rf /var/lib/apt/lists/*

# 启用核心包管理 (pnpm)
RUN corepack enable && corepack prepare pnpm@latest --activate

# 设置构建环境变量，尝试跳过不必要的原生模块重新编译 (如果支持)
ENV SKIP_DOWNLOAD_LLAMA_CPP_BINARIES=1
ENV NODE_LLAMA_CPP_SKIP_DOWNLOAD=1

# 设置工作目录并预分配权限
RUN mkdir -p /app && chown 1000:1000 /app
WORKDIR /app

# 切换到非 root 用户 (UID 1000)
USER 1000

# 从特定仓库拉取代码
RUN git clone https://github.com/superxuu/HF_clawbot.git .

# 安装依赖
RUN pnpm install --no-frozen-lockfile

# 构建项目
RUN pnpm build

# 构建前端 UI
RUN pnpm ui:build

# 暴露端口 (HF Space 要求 7860)
EXPOSE 7860

# 环境变量设置
ENV NODE_ENV=production
ENV PORT=7860

# 启动应用程序
# 显式映射 PORT 到 OpenClaw 使用的 OPENCLAW_GATEWAY_PORT，并加上 gateway 命令启动服务
# 增加 --allow-unconfigured 允许在没有物理配置文件的情况下使用硬编码注入的配置
CMD ["sh", "-c", "export OPENCLAW_GATEWAY_PORT=${PORT:-7860}; node scripts/run-node.mjs gateway --port ${PORT:-7860} --force --allow-unconfigured"]
