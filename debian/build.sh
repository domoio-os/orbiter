
#!/bin/bash

BASE_DIR=orbiter_0.1.0
TMP_DIR=`mktemp -d`
DIR=${TMP_DIR}/${BASE_DIR}
mkdir  ${DIR}

echo "DIR: ${DIR}"

cp -r templates/* ${DIR}
cp -r DEBIAN ${DIR}
mkdir ${DIR}/opt
cp -r ../rel/orbiter ${DIR}/opt

dpkg-deb --build ${DIR}
