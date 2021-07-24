# Build base image for Container Execution

https://doc.dataiku.com/dss/latest/containers/custom-base-images.html

* to build base image with restricted corporate proxy

```
# generate build-base-image with prepend and append dockerfile option

# use https_proxy and use base url
cat Dockerfile.prepend
ENV https_proxy=$http_proxy
RUN yum -y install epel-release \
    && yum -y --disableplugin=fastestmirror update \
    && sed -i -e 's/^mirrorlist=/#mirrorlist=/g ; s/^#baseurl=/baseurl=/g' /etc/yum.repos.d/*.repo

# disable http proxy to direct access
cat Dockerfile.append
ENV http_proxy=""
ENV https_proxy=""
ENV no_proxy=""

$HOME/dss/bin/dssadmin build-base-image --type container-exec --http-proxy $https_proxy  --no-proxy=$no_proxy --dockerfile-append Dockerfile.append --dockerfile-prepend Dockerfile.prepend --without-r --with-py37 --without-cuda

-> this generate dku-exec-base-3bxcxfn7xeopddcvvnsqvolf:dss-9.0.4
You can change de name with tag option

# then test in /admin/general/seting  Containerized execution choose Container engine docker, and add network latelier_dss-network
```

