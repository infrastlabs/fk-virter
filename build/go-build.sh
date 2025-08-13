#!/bin/bash
# cur=$(cd "$(dirname "$0")"; pwd)
cur=$(dirname $(readlink -f "$0"))


# ref docker-registry/build/go-build.sh
#########################################
# ref _ct\fk-agent\_build.sh
# apt -y install upx
apk add upx #alpine-go
upx -V > /dev/null 2>&1; errCode=$?
test "0" != "$errCode" && sudo apt -y install upx #if non-sudo
upx -V > /dev/null 2>&1; errCode=$?
if [ "0" != "$errCode" ]; then
  # upx@/usr/local/static/3rd: /usr/bin/bash, curl, gosu, undock, upx, yq, /usr/sbin/tini
  curl -k -fSL -O https://github.com/infrastlabs/docker-x11base/releases/download/v24.12/3rd-latest-amd64.tar.gz
  tar -zxf 3rd-latest-amd64.tar.gz -C /
  find /usr/local/static -type f |sort #view

  # ref docker-x11base\rootfs\src\static\clear\_link.sh
  # link-bin,sbin
  echo -e "\n[link] /usr/sbin/"
  find /usr/local/static -type f |grep "/sbin/" |sort | \
    while read one; do ls -lh $one; ln -s $one /usr/sbin/; done; \

  echo -e "\n[link] /usr/bin/"
  find /usr/local/static -type f |grep "/bin/" |sort | \
    while read one; do ls -lh $one; ln -s $one /usr/bin/; done;
fi

#########################################
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
# LATESTTAG=$(shell git describe --abbrev=0 --tags | tr -d 'v')
# BUILDDATE=$(shell LC_ALL=C date --utc)
# GITHASH=$(shell git rev-parse HEAD)
LATESTTAG=$version
BUILDDATE=$seq
GITHASH=$version
# ERR>> cd /src; git status --porcelain #fatal: detected dubious ownership in repository at '/src'
echo "cur: $cur"
test "/src/build" == "$cur" && chown root:root /src -R #@ct-golang
onePack(){
  arch=$1

	flags="-X \"github.com/LINBIT/virter/cmd.version=$LATESTTAG\" \
		-X \"github.com/LINBIT/virter/cmd.builddate=$BUILDDATE\" \
		-X \"github.com/LINBIT/virter/cmd.githash=$GITHASH\""
  cd $cur/..
    # go build -x -v -ldflags "-s -w $flags" ./cmd/registry/*.go
    mkdir -p build/bin
    CGO_ENABLED=0 GOOS=linux GOARCH=$arch \
      go build -o build/bin/virter-linux-$arch -v -ldflags "-s -w $flags" ./
    echo "errCode: $?"

  #upx
  cd $cur/../build
    rm -f ./virter-linux-$arch; upx -7 bin/virter-linux-$arch -o ./virter-linux-$arch
    tar -zcvf ./virter-$version-$seq-$os-${arch}-upx.tar.gz virter-linux-$arch #--exclude-from=../../.tarignore 
    # clear
    # rm -rf $cur/build/virter-linux-$arch
}
onePack arm & #DO batchMode
onePack arm64 &
onePack amd64 &
onePack ppc64le &
wait

ls -lh $cur/../build |grep "virter-linux-"