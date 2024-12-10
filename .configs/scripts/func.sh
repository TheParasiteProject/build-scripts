#!/bin/bash

source $CWD/.configs/scripts/script-configs.sh

get_arguments() {
	for arg in "$@"; do
		if [ "$arg" == "--verbose" ] || [ "$arg" == "-v" ]; then
			if [ -z $VERBOSE ]; then
				echo "Verbose mode enabled."
				VERBOSE=true
				set -x
			else
				echo "Verbose mode set to $VERBOSE by options.sh"
			fi
		fi
		if [ "$arg" == "--ccache" ] || [ "$arg" == "-ec" ]; then
			if [ "$ARG_CCACHE_SUPPORTED" = true ]; then
				if [ -z $CCACHE ]; then
					echo "Enable CCache."
					CCACHE=true
				else
					echo "CCache mode set to $CCACHE by options.sh"
				fi
			fi
		fi
		if [ "$arg" == "--thinlto-cache" ] || [ "$arg" == "-tc" ]; then
			if [ "$ARG_TCACHE_SUPPORTED" = true ]; then
				if [ -z $TCACHE ]; then
					echo "Enable ThinLTO Cache."
					TCACHE=true
				else
					echo "ThinLTO Cache mode set to $TCACHE by options.sh"
				fi
			fi
		fi
		if [ "$arg" == "--installclean" ] || [ "$arg" == "-ic" ]; then
			if [ "$ARG_INSTALLCLEAN_SUPPORTED" = true ]; then
				if [ -z $INSTALLCLEAN ]; then
					echo "Install clean build mode enabled."
					INSTALLCLEAN=true
				else
					echo "Install clean build mode set to $INSTALLCLEAN by options.sh"
				fi
			fi
		fi
		if [ "$arg" == "--clean" ] || [ "$arg" == "-c" ]; then
			if [ "$ARG_CLEAN_SUPPORTED" = true ]; then
				if [ -z $CLEAN ]; then
					echo "Clean build mode enabled."
					CLEAN=true
				else
					echo "Clean build mode set to $CLEAN by options.sh"
				fi
			fi
		fi
		if [ "$arg" == "--clean-sync" ] || [ "$arg" == "-cs" ]; then
			if [ "$ARG_CLEANSYNC_SUPPORTED" = true ]; then
				if [ -z $CLEANSYNC ]; then
					echo "Clean sync mode enabled."
					CLEANSYNC=true
				else
					echo "Clean sync mode set to $CLEANSYNC by options.sh"
				fi
			fi
		fi
		if [ "$arg" == "--aclean" ] || [ "$arg" == "-ac" ]; then
			if [ "$ARG_ACLEAN_SUPPORTED" = true ]; then
				if [ -z $ACLEAN ]; then
					echo "All Cache Clean mode enabled."
					ACLEAN=true
				else
					echo "CCache Clean mode set to $ACLEAN by options.sh"
				fi
			fi
		fi
		if [ "$arg" == "--shutdown" ] || [ "$arg" == "-s" ]; then
			if [ -z $SHUTDOWN ]; then
				echo "Shutdown system after tasks complete."
				SHUTDOWN=true
			else
				echo "Shutdown system after tasks complete mode set to $SHUTDOWN by options.sh"
			fi
		fi
	done
}

check_clean_sync() {
	# Check clean sync
	if [ "$CLEANSYNC" = true ]; then
		echo "Cleaning $ROMNAME directory..."
		rm -rf $ROMBASE
	fi
}

init_git_account() {
	# check to see if git is configured, if not prompt user
	if [[ "$(git config --list)" != *"user.email"* ]]; then
		read -p "Enter your git email address: " GITEMAIL
		read -p "Enter your name: " GITNAME
		git config --global user.email $GITEMAIL
		git config --global user.name $GITNAME
	fi
}

update_pkg() {
	# prompt for root and install necessary packages
	if [ -f "/etc/arch-release" ]; then
		if ! yay -h >/dev/null 2>&1; then
			echo "yay command not installed! Start building..."
			sudo pacman -Sy
			sudo pacman -S --needed base-devel git
			git clone https://aur.archlinux.org/yay.git /tmp/yay
			makepkg -si /tmp/yay --noconfirm
		fi
		sudo pacman -Sy aria2 autoconf automake axel base-devel bc bison ccache clang cmake coreutils curl expat flex gcc-multilib git git-lfs github-cli glibc gmp gnupg go gperf htop imagemagick inetutils java-environment lib32-ncurses lib32-readline lib32-zlib libmpc libtool libxcrypt-compat libxml2 libxslt lz4 lzip lzop maven mpfr mtd-utils nano ncftp ncurses openssl patch patchelf perl-switch perl-xml-libxml-simple pkgconf pngcrush pngquant python3 qemu-user-static-binfmt re2c readline rsync schedtool squashfs-tools subversion texinfo unzip vim w3m wget wxwidgets-gtk3 xmlstarlet xz zip zlib gcc-multilib gcc-libs-multilib libtool-multilib lib32-libusb lib32-glibc bash-completion gradle multilib-devel jq --needed --noconfirm
		yay -Sy lib32-ncurses5-compat-libs ncurses5-compat-libs sdl android-devel lineageos-devel lib32-libusb-compat android-sdk android-sdk-platform-tools android-udev repo termcap --needed --noconfirm
		sudo mkdir -p /opt/bin
		sudo rm -Rf /opt/bin/python
		sudo ln -sf /usr/bin/python3 /opt/bin/python
	elif [ -f "/etc/debian_version" ]; then
		sudo apt update
		sudo apt install '^liblz4-.*' '^liblzma.*' '^lzma.*' adb apt-utils aria2 autoconf automake axel bc binfmt-support bison build-essential ccache clang cmake curl expat fastboot flex g++ g++-multilib gawk gcc gcc-multilib gh git git-lfs gnupg golang gperf htop imagemagick lib32ncurses-dev lib32ncurses5-dev lib32readline-dev lib32z1-dev libc6-dev libcap-dev libexpat1-dev libgmp-dev liblz4-tool libmpc-dev libmpfr-dev libncurses5 libncurses5-dev libsdl1.2-dev libssl-dev libswitch-perl libtinfo5 libtool libwxgtk3.2-dev libxml-simple-perl libxml2 libxml2-utils lsb-base lzip lzop maven mtd-utils mtp-tools ncftp ncurses-dev patch patchelf pkg-config pngcrush pngquant python-is-python3 python3 python3-all-dev python3-full python3-venv re2c rsync schedtool software-properties-common squashfs-tools subversion texinfo unzip w3m wget xmlstarlet xsltproc zip zlib1g-dev jq -y
	fi
}

update_bin() {
	if [ ! -d $HOME/bin ]; then
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

set_path() {
	local currentshell="$1"
	if [ "$currentshell" == "bash" ]; then
		profile=$HOME/.profile
	elif [ "$currentshell" == "zsh" ]; then
		profile=$HOME/.zprofile
	fi
	set_profile $profile
	currentshell=
	profile=
}

# check for bin and platform tools in PATH, add if missing, source it
set_profile() {
	local profile="$1"
	if [ ! -z $profile ]; then
		for i in bin bin/platform-tools; do
			if ! grep -q "PATH=\"\$HOME/$i:\$PATH\"" $profile; then
				echo "if [ -d \"\$HOME/$i\" ] ; then" >>$profile
				echo "    PATH=\"\$HOME/$i:\$PATH\"" >>$profile
				echo "fi" >>$profile
			fi
		done
		if ! grep -q "PATH=\"/opt/bin:\$PATH\"" $profile; then
			echo "if [ -d \"/opt/bin/\" ] ; then" >>$profile
			echo "    PATH=\"/opt/bin/:\$PATH\"" >>$profile
			echo "fi" >>$profile
		fi
		source $profile
	fi
	profile=
}

copy_device_manifests() {
	for f in $DEVICE_MANIFESTS_DIR/*.xml; do
		[ -e "$f" ] && fileexists=true && break
	done
	if [ "$fileexists" = true ]; then
		for i in $DEVICE_MANIFESTS_DIR/*.xml; do
			checkmanifest=$(cat $i | grep "manifest" 2>/dev/null)
			if [ ! -z "${checkmanifest}" ]; then
				mkdir -p $ROMBASE/.repo/local_manifests/
				if [ "$FORCE_OVERRIDE_MANIFEST" = true ]; then
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

copy_additional_manifests() {
	for f in $ADDITIONAL_MANIFESTS_DIR/*.xml; do
		[ -e "$f" ] && fileexists=true && break
	done
	if [ "$fileexists" = true ]; then
		for i in $ADDITIONAL_MANIFESTS_DIR/*.xml; do
			checkmanifest=$(cat $i | grep "manifest" 2>/dev/null)
			if [ ! -z "${checkmanifest}" ]; then
				mkdir -p $ROMBASE/.repo/local_manifests/
				if [ "$FORCE_OVERRIDE_MANIFEST" = true ]; then
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

repo_init() {
	if [ "$SHALLOWSYNC" = true ]; then
		repo init --depth=1 --no-repo-verify -u "$MANIFEST_URL" -b $BRANCH -g default,-mips,-darwin,-notdefault --git-lfs
	else
		repo init --no-repo-verify -u "$MANIFEST_URL" -b $BRANCH -g default,-mips,-darwin,-notdefault --git-lfs
	fi
}

repo_sync() {
	if [ "$SHALLOWSYNC" = true ]; then
		repo sync -c --force-sync --optimized-fetch --no-tags --no-clone-bundle --prune -j$(nproc --all)
	else
		repo sync -c --force-sync --optimized-fetch --prune -j$(nproc --all)
	fi
}

repo_update() {
	cd .repo/repo
	git fetch origin main
	git pull origin main
	cd ../../
}

repo_reset() {
	repo forall -c 'git reset --hard'
	repo forall -c 'git clean -fdd'
}

clean_all_cache() {
	if [ "$ACLEAN" = true ]; then
		sudo rm -Rf /tmp/*
		rm -Rf $CCACHEDIR/*
		rm -Rf $GOCACHEDIR/*
	fi
}

clean_error_logs() {
	rm -Rf $BUILD_OUT/error*.log
}

custom_go_cache_dir() {
	if [ "$CUSTOM_GO_CACHE_DIR" = true ]; then
		export GOCACHE=$GOCACHEDIR
		mkdir -p $GOCACHEDIR
	fi
}

set_ccache() {
	if [ "$CCACHE" = true ]; then
		export USE_CCACHE=1
		export CCACHE_EXEC="/usr/bin/ccache"
		export WITHOUT_CHECK_API=true
		export CCACHE_DIR="$CCACHEDIR"
		mkdir -p "$CCACHE_DIR"
		ccache -M $CCACHESIZE
	fi
}

set_thinlto_cache() {
	if [ "$TCACHE" = true ]; then
		export USE_THINLTO_CACHE=true
	fi
}

set_global_thinlto() {
	if [ "$GTLTO" = true ]; then
		export GLOBAL_THINLTO=true
		export SKIP_ABI_CHECKS=true
	fi
}

clean_build() {
	if [ "$INSTALLCLEAN" = true ]; then
		m installclean
	elif [ "$CLEAN" = true ]; then
		m clean
	fi
}

shutdown_system() {
	if [ "$SHUTDOWN" = true ]; then
		shutdown -h now
	fi
}

copy_built_files() {
	if [ ! -d "$OUTDIR" ]; then
		mkdir -p "$OUTDIR"
	fi
	for i in $2; do
		if [ -f "$1"/$i ]; then
			mv "$1"/$i "$OUTDIR"
		fi
	done
}

build_and_copy() {
	if [ ! -z "$BUILD_TARGET" ]; then
		m -j"$BUILD_PROC" "$BUILD_TARGET"
	fi
	if [ $? != 0 ]; then
		copy_built_files "$BUILD_OUT" error.log
		echo "Build failed!"
	elif [ ! -z "$BUILD_OUT" ]; then
		copy_built_files "$BUILD_TARGET_OUT" "$OUT_FILE"
	fi
}

apply_patch() {
	local dogitreset="$1"
	local patchdir="$2"
	# check for patch
	if [ -d $patchdir ]; then
		for f in $patchdir/*.patch; do
			[ -e "$f" ] && fileexists=true && break
		done
		if [ "$fileexists" = true ]; then
			for i in $patchdir/*.patch; do
				patchname="$(echo "${i#\/*patches\/}")"
				pathname="$(echo "${patchname%.*}" | tr + \/)"
				cd $ROMBASE/$pathname
				if [ "$dogitreset" = true ]; then
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
