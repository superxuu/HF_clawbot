# 使用 Node.js 22 作为基础镜像
FROM node:22-bullseye

# 安装必要的系统工具 (git, cmake, python3, 编译工具)
RUN apt-get update && apt-get install -y \
    git \
    cmake \
    python3 \
    build-essential \
    openssh-client \
    && rm -rf /var/lib/apt/lists/*

# 启用核心包管理 (pnpm)
RUN corepack enable && corepack prepare pnpm@latest --activate

# 设置构建环境变量，尝试跳过不必要的原生模块重新编译 (如果支持)
ENV SKIP_DOWNLOAD_LLAMA_CPP_BINARIES=1
ENV NODE_LLAMA_CPP_SKIP_DOWNLOAD=1

# 设置工作目录
WORKDIR /app

# 注意：Hugging Face Space 会自动将当前仓库代码放在构建上下文中。
# 如果你想从特定仓库拉取最新代码，可以使用下面的命令：
# 注意：如果仓库是私有的，需要通过环境变量传入 token。
RUN git clone https://github.com/superxuu/HF_clawbot.git .

# 安装依赖
# 由于是克隆的全新仓库，我们需要安装依赖
RUN pnpm install --no-frozen-lockfile

# 构建项目 (编译 TypeScript 等)
RUN pnpm build

# 构建前端 UI
RUN pnpm ui:build

# 修正目录权限 (HF Space 使用 user 1000)
RUN chown -R 1000:1000 /app

# 切换到非 root 用户
USER 1000

# 暴露端口 (HF Space 要求 7860)
EXPOSE 7860

# 环境变量设置
ENV NODE_ENV=production
ENV PORT=7860

# 启动应用程序
# 显式映射 PORT 到 OpenClaw 使用的 OPENCLAW_GATEWAY_PORT
CMD ["sh", "-c", "export OPENCLAW_GATEWAY_PORT=${PORT:-7860}; node scripts/run-node.mjs"]
