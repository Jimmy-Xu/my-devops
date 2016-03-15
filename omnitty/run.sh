#/bin/bash

WORKDIR=$(cd `dirname $0`; pwd)

echo
echo "=============================================="
echo " building image..."
echo "=============================================="
docker build --rm -t xjimmyshcn/omnitty .

echo
echo "=============================================="
echo " compiling omnitty..."
echo "=============================================="
docker run -it --rm -v $(pwd)/src:/root/src xjimmyshcn/omnitty

echo
echo "=============================================="
echo " installing ..."
echo "=============================================="
for p in rote-0.2.8 omnitty-0.3.0 omnitty-0.3.0-patched
do
  echo "----------------------------------"
  echo " install $p"
  echo "----------------------------------"
  cd ${WORKDIR}/src/$p && sudo make install
done

echo -e "\nDone!\n"
