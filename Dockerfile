# 使用 Node.js 22 (Debian Bullseye)
FROM node:22-bullseye

# 1. 补全浏览器、SSH、时区及 Python 编译工具
RUN apt-get update && apt-get install -y \
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
    # Chromium 依赖 (补全缺失项)
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
    && rm -rf /var/lib/apt/lists/*

# 2. 锁定 pnpm 版本
RUN corepack enable && corepack prepare pnpm@9.0.0 --activate

# 3. 环境变量 (修正 Python 为 3.9)
ENV TZ=Asia/Shanghai \
    SKIP_DOWNLOAD_LLAMA_CPP_BINARIES=1 \
    NODE_LLAMA_CPP_SKIP_DOWNLOAD=1 \
    PYTHONUSERBASE=/app/.local \
    OPENCLAW_STATE_DIR=/app/.openclaw \
    PATH="/app/.local/bin:${PATH}" \
    PYTHONPATH="/app/.local/lib/python3.9/site-packages:${PYTHONPATH}"

# 4. 目录预设与权限 (针对 HF 优化)
# 显式初始化 SSH 目录并赋权，防止 SSH 运行时报错
# 预创建 /app/.openclaw 以支持数据重定向
RUN mkdir -p /app /app/.openclaw /home/node/.ssh && \
    chmod 700 /home/node/.ssh && \
    chown -R node:node /app /home/node

WORKDIR /app

# 5. 代码拉取
# 克隆仓库并设置权限
RUN git clone https://github.com/superxuu/HF_clawbot.git /app && \
    chown -R node:node /app

USER node

# 6. 使用 --user 安装，确保 AI 运行时可调用 (Paramiko/Fabric)
RUN pip3 install --no-cache-dir --user paramiko fabric

# 7. 构建
# 安装依赖并清理缓存
RUN pnpm install --no-frozen-lockfile && pnpm store prune && \
    pnpm build && \
    pnpm ui:build

EXPOSE 7860
ENV NODE_ENV=production PORT=7860

# 8. 启动
CMD ["sh", "-c", "export OPENCLAW_GATEWAY_PORT=${PORT:-7860}; node scripts/run-node.mjs gateway --port ${PORT:-7860} --force --allow-unconfigured"]
