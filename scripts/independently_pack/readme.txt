独立打包功能说明：
功能：用来支持在非tina环境下打包

1、选上配置
make menuconfig  --->Target Images  --->[*]support pack out of tina

2、pack 打包，然后会在out/xx方案/生成一个目录：aw_pack_src，将此目录发放给客户即可

3、aw_pack_src目录使用
./aw_pack_src
|--aw_pack.sh  #执行此脚本即可在aw_pack_src/out/目录生成固件
|--config      #打包配置文件
|--image       #各种镜像文件，可替换，但不能改文件名
|    |--boot0_nand.fex        #nand介质boot0镜像
|    |--boot0_sdcard.fex      #SD卡boot0镜像
|    |--boot0_spinor.fex      #nor介质boot0镜像
|    |--boot0_spinor.fex      #nor介质boot0镜像
|    |--boot_package.fex      #nand和SD卡uboot镜像
|    |--boot_package_nor.fex  #nor介质uboot镜像
|    |--env.fex               #env环境变量镜像
|    |--boot.fex              #内核镜像
|    |--rootfs.fex            #rootfs镜像
|--other       #打包所需的其他文件
|--out         #固件生成目录
|--tmp         #打包使用的临时目录
|--tools       #工具
|--rootfs      #存放rootfs的tar.gz打包,给二次修改使用
|--lib_aw      #拷贝全志方案的库文件，如多媒体组件eyesempp等,给应用app编译链接使用(没有选择这些库，则可能是空文件).
|--README      #关于板级方案的一些说明，例如分区布局等等(无说明则没有这个文件夹)。


