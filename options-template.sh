# Customizable variables
ROMNAME=TheParasiteProject
BUILDBASE=$HOME
ROMBASE=${BUILDBASE}/android/$ROMNAME

## Sync
MANIFEST_URL=https://github.com/$ROMNAME/manifest
BRANCH=main
FORCEINIT=true
SHALLOWSYNC=true

## Build configs
BUILD_PROC=${nproc}
#CCACHE=true
#CCACHEDIR=${BUILDBASE}/android/.cache/.ccache
#CCACHESIZE=50G
#CUSTOM_GO_CACHE_DIR=true
#GOCACHEDIR=${BUILDBASE}/android/.cache/go-build
#TCACHE=true
#GTLTO=true ## Zip file error ##

## Build
DEVICE=pdx234
BUILDTYPE=user
BUILD_TARGET="bacon"
OUT_FILE="$ROMNAME*$DEVICE*.zip"
LUNCHCOMMAND=aosp_$DEVICE-$BUILDTYPE

## Output directories
BUILD_OUT=$ROMBASE/out
BUILD_TARGET_OUT=$BUILD_OUT/target/product/$DEVICE
OUTDIR=$CWD/out
