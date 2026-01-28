# ---------------------------
# 阶段 1: 编译环境 (Builder)
# ---------------------------
FROM golang:1.21-alpine AS builder

WORKDIR /app

# 安装 git, ssl证书, 时区数据
RUN apk add --no-cache git ca-certificates tzdata

# 【修复点】：只复制 go.mod，去掉 go.sum
# 如果项目没有 go.sum，Go 会在 download 时自动处理
COPY go.mod ./
RUN go mod download

# 复制源码
COPY . .

# 编译 Go 程序
# CGO_ENABLED=0: 确保静态链接
# -ldflags="-s -w": 压缩体积
# -o app: 输出文件名为 app
RUN CGO_ENABLED=0 GOOS=linux go build -ldflags="-s -w" -o app .

# ---------------------------
# 阶段 2: 运行环境 (Scratch)
# ---------------------------
FROM scratch

# 1. 复制时区数据
COPY --from=builder /usr/share/zoneinfo /usr/share/zoneinfo

# 2. 复制 CA 证书
COPY --from=builder /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/

# 3. 复制编译好的二进制程序
COPY --from=builder /app/app /go-wxpush

# 设定入口
ENTRYPOINT ["/go-wxpush"]

# 默认参数
CMD ["-port", "5566"]
