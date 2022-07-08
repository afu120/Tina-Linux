$(call inherit-product-if-exists, target/allwinner/f133-common/f133-common.mk)

PRODUCT_PACKAGES +=

PRODUCT_COPY_FILES +=

PRODUCT_AAPT_CONFIG := large xlarge hdpi xhdpi
PRODUCT_AAPT_PERF_CONFIG := xhdpi
PRODUCT_CHARACTERISTICS := musicbox

PRODUCT_BRAND := allwinner
PRODUCT_NAME := f133_evb1
PRODUCT_DEVICE := f133-evb1
PRODUCT_MODEL := Allwinner f133 evb board
