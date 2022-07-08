ifneq ($(__target/allwinner/d1s-common/BoardConfigCommon.mk_inc),1)
__target/allwinner/d1s-common/BoardConfigCommon.mk_inc=1

-include target/allwinner/generic/common.mk

TARGET_CPU_ABI := lp64d
TARGET_CPU_ABI2 :=
TARGET_CPU_SMP := false
TARGET_LINUX_VERSION:=5.4
TARGET_UBOOT_VERSION:=2018
TARGET_ARCH := riscv
TARGET_ARCH_VARIANT := rv64gcxthead
TARGET_CPU_VARIANT := c910

TARGET_ARCH_PACKAGES := sunxi

TARGET_BOARD_PLATFORM := d1s

endif #__target/allwinner/d1s-common/BoardConfigCommon.mk_inc
