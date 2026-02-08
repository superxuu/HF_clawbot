# 使用 Node.js 22 (Debian Bullseye)
FROM node:22-bullseye

# 1. 补全浏览器、SSH、时区及 Python 编译工具
# - DEBIAN_FRONTEND=noninteractive: 防止 tzdata 等安装时由于交互式提示挂起
# - fonts-noto-color-emoji: 确保网页截图中的 Emoji 正常显示
# - libxss1: 增强浏览器进程在某些组件下的兼容性
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
    # Chromium 依赖
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
# - PYTHONUSERBASE 指定后，Python 会自动寻找其下的 site-packages
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
# 采用克隆到当前目录的方式，随后创建数据重定向目录并赋权
RUN git clone https://github.com/superxuu/HF_clawbot.git . && \
    mkdir -p /app/.openclaw && \
    chown -R node:node /app

# 切换到非 root 用户 (node)
USER node

# 6. 使用 --user 安装以确保 AI 运行时路径兼容
RUN pip3 install --no-cache-dir --user paramiko fabric

# 7. 构建流程 (分步执行以便于日志定位)
RUN pnpm install --no-frozen-lockfile
RUN pnpm store prune
RUN pnpm build
RUN pnpm ui:build
# 关键：下载 Chromium 二进制内核，这是智能体联网浏览的“硬件”基础
RUN pnpm exec playwright-core install chromium

EXPOSE 7860
# 关键环境变量：设置生产环境与端口
ENV NODE_ENV=production PORT=7860

# 8. 启动
# 移除 --no-sandbox (该标志应由代码注入浏览器，而非注入网关服务)
CMD ["sh", "-c", "export OPENCLAW_GATEWAY_PORT=${PORT:-7860}; node scripts/run-node.mjs gateway --port ${PORT:-7860} --force --allow-unconfigured"]
