#!/bin/sh
#https://gist.github.com/ych/4077637
#An install script of omnitty on Debian/Ubuntu

dir=`mktemp -d`
oridir=`pwd`
cd $dir

if [ -x "/usr/bin/wget" ]; then
        wget https://gist.github.com/raw/4077456/45864036e823a8b7faaf5fb2f179486e0500740d/md5sums
        wget https://gist.github.com/raw/4077459/7ba155894489c1be43875d0092da91a7eaeb2d7b/omnitty.conf
        wget http://downloads.sourceforge.net/project/rote/rote/rote-0.2.8/rote-0.2.8.tar.gz
        wget http://downloads.sourceforge.net/project/omnitty/omnitty/omnitty-0.3.0/omnitty-0.3.0.tar.gz
else
        echo "Please install wget!"
        cd $oridir
        rm -rf $dir
        exit
fi

md5sum -c md5sums

if [ $? -ne 0 ]; then
        echo "Please execution again!"
        cd $oridir
        rm -rf $dir
        exit
fi

if [ -x "/usr/bin/aptitude" ]; then
        sudo aptitude -y install libc-dev libncurses-dev
else
        sudo apt-get -y install libc-dev libncurses-dev
fi

tar -xvf rote-0.2.8.tar.gz
tar -xvf omnitty-0.3.0.tar.gz

cd rote-0.2.8
./configure
make
sudo make install

cd ../omnitty-0.3.0
./configure
make
sudo make install

cd ..
sudo cp omnitty.conf /etc/ld.so.conf.d/
sudo ldconfig

cd $oridir
rm -rf $dir
