#!/bin/bash

aw_top=${TINA_BUILD_TOP}
img_path=${LICHEE_PACK_OUT_DIR}
output_path=${img_path}/../aw_pack_src

image_dir=image
config_dir=config
other_dir=other
tools_dir=tools
tmp_dir=tmp
out_dir=out
lib_dir=lib_aw
rootfs_dir=rootfs
readme_dir=README

#creat dir
rm ${output_path} -r 2>/dev/null
mkdir -p ${output_path}

mkdir -p  ${output_path}/${image_dir}
mkdir -p  ${output_path}/${config_dir}
mkdir -p  ${output_path}/${other_dir}
mkdir -p  ${output_path}/${tools_dir}
mkdir -p  ${output_path}/${tmp_dir}
mkdir -p  ${output_path}/${out_dir}
mkdir -p  ${output_path}/${lib_dir}/include
mkdir -p  ${output_path}/${lib_dir}/lib
mkdir -p  ${output_path}/${rootfs_dir}

#this image need to be cp to image_dir
phy_partition_image_list=(
boot0_sdcard.fex
boot0_spinor.fex
boot0_nand.fex
boot_package.fex
boot_package_nor.fex
sunxi.fex
)

fw_cfg_file=(
${img_path}/image.cfg:${config_dir}/image.cfg
)

tools_bin=(
${aw_top}/tools/pack-bintools/src/dragon
${aw_top}/tools/pack-bintools/src/plgvector.dll
${aw_top}/tools/pack-bintools/src/*.dll
${aw_top}/tools/pack-bintools/src/check_sum
)

#cp fw_cfg_file
for file in ${fw_cfg_file[@]} ; do
		cp -f `echo $file | awk -F: '{print $1}'` \
			${output_path}/`echo $file | awk -F: '{print $2}'` 2>/dev/null
done

#cp source file of image.cfg
if [ -f ${output_path}/${config_dir}/image.cfg ]; then

	#parse image.cfg and get file of include.
	fw_image_cfg_list=`cat ${output_path}/${config_dir}/image.cfg | grep "filename" | grep -v ";" | awk -F"," '{print $1}' | awk -F"=" '{print $2}' | awk -F \" '{print $2}'`

	#Classify files
	echo "$fw_image_cfg_list" | while read i
	do
		cp_flag=0
		for file in ${phy_partition_image_list[@]} ; do
			if [  $file = ${i} ]; then
				cp_flag=1
				break
			fi
		done

		if [ ${cp_flag} = 1 ]; then
			cp -f ${img_path}/${i} ${output_path}/${image_dir}  #cp to image

		else
			cp -f ${img_path}/${i} ${output_path}/${other_dir}  #cp to other
		fi
	done
else
	echo "can not find imag.cfg"
	exit 1
fi

#parse sys_partition file and cp download file
if [ -f ${output_path}/${other_dir}/sys_partition.fex ]; then
	sys_par=`cat ${output_path}/${other_dir}/sys_partition.fex | grep "download" | grep -v ";" `
	echo "$sys_par" | while read i
	do
		sys_par_file=`echo "$i" | awk -F \" '{ print $2 }'`
		cp -f ${img_path}/${sys_par_file} ${output_path}/${image_dir}/${sys_par_file}
	done
fi

#cp rootfs.tar.gz
if [ -d ${img_path}/../compile_dir/target/rootfs ]; then
	cd ${img_path}/../compile_dir/target/rootfs
	tar -czf ${output_path}/${rootfs_dir}/rootfs.tar.gz ./
	cd -
fi

#run project hook script that can copy some resource about project
if [ -f ${aw_top}/target/allwinner/${TARGET_BOARD}/${TARGET_PRODUCT}-pack_out.sh ]; then
	${aw_top}/target/allwinner/${TARGET_BOARD}/${TARGET_PRODUCT}-pack_out.sh ${output_path}
fi

#cp board readme dir
if [ -d ${aw_top}/target/allwinner/${TARGET_BOARD}/README ]; then
	mkdir -p ${output_path}/${readme_dir}
	cp -rf ${aw_top}/target/allwinner/${TARGET_BOARD}/README ${output_path}/${readme_dir}
fi

#cp pack tools
for file in ${tools_bin[@]} ; do
		cp -f `echo $file | awk -F: '{print $1}'` \
			${output_path}/${tools_dir} 2>/dev/null
done

#cp pack script
cp ${aw_top}/scripts/independently_pack/aw_pack.sh ${output_path}


echo '----------partitions image is at----------'
echo -e '\033[0;31;1m'
echo ${output_path}
echo -e '\033[0m'
