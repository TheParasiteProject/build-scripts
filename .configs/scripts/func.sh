#!/bin/bash

get_arguments () {
	for arg in "$@";
	do
	    if [ "$arg" == "--verbose" ] || [ "$arg" == "-v" ];
	    then
	        if [ -z $VERBOSE ];
	        then
				echo "Verbose mode enabled."
				VERBOSE=true
				set -x
			else
				echo "Verbose mode set to $VERBOSE by options.txt"
			fi
	    fi
	    if [ "$arg" == "--bootimage" ] || [ "$arg" == "-b" ];
	    then
	        if [ "$ARG_BOOTIMG_SUPPORTED" = true ];
	        then
		        if [ -z $BOOTIMG ];
		        then
					echo "Build bootimage only."
					BOOTIMG=true
				else
					echo "Bootimage build mode set to $BOOTIMG by options.txt"
				fi
			fi
	    fi
		if [ "$arg" == "--ccache" ] || [ "$arg" == "-ec" ];
	    then
	        if [ "$ARG_CCACHE_SUPPORTED" = true ];
	        then
		        if [ -z $CCACHE ];
		        then
					echo "Enable CCache."
					CCACHE=true
				else
					echo "CCache mode set to $CCACHE by options.txt"
				fi
			fi
		fi
		if [ "$arg" == "--thinlto-cache" ] || [ "$arg" == "-tc" ];
	    then
	        if [ "$ARG_TCACHE_SUPPORTED" = true ];
	        then
		        if [ -z $TCACHE ];
		        then
					echo "Enable ThinLTO Cache."
					TCACHE=true
				else
					echo "ThinLTO Cache mode set to $TCACHE by options.txt"
				fi
			fi
		fi
		if [ "$arg" == "--clean" ] || [ "$arg" == "-c" ];
	    then
	        if [ "$ARG_CLEAN_SUPPORTED" = true ];
	        then
		        if [ -z $CLEAN ];
		        then
					echo "Clean build mode enabled."
					CLEAN=true
				else
					echo "Clean build mode set to $CLEAN by options.txt"
				fi
			fi
		fi
		if [ "$arg" == "--clean-sync" ] || [ "$arg" == "-cs" ];
	    then
	        if [ "$ARG_CLEANSYNC_SUPPORTED" = true ];
	        then
		        if [ -z $CLEANSYNC ];
		        then
					echo "Clean sync mode enabled."
					CLEANSYNC=true
				else
					echo "Clean sync mode set to $CLEANSYNC by options.txt"
				fi
			fi
		fi
		if [ "$arg" == "--aclean" ] || [ "$arg" == "-ac" ];
	    then
	        if [ "$ARG_ACLEAN_SUPPORTED" = true ];
	        then
		        if [ -z $ACLEAN ];
		        then
					echo "All Cache Clean mode enabled."
					ACLEAN=true
				else
					echo "CCache Clean mode set to $ACLEAN by options.txt"
				fi
			fi
		fi
		if [ "$arg" == "--shutdown" ] || [ "$arg" == "-s" ];
	    then
	        if [ -z $SHUTDOWN ];
	        then
				echo "Shutdown system after tasks complete."
				SHUTDOWN=true
			else
				echo "Shutdown system after tasks complete mode set to $SHUTDOWN by options.txt"
			fi
		fi
	done
}

check_clean_sync () {
    # Check clean sync
    if [ "$CLEANSYNC" = true ];
    then
    	echo "Cleaning $ROMNAME directory..."
    	rm -rf $ROMBASE
    fi
}

init_git_account () {
	# check to see if git is configured, if not prompt user
	if [[ "$(git config --list)" != *"user.email"* ]];
	then
		read -p "Enter your git email address: " GITEMAIL
		read -p "Enter your name: " GITNAME
		git config --global user.email $GITEMAIL
		git config --global user.name $GITNAME
	fi
}

update_apt () {
	# prompt for root and install necessary packages
	sudo apt update
	sudo apt install aria2 wget '^liblz4-.*' '^liblzma.*' '^lzma.*' adb apt-utils autoconf automake axel bc binfmt-support bison build-essential ccache clang cmake curl expat fastboot flex g++ g++-multilib gawk gcc gcc-multilib git gnupg gperf htop imagemagick lib32ncurses-dev lib32ncurses5-dev lib32readline-dev lib32z1-dev libc6-dev libcap-dev libexpat1-dev libgmp-dev liblz4-tool libmpc-dev libmpfr-dev libncurses5 libncurses5-dev libsdl1.2-dev libssl-dev libswitch-perl libtinfo5 libtool libwxgtk3.2-dev libxml-simple-perl libxml2 libxml2-utils lzip lzop maven mtd-utils ncftp ncurses-dev patch patchelf pkg-config pngcrush pngquant python3-all-dev python-is-python3 python3 re2c rsync schedtool squashfs-tools subversion texinfo unzip w3m xsltproc zip zlib1g-dev software-properties-common gh lsb-base xmlstarlet python3-venv python3-full mtp-tools -y
	sudo apt -y upgrade
}

update_bin () {
	if [ ! -d $HOME/bin ];
	then
		# create bin directory and get repo
		mkdir -p $HOME/bin
	fi

	# clean, download, and unzip latest platform tools, repo
	rm -rf $HOME/bin/platform-tools-latest-linux.zip
	rm -rf $HOME/bin/platform-tools-latest-linux*.zip
	rm -rf $HOME/bin/platform-tools
	aria2c https://dl.google.com/android/repository/platform-tools-latest-linux.zip -d $HOME/bin -o platform-tools-latest-linux.zip
	unzip $HOME/bin/platform-tools-latest-linux.zip -d $HOME/bin
	rm -rf $HOME/bin/platform-tools-latest-linux.zip
	rm -rf $HOME/bin/platform-tools-latest-linux*.zip
	
	rm -rf $HOME/bin/repo
	aria2c https://storage.googleapis.com/git-repo-downloads/repo -d $HOME/bin
	chmod a+x $HOME/bin/repo
}

set_path () {
	local currentshell="$1"
	if [ "$currentshell" == "bash" ];
	then
		profile=$HOME/.profile
	elif [ "$currentshell" == "zsh" ];
	then
		profile=$HOME/.zprofile
	fi
	set_profile $profile
	currentshell=
	profile=
}

# check for bin and platform tools in PATH, add if missing, source it
set_profile () {
	local profile="$1"
	if [ ! -z $profile ];
	then
		for i in bin bin/platform-tools;
		do
			if ! grep -q "PATH=\"\$HOME/$i:\$PATH\"" $profile ; 
			then
				echo "if [ -d \"\$HOME/$i\" ] ; then" >> $profile
				echo "    PATH=\"\$HOME/$i:\$PATH\"" >> $profile
				echo "fi" >> $profile
			fi
		done
		source $profile
	fi
	profile=
}

copy_device_manifests () {
	for f in $DEVICE_MANIFESTS_DIR/*.xml;
	do
		[ -e "$f" ] && fileexists=true && break
	done
	if [ "$fileexists" = true ];
	then
		for i in $DEVICE_MANIFESTS_DIR/*.xml;
		do
			checkmanifest=`cat $i | grep "manifest" 2>/dev/null`
			if [ ! -z "${checkmanifest}" ];
			then
				mkdir -p $ROMBASE/.repo/local_manifests/
				if [ "$FORCE_OVERRIDE_MANIFEST" = true ];
				then
					/bin/cp -rf $i $ROMBASE/.repo/local_manifests/
				else
					cp $i $ROMBASE/.repo/local_manifests/
				fi
			fi
			checkmanifest=
		done
	fi
	fileexists=
}

copy_additional_manifests () {
	for f in $ADDITIONAL_MANIFESTS_DIR/*.xml;
	do
		[ -e "$f" ] && fileexists=true && break
	done
	if [ "$fileexists" = true ];
	then
		for i in $ADDITIONAL_MANIFESTS_DIR/*.xml;
		do
			checkmanifest=`cat $i | grep "manifest" 2>/dev/null`
			if [ ! -z "${checkmanifest}" ];
			then
				mkdir -p $ROMBASE/.repo/local_manifests/
				if [ "$FORCE_OVERRIDE_MANIFEST" = true ];
				then
					/bin/cp -rf $i $ROMBASE/.repo/local_manifests/
				else
					cp $i $ROMBASE/.repo/local_manifests/
				fi
			fi
			checkmanifest=
		done
	fi
	fileexists=
}

repo_init () {
	repo init --depth=1 --no-repo-verify -u https://github.com/$ROMNAME/manifest -b $BRANCH -g default,-mips,-darwin,-notdefault
}

repo_sync () {
	repo sync -c --force-sync --optimized-fetch --no-tags --no-clone-bundle --prune -j$(nproc --all)
}

repo_reset () {
	repo forall -c 'git reset --hard'
	repo forall -c 'git clean -fdd'
}

clean_all_cache () {
	if [ "$ACLEAN" = true ];
	then
		sudo rm -Rf /tmp/*
		rm -Rf $CCACHEDIR/*
		rm -Rf $GOCACHEDIR/*
	fi
}

clean_error_logs () {
	rm -Rf $ROMBASE/out/error*.log
}

custom_go_cache_dir () {
	if [ "$CUSTOM_GO_CACHE_DIR" = true ];
	then
		export GOCACHE=$GOCACHEDIR
		mkdir -p $GOCACHEDIR
	fi
}

set_ccache () {
	if [ "$CCACHE" = true ];
	then
		export USE_CCACHE=1
		export CCACHE_EXEC="/usr/bin/ccache"
		export WITHOUT_CHECK_API=true
		export CCACHE_DIR="$CCACHEDIR"
		mkdir -p $CCACHE_DIR
		ccache -M 50G
	fi
}

set_thinlto_cache () {
	if [ "$TCACHE" = true ];
	then
		export USE_THINLTO_CACHE=true
	fi
}

set_global_thinlto () {
	if [ "$GTLTO" = true ];
	then
		export GLOBAL_THINLTO=true
		export SKIP_ABI_CHECKS=true
	fi
}

clean_build () {
	if [ "$CLEAN" = true ];
	then
		rm -Rf $ROMBASE/out
		m clean
	fi
}

shutdown_system () {
	if [ "$SHUTDOWN" = true ];
	then
		shutdown -h now
	fi
}

build_and_copy () {
	local buildtarget="$1"
	local buildout="$2"
	local outdir="$3"
	if [ "$BUILDDIST" = true ];
	then
		m -j${nproc} dist
	else
		m -j${nproc} "$buildtarget"
	fi
	if [ $? != 0 ];
	then
		outfile=$(ls -rt $ROMBASE/out/error*.log | tail -1)
		mkdir -p $outdir
		mv $outfile $outdir
		echo "Build failed!"
		exit 1
	elif [ ! -z "$buildout" ];
	then
		target_out_dir=
		if [ "$BUILDDIST" = true ];
		then
			target_out_dir=$ROMBASE/out/dist
		else
			target_out_dir=$ROMBASE/out/target/product/$DEVICE
		fi
		for i in $(echo "$buildout" | tr ";" "\n");
		do
			if [ -f $(ls -rt $target_out_dir/$i | tail -1) ];
			then
				outfile=$(ls -rt $target_out_dir/$i | tail -1)
				mkdir -p $outdir
				mv $outfile $outdir
			fi
		done
	fi
	buildtarget=
	buildout=
	outdir=
	outfile=
}

apply_patch () {
	local dogitreset="$1"
	local patchdir="$2"
	# check for patch
	if [ -d $patchdir ]; 
	then
		for f in $patchdir/*.patch;
		do
			[ -e "$f" ] && fileexists=true && break
		done
		if [ "$fileexists" = true ];
		then
			for i in $patchdir/*.patch;
			do
				patchname="$(echo "${i#\/*patches\/}")"
				pathname="$(echo "${patchname%.*}" | tr + \/)"
				cd $ROMBASE/$pathname
				if [ "$dogitreset" = true ];
				then
					git reset --hard
				fi
				git apply $patchdir/$patchname
			done
		fi
		cd $CWD
	fi
	dogitreset=
	patchdir=
	fileexists=
	patchname=
	pathname=
}
