#!/bin/bash

ARG_CLEANSYNC_SUPPORTED=true

# get current working directory
CWD=$(pwd)

source $CWD/.configs/scripts/script-configs.sh
source $CWD/options.sh

source $FUNCS
source $FUNCS_CUSTOM

# arguments
get_arguments "$@"

# Reset back to current directory
cd $CWD

update_pkg

check_clean_sync

currentshell=$(cat /proc/$$/cmdline)
set_path $currentshell
currentshell=
update_bin

init_git_account

# check for $ROMNAME
if [ ! -d $ROMBASE ]; then
	# create directories
	mkdir -p $ROMBASE

	# initialize repo, sync
	cd $ROMBASE
	repo_init
	repo_init_custom

	copy_additional_manifests
	copy_device_manifests

	repo_update
	repo_sync
fi

if [ -d $ROMBASE ]; then
	# Update sync (and sync again failed sync)
	cd $ROMBASE

	repo_reset

	update_repo_manifest

	copy_additional_manifests
	copy_device_manifests

	repo_update
	repo_sync

	cd $ROMBASE

	# Sources envsetup to execute vendorsetup scripts
	source build/envsetup.sh

	# Apply custom patches
	bash -x $PATCHER $CWD
fi

shutdown_system
