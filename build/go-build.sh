#!/bin/bash
# cur=$(cd "$(dirname "$0")"; pwd)
cur=$(dirname $(readlink -f "$0"))


# ref docker-registry/build/go-build.sh
apk add upx #alpine-go
# ref _ct\fk-agent\_build.sh
# apt -y install upx
upx -V > /dev/null 2>&1
errCode=$?
test "0" != "$errCode" && sudo apt -y install upx


# use go modules
export GO111MODULE=on
export GOPROXY=https://goproxy.cn

# Build
# CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -a -o virter-linux-amd64 . #${dir}/

# CGO_ENABLED=0 GOOS=linux GOARCH=amd64 \
#   go build -o virter-linux-x64 -v -ldflags "-s -w $flags" ./cmd/virter-linux/

# seq=220213
version="v2501"
seq=$(date +%Y%m%d |sed "s/^20//g"); echo "seq: $seq"
os=linux
onePack(){
  arch=$1
  cd $cur/..
    # go build -x -v -ldflags "-s -w $flags" ./cmd/registry/*.go
    CGO_ENABLED=0 GOOS=linux GOARCH=$arch \
      go build -o build/bin/virter-linux-$arch -v -ldflags "-s -w $flags" ./
    echo "errCode: $?"

  #upx
  cd $cur/../build
    rm -f ./virter-linux-$arch; upx -7 bin/virter-linux-$arch -o ./virter-linux-$arch
    tar -zcvf ./virter-$os-$arch-$version-$seq.tar.gz virter-linux-$arch #--exclude-from=../../.tarignore 
    # clear
    # rm -rf $cur/build/virter-linux-$arch
}
onePack arm & #DO batchMode
onePack arm64 &
onePack amd64 &
wait

ls -lh $cur/../build |grep "virter-linux-"