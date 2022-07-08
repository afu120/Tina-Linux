$(call inherit-product-if-exists, target/allwinner/r528-common/r528-common.mk)

PRODUCT_PACKAGES +=

PRODUCT_COPY_FILES +=

PRODUCT_AAPT_CONFIG := large xlarge hdpi xhdpi
PRODUCT_AAPT_PERF_CONFIG := xhdpi
PRODUCT_CHARACTERISTICS := musicbox

PRODUCT_BRAND := allwinner
PRODUCT_NAME := h133_p1
PRODUCT_DEVICE := h133-p1
PRODUCT_MODEL := Allwinner h133 p1 board
