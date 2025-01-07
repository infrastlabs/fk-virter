#!/bin/bash
# cur=$(cd "$(dirname "$0")"; pwd)
cur=$(dirname $(readlink -f "$0"))
cd $cur/..
source /etc/profile
export |grep DOCKER_REG |grep -Ev "PASS|PW"
repo=registry.cn-shenzhen.aliyuncs.com
echo "${DOCKER_REGISTRY_PW_infrastSubUser2}" |docker login --username=${DOCKER_REGISTRY_USER_infrastSubUser2} --password-stdin $repo
repoHub=docker.io
echo "${DOCKER_REGISTRY_PW_dockerhub}" |docker login --username=${DOCKER_REGISTRY_USER_dockerhub} --password-stdin $repoHub

# ref _ct\fk-agent\_build.sh
buidImg=registry.cn-shenzhen.aliyuncs.com/infrastlabs/golang:1.16.8-alpine3.14 #ref: dvp-ci-mgr>> maven:3.6.3-jdk-8-slim
buidImg=golang:1.21
function buildRegistry(){

  # build-agent > pack
  # CGO_ENABLED=0 go build -o agent -v -ldflags "-s -w $flags" ./cmd/agent
  # 
  # ENV GO111MODULE=on
  # ENV GOPROXY=https://goproxy.cn
  # GOPATH: -v to cache

  test -d /mnt/mnt/data && pref=/mnt/data/
  cur2=$(echo $(pwd)|sed "s/_ext/dbox_ext/g") #barge253
  echo "==src: $pref$cur2"
  docker run -v $pref$cur2:/src \
    -e GO111MODULE=on -e GOPROXY=https://goproxy.cn \
    $buidImg \
    sh -c "cd /src && ls -lh && sh build/go-build.sh; ls -lh build/*.tar.gz"

}
buildRegistry


function doBuildx(){
    local tag=$1
    local dockerfile=$2

    repo=registry-1.docker.io
    # repo=registry.cn-shenzhen.aliyuncs.com
    test ! -z "$REPO" && repo=$REPO #@gitac
    img="libvirt-virter:$tag"
    # cache
    ali="registry.cn-shenzhen.aliyuncs.com"
    cimg="libvirt-virter:$tag-cache" #tag-cache
    cache="--cache-from type=registry,ref=$ali/$ns/$cimg --cache-to type=registry,ref=$ali/$ns/$cimg"
    
    plat="--platform linux/amd64,linux/arm64,linux/arm"
    # plat="--platform linux/amd64,linux/arm64" ##,linux/arm

    compile="alpine-compile";
    # test "$plat" != "--platform linux/amd64,linux/arm64,linux/arm" && compile="${compile}-dbg"
    # --build-arg REPO=$repo/ #temp notes, just use dockerHub's
    args="""
    --provenance=false 
    --build-arg REPO=$repo/
    --build-arg COMPILE_IMG=$compile
    --build-arg NOCACHE=$(date +%Y-%m-%d_%H:%M:%S)
    """

    # cd flux
    # test "$plat" != "--platform linux/amd64,linux/arm64,linux/arm" && img="${img}-dbg"
    # test "$plat" != "--platform linux/amd64,linux/arm64,linux/arm" && cimg="${cimg}-dbg"
    cache="--cache-from type=registry,ref=$ali/$ns/$cimg --cache-to type=registry,ref=$ali/$ns/$cimg"
    output="--output type=image,name=$repo/$ns/$img,push=true,oci-mediatypes=true,annotation.author=sam"
    docker buildx build $cache $plat $args $output -f $dockerfile . 
}

cd $cur/..
ns=infrastlabs
ver=v51 #base-v5 base-v5-slim
# doBuildx latest Dockerfile  #none-build
