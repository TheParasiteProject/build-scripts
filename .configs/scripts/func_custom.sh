#!/bin/bash

repo_init_custom () {
	return
}

repo_sync_custom () {
	return
}

update_repo_manifest () {
	# Update sync (and sync again failed sync)
	cd $ROMBASE/.repo/manifests
	git reset --hard
	git clean -f
	git pull 2>/dev/null
	if [ $? != 0 ];
	then
		if [ "$FORCEINIT" = true ];
		then
			cd $ROMBASE
			echo "git failed to update manifest. Do repo init again..."
			repo_init
		fi
	fi
}

build_custom () {
	lunch $LUNCHCOMMAND
	
	if [ "$BOOTIMG" = true ];
	then
		buildtarget="bootimage dtboimage"
		buildout="boot.img;dtbo.img"
		outdir="$OUTDIR"
		build_and_copy "$buildtarget" "$buildout" "$outdir"
	elif [ "$BUILDDIST" = true ];
	then
		buildtarget="dist"
		buildout="$ROMNAME*$DEVICE*.zip"
		outdir="$OUTDIR"
		build_and_copy "$buildtarget" "$buildout" "$outdir"
	else
		buildtarget="bacon"
		buildout="$ROMNAME*$DEVICE*.zip"
		outdir="$OUTDIR"
		build_and_copy "$buildtarget" "$buildout" "$outdir"
	fi
	
	buildtarget=
	buildout=
	outdir=
}
