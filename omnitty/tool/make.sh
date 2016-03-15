#/bin/bash

for p in rote-0.2.8 omnitty-0.3.0 omnitty-0.3.0-patched
do
  echo
  echo "=============================================="
  echo " building... $p"
  echo "=============================================="
  cd /root/src/$p && ./configure && make && make install
done
