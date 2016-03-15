FROM centos:6.7
MAINTAINER Jimmy Xu <xjimmyshcn@gmail.com>

RUN yum install -y gcc ncurses-devel

WORKDIR /root/src
COPY tool/make.sh /root
VOLUME /root/src

CMD ["/bin/bash","/root/make.sh"]
