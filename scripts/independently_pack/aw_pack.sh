#!/bin/bash

usage_help()
{
	echo "------usage-----"
	echo "run ./pack.sh"
	echo "tina image is creat on ./out"
}

aw_pack_dir=
get_aw_pack_dir(){
	cd `dirname $0`
	aw_pack_dir=`pwd`
	echo "aw_pack_dir=${aw_pack_dir}"
	cd -
}

function print_red(){
    echo -e '\033[0;31;1m'
    echo $1
    echo -e '\033[0m'
}

get_aw_pack_dir

if [ ! -d ${aw_pack_dir}/config ]; then
	echo "input erro"
	usage_help
	exit 1
fi

if [ ! -d ${aw_pack_dir}/image ]; then
	echo "input erro"
	usage_help
	exit 1
fi

if [ ! -d ${aw_pack_dir}/other ]; then
	echo "input erro"
	usage_help
	exit 1
fi

rm -rf ${aw_pack_dir}/tmp
rm -rf ${aw_pack_dir}/out

mkdir -p ${aw_pack_dir}/tmp
mkdir -p ${aw_pack_dir}/out

#cp resource
cp -lrf ${aw_pack_dir}/config/* ${aw_pack_dir}/tmp
cp -lrf ${aw_pack_dir}/image/* ${aw_pack_dir}/tmp
cp -lrf ${aw_pack_dir}/other/* ${aw_pack_dir}/tmp

cd ${aw_pack_dir}/tmp
#creat AW image
../tools/dragon image.cfg sys_partition.fex
if [ $? != 0 ]; then
	echo "make AW image fail !!"
	exit 1
fi

image_name=`ls tina*.img`

cp ${image_name} ../out

cd -
rm -rf ${aw_pack_dir}/tmp

echo "aw pack finish !"

echo "-------------------- aw image file in --------------------"
echo ""
print_red "${aw_pack_dir}/out/${image_name}"


