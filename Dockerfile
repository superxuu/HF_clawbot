# 使用 Node.js 22 (Debian Bullseye)
FROM node:22-bullseye

# 1. 补全浏览器、SSH、时区及 Python 编译工具
# - DEBIAN_FRONTEND=noninteractive: 防止 tzdata 等安装时由于交互式提示挂起
# - chromium: 系统级内核，其路径 /usr/bin/chromium 可被 OpenClaw 自动识别
RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y \
    git \
    cmake \
    python3 \
    python3-pip \
    python3-setuptools \
    python3-wheel \
    lsof \
    build-essential \
    openssh-client \
    tzdata \
    chromium \
    libnss3 \
    libatk1.0-0 \
    libatk-bridge2.0-0 \
    libcups2 \
    libdrm2 \
    libxkbcommon0 \
    libxcomposite1 \
    libxdamage1 \
    libxext6 \
    libxfixes3 \
    libxrandr2 \
    libgbm1 \
    libasound2 \
    libpango-1.0-0 \
    libpangocairo-1.0-0 \
    libx11-xcb1 \
    libxcb1 \
    libglib2.0-0 \
    libgtk-3-0 \
    fonts-liberation \
    fonts-noto-color-emoji \
    libxss1 \
    && rm -rf /var/lib/apt/lists/*

# 2. 锁定 pnpm 版本确保构建一致性
RUN corepack enable && corepack prepare pnpm@9.0.0 --activate

# 3. 环境变量 (自适应 Python 路径，去除硬编码版本号)
ENV TZ=Asia/Shanghai \
    SKIP_DOWNLOAD_LLAMA_CPP_BINARIES=1 \
    NODE_LLAMA_CPP_SKIP_DOWNLOAD=1 \
    PYTHONUSERBASE=/app/.local \
    OPENCLAW_STATE_DIR=/app/.openclaw \
    PATH="/app/.local/bin:${PATH}"

# 4. 目录预设与权限 (使用 node 用户对齐标准 Shell 环境)
RUN mkdir -p /home/node/.ssh && \
    chmod 700 /home/node/.ssh && \
    chown -R node:node /home/node

WORKDIR /app

# 5. 代码拉取及权限同步
RUN git clone https://github.com/superxuu/HF_clawbot.git . && \
    mkdir -p /app/.openclaw && \
    chown -R node:node /app

# 切换到非 root 用户 (node)
USER node

# 6. 使用 --user 安装以确保 AI 运行时路径兼容
RUN pip3 install --no-cache-dir --user paramiko fabric

# 7. 构建流程 (驱动重定向与环境适配已并入代码，此处仅负责编译)
RUN pnpm install --no-frozen-lockfile
RUN pnpm store prune
RUN pnpm build
RUN pnpm ui:build

EXPOSE 7860
# 关键环境变量：设置生产环境与端口
ENV NODE_ENV=production PORT=7860

# 8. 启动 (依靠代码级 [io.ts] 对 HF 环境的检测自动挂载 --no-sandbox)
CMD ["sh", "-c", "export OPENCLAW_GATEWAY_PORT=${PORT:-7860}; node scripts/run-node.mjs gateway --port ${PORT:-7860} --force --allow-unconfigured"]
