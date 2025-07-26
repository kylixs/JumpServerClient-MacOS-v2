# JMS Protocol Handler - Development Environment
FROM swift:5.9-focal

LABEL maintainer="JMS Protocol Handler Team"
LABEL version="1.0.0"
LABEL description="Development environment for JMS Protocol Handler"

# 安装系统依赖
RUN apt-get update && apt-get install -y \
    build-essential \
    git \
    curl \
    wget \
    unzip \
    libssl-dev \
    libxml2-dev \
    libcurl4-openssl-dev \
    && rm -rf /var/lib/apt/lists/*

# 设置工作目录
WORKDIR /workspace

# 复制项目文件
COPY . .

# 创建构建目录结构
RUN mkdir -p build/{objects,temp,artifacts,xcode,derived-data}

# 设置环境变量
ENV SWIFT_VERSION=5.9
ENV PROJECT_NAME=JMSProtocolHandler
ENV BUILD_CONFIGURATION=Release

# 暴露端口（用于开发服务器）
EXPOSE 8080

# 默认命令
CMD ["swift", "--version"]
