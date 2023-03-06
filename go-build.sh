# use go modules
export GO111MODULE=on
export GOPROXY=https://goproxy.cn

# Build
$RUN pwd && ls -h && CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -a -o virter-linux-amd64 . #${dir}/
