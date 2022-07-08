$(call inherit-product-if-exists, target/allwinner/d1-common/d1-common.mk)

PRODUCT_PACKAGES +=

PRODUCT_COPY_FILES +=

PRODUCT_AAPT_CONFIG := large xlarge hdpi xhdpi
PRODUCT_AAPT_PERF_CONFIG := xhdpi
PRODUCT_CHARACTERISTICS := musicbox

PRODUCT_BRAND := allwinner
PRODUCT_NAME := d1_nezha
PRODUCT_DEVICE := d1-nezha
PRODUCT_MODEL := Allwinner d1 dev board
