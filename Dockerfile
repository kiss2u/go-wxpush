# ---------------------------
# 阶段 1: 编译环境 (Builder)
# ---------------------------
FROM golang:1.21-alpine AS builder

WORKDIR /app

# 安装 git (下载依赖可能需要) 和 ssl证书(微信接口是HTTPS)、时区数据
RUN apk add --no-cache git ca-certificates tzdata

# 复制 go.mod 和 go.sum (利用缓存层)
COPY go.mod go.sum ./
RUN go mod download

# 复制源码
COPY . .

# 编译 Go 程序
# CGO_ENABLED=0: 确保静态链接
# -ldflags="-s -w": 压缩体积，去掉调试信息
# -o app: 输出文件名为 app
RUN CGO_ENABLED=0 GOOS=linux go build -ldflags="-s -w" -o app .

# ---------------------------
# 阶段 2: 运行环境 (Scratch)
# ---------------------------
FROM scratch

# 1. 复制时区数据 (解决 -tz 参数报错问题)
COPY --from=builder /usr/share/zoneinfo /usr/share/zoneinfo

# 2. 复制 CA 证书 (解决 HTTPS 请求 x509 报错问题)
COPY --from=builder /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/

# 3. 复制编译好的二进制程序
COPY --from=builder /app/app /go-wxpush

# 设定入口
ENTRYPOINT ["/go-wxpush"]

# 默认参数 (会被 docker-compose 的 command 覆盖)
CMD ["-port", "5566"]
