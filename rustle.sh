#!/bin/sh
set -u

main() {
    if [ -z "${1-}" ]; then
	err "provide a url"
    fi

    local _crate_origin="$1"

    local _toolchain="nightly"
    if [ "${2-}" = "--toolchain" ]; then
	if [ -n "${3-}" ]; then
	    _toolchain="$3"
	else
	    err "provide a toolchain"
	fi
    fi

    flag_yes=false
    local _arg
    for _arg in "$@"; do
	if [ "$_arg" = "-y" ]; then
	    flag_yes=true
	fi
    done

    if [ ! -e "/dev/tty" ]; then
	err "/dev/tty does not exist"
    fi

    rustle_up_from "$_crate_origin" "$_toolchain"
}

rustle_up_from() {
    local _crate_origin="$1"
    local _toolchain="$2"

    ask_for_initial_confirmation
    create_temp_dir
    set_globals
    download_crate "$_crate_origin"
    download_multirust
    download_rust_installer
    install_multirust
    set_env_for_multirust
    configure_multirust "$_toolchain"
    build_crate
    unconfigure_multirust
    package_crate
    install_crate
    remove_temp_dir
    print_final_advice
}

ask_for_initial_confirmation() {
    say "preparing to download and build $_crate_origin"

    local _yn
    if [ "$flag_yes" != true ]; then
	cat <<EOF

This script will do its best to install a Rust crate on your system
without any preexisting Rust installation.

It will download a number of tools to temporary locations, then use
them to build, package and install the crate.

It will temporarily occupy at least 1 GB of disk.

It will prompt for your password via sudo.

*WARNING: This is very experimental and could cause serious havok.*

EOF

	read -p "Ready? (y/n) " _yn < /dev/tty
	echo
    else
	_yn=y
    fi

    if [ "$_yn" = "y" ]; then
	return 0
    else
	say "ok, then"
	exit 0
    fi
}

print_final_advice() {
    say "run \`sudo /usr/local/lib/rustle/uninstall.sh\` to uninstall"
    echo
    echo "Have fun."
}

set_globals() {
    multirust_git="https://github.com/brson/multirust.git"
    rust_installer_git="https://github.com/rust-lang/rust-installer.git"
    multirust_dir="$temp_dir/multirust"
    rust_installer_dir="$temp_dir/rust-installer"
    crate_dir="$temp_dir/crate"
    multirust_install_dir="$temp_dir/multirust-install"
    multirust_home="$temp_dir/multirust-home"
    crate_image="$temp_dir/image"
    installer_work_dir="$temp_dir/installer-work"
    installer_out_dir="$temp_dir/installer-out"
}

download_crate() {
    local _crate_origin="$1"

    say "cloning crate $_crate_origin"
    download_git "$_crate_origin" "$crate_dir"
}

download_multirust() {
    say "cloning multirust from $multirust_git"
    download_git "$multirust_git" "$multirust_dir"
}

download_rust_installer() {
    say "cloning rust-installer from $rust_installer_git"
    download_git "$rust_installer_git" "$rust_installer_dir"
}

download_git() {
    local _remote_url="$1"
    local _local_path="$2"

    say "cloning $1 to $2"
    git clone "$1" "$2" --depth 1
    need_ok "failed to clone repo $1"

    (cd "$2" && git submodule update --init)
    need_ok "failed to update submodules"
}

install_multirust() {
    (cd "$multirust_dir" && sh ./build.sh)
    need_ok "failed to build multirust"

    say "installing multirust to temporary location $multirust_install_dir"

    (cd "$multirust_dir" && sh ./install.sh --prefix="$multirust_install_dir" --disable-ldconfig)
    need_ok "failed to install multirust to temporary location"
}

set_env_for_multirust() {
    export PATH="$multirust_install_dir/bin:$PATH"
    export LD_LIBRARY_PATH="$multirust_install_dir/lib:$PATH"
    export DYLD_LIBRARY_PATH="$multirust_install_dir/lib:$PATH"
    export MULTIRUST_HOME="${MULTIRUST_HOME-$multirust_home}"
}

# This creates and removes an override so that if somebody wants to use
# MULTIRUST_HOME it doesn't interfere with their defaults.
configure_multirust() {
    local _toolchain="$1"

    say "installing Rust $_toolchain to temporary location"

    (cd "$crate_dir" && multirust override "$_toolchain")
    need_ok "failed to download and install Rust $_toolchain"
}

unconfigure_multirust() {
    (cd "$crate_dir" && multirust remove-override)
    need_ok "failed to unconfigure multirust"
}

build_crate() {
    (cd "$crate_dir" && cargo build --release)
    if [ $? != 0 ]; then
	unconfigure_multirust
	err "failed to build crate"
    fi
}

package_crate() {
    get_crate_name
    local _crate_name="$RETVAL"

    create_crate_image

    sh "$rust_installer_dir/gen-installer.sh" \
	--product-name=Rustle \
	--rel-manifest-dir=rustle \
	--image-dir="$crate_image" \
	--work-dir="$installer_work_dir" \
	--output-dir="$installer_out_dir" \
	--package-name="rustled-crate" \
	--component-name="$_crate_name"
    need_ok "failed to create installer for crate"
}

get_crate_name() {
    if [ ! -e "$crate_dir/Cargo.toml" ]; then
	err "no Cargo.toml in crate root directory"
    fi

    local _l
    local _found=false
    # Extracting the crate name from the Cargo.toml. Pretty sketchy
    local _crate_name="$(cat "$crate_dir/Cargo.toml" | grep "^name *=" | sed "s/.*\"\(.*\)\".*/\1/" | head -n1)"
    need_ok "failed to extract crate name from $crate_dir/Cargo.toml"
    say "detected crate name is $_crate_name"
    RETVAL="$_crate_name"
}

create_crate_image() {
    mkdir -p "$crate_image/bin"
    need_ok "failed to create directory for crate image"

    # Only pick executables for now
    local _f
    local _picked_something=false
    for _f in "$crate_dir/target/release/"*; do
	if [ -x "$_f" -a ! -d "$_f" ]; then
	    say "choosing $_f for installation"
	    cp "$_f" "$crate_image/bin/"
	    need_ok "failed to copy file $_f to crate image"
	    _picked_something=true
	fi
    done

    if [ "$_picked_something" = false ]; then
	err "found no suitable files to package. Does this crate produce an executable?"
    fi
}

install_crate() {
    sudo sh "$installer_work_dir/rustled-crate/install.sh"
    need_ok "failed to install crate"
}

create_temp_dir() {
    temp_dir="$(mktemp -d 2>/dev/null \
             || mktemp -d -t 'rustle-tmp' 2>/dev/null \
             || create_temp_dir_fallback)"
    assert_nz "$temp_dir" "temp_dir"

    verbose_say "using temp dir $temp_dir"
}

create_temp_dir_fallback() {
    local _tmpdir=`pwd`/rustle-tmp

    verbose_say "using fallback tempdir method!"

    rm -Rf "$_tmpdir"
    need_ok "failed to remove temporary directory"

    mkdir -p "$_tmpdir"
    need_ok "failed to create create temporary directory"

    echo $_tmpdir
}

remove_temp_dir() {
    if [ -z "${temp_dir-}" ]; then
	# Error occurred before initialization
	return 0
    fi
    say "cleaning up temporary directory"
    if [ -e "$temp_dir" ]; then
	rm -Rf "$temp_dir"
	if [ $? != 0 ]; then
	    say "warning: unable to remove temp directory $temp_dir"
	fi
    fi
}

# Standard utilities

say() {
    echo "rustle: $1"
}

say_err() {
    say "$1" >&2
}

verbose_say() {
    if [ "${VERBOSE-}" = true ]; then
	say "$1"
    fi
}

err() {
    say "$1" >&2
    remove_temp_dir
    exit 1
}

need_cmd() {
    if ! command -v $1 > /dev/null 2>&1
    then err "need $1"
    fi
}

need_ok() {
    if [ $? != 0 ]; then err "$1"; fi
}

assert_nz() {
    if [ -z "$1" ]; then err "assert_nz $2"; fi
}

# Ensure various commands exist
need_cmd dirname
need_cmd basename
need_cmd mkdir
need_cmd cat
need_cmd curl
need_cmd mktemp
need_cmd rm
need_cmd egrep
need_cmd grep
need_cmd file
need_cmd uname
need_cmd tar
need_cmd sed
need_cmd sh
need_cmd mv
need_cmd awk
need_cmd cut
need_cmd sort
need_cmd shasum
need_cmd date
need_cmd head
need_cmd git
need_cmd read
need_cmd sudo

main "$@"

