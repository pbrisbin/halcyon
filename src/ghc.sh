map_ghc_version_to_source_url () {
	local ghc_version
	expect_args ghc_version -- "$@"

	case "${ghc_version}" in
	'7.10.1-rc2')	echo 'https://downloads.haskell.org/~ghc/7.10.1-rc2/ghc-7.10.0.20150123-src.tar.xz';;
	'7.8.4')	echo 'https://downloads.haskell.org/~ghc/7.8.4/ghc-7.8.4-src.tar.xz';;
	'7.8.3')	echo 'https://downloads.haskell.org/~ghc/7.8.3/ghc-7.8.3-src.tar.xz';;
	'7.8.2')	echo 'https://downloads.haskell.org/~ghc/7.8.2/ghc-7.8.2-src.tar.xz';;
	'7.6.3')	echo 'https://downloads.haskell.org/~ghc/7.6.3/ghc-7.6.3-src.tar.bz2';;
	'7.6.1')	echo 'https://downloads.haskell.org/~ghc/7.6.1/ghc-7.6.1-src.tar.bz2';;
	'7.4.2')	echo 'https://downloads.haskell.org/~ghc/7.4.2/ghc-7.4.2-src.tar.bz2';;
	'7.2.2')	echo 'https://downloads.haskell.org/~ghc/7.2.2/ghc-7.2.2-src.tar.bz2';;
	'7.0.4')	echo 'https://downloads.haskell.org/~ghc/7.0.4/ghc-7.0.4-src.tar.bz2';;
	'6.12.3')	echo 'https://downloads.haskell.org/~ghc/6.12.3/ghc-6.12.3-src.tar.bz2';;
	'6.10.4')	echo 'https://downloads.haskell.org/~ghc/6.10.4/ghc-6.10.4-src.tar.bz2';;
	*)
		log_error "Unexpected GHC version for source: ${ghc_version}"
		return 1
	esac
}


map_ghc_version_to_linux_x86_64_gmp10_url () {
	local ghc_version
	expect_args ghc_version -- "$@"

	case "${ghc_version}" in
	'7.10.1-rc2')	echo 'https://downloads.haskell.org/~ghc/7.10.1-rc2/ghc-7.10.0.20150123-x86_64-unknown-linux-deb7.tar.xz';;
	'7.8.4')	echo 'https://downloads.haskell.org/~ghc/7.8.4/ghc-7.8.4-x86_64-unknown-linux-deb7.tar.xz';;
	'7.8.3')	echo 'https://downloads.haskell.org/~ghc/7.8.3/ghc-7.8.3-x86_64-unknown-linux-deb7.tar.xz';;
	'7.8.2')	echo 'https://downloads.haskell.org/~ghc/7.8.2/ghc-7.8.2-x86_64-unknown-linux-deb7.tar.xz';;
	*)
		log_error "Unexpected GHC version for Linux (x86_64 libgmp.so.10): ${ghc_version}"
		return 1
	esac
}


map_ghc_version_to_linux_x86_64_gmp3_url () {
	local ghc_version
	expect_args ghc_version -- "$@"

	case "${ghc_version}" in
	'7.8.4')	echo 'https://downloads.haskell.org/~ghc/7.8.4/ghc-7.8.4-x86_64-unknown-linux-centos65.tar.xz';;
	'7.8.3')	echo 'https://downloads.haskell.org/~ghc/7.8.3/ghc-7.8.3-x86_64-unknown-linux-centos65.tar.xz';;
	'7.8.2')	echo 'https://downloads.haskell.org/~ghc/7.8.2/ghc-7.8.2-x86_64-unknown-linux-centos65.tar.xz';;
	'7.6.3')	echo 'https://downloads.haskell.org/~ghc/7.6.3/ghc-7.6.3-x86_64-unknown-linux.tar.bz2';;
	'7.6.1')	echo 'https://downloads.haskell.org/~ghc/7.6.1/ghc-7.6.1-x86_64-unknown-linux.tar.bz2';;
	'7.4.2')	echo 'https://downloads.haskell.org/~ghc/7.4.2/ghc-7.4.2-x86_64-unknown-linux.tar.bz2';;
	'7.2.2')	echo 'https://downloads.haskell.org/~ghc/7.2.2/ghc-7.2.2-x86_64-unknown-linux.tar.bz2';;
	'7.0.4')	echo 'https://downloads.haskell.org/~ghc/7.0.4/ghc-7.0.4-x86_64-unknown-linux.tar.bz2';;
	'6.12.3')	echo 'https://downloads.haskell.org/~ghc/6.12.3/ghc-6.12.3-x86_64-unknown-linux-n.tar.bz2';;
	'6.10.4')	echo 'https://downloads.haskell.org/~ghc/6.10.4/ghc-6.10.4-x86_64-unknown-linux-n.tar.bz2';;
	*)
		log_error "Unexpected GHC version for Linux (x86_64 libgmp.so.3): ${ghc_version}"
		return 1
	esac
}


map_ghc_version_to_freebsd_x86_64_url () {
	local ghc_version
	expect_args ghc_version -- "$@"

	case "${ghc_version}" in
	'7.8.4')	echo 'https://downloads.haskell.org/~ghc/7.8.4/ghc-7.8.4-x86_64-portbld-freebsd.tar.xz';;
	'7.8.3')	echo 'https://downloads.haskell.org/~ghc/7.8.3/ghc-7.8.3-x86_64-portbld-freebsd.tar.xz';;
	'7.8.2')	echo 'https://downloads.haskell.org/~ghc/7.8.2/ghc-7.8.2-x86_64-portbld-freebsd.tar.xz';;
	'7.6.3')	echo 'https://downloads.haskell.org/~ghc/7.6.3/ghc-7.6.3-x86_64-unknown-freebsd.tar.bz2';;
	'7.6.1')	echo 'https://downloads.haskell.org/~ghc/7.6.1/ghc-7.6.1-x86_64-unknown-freebsd.tar.bz2';;
	'7.4.2')	echo 'https://downloads.haskell.org/~ghc/7.4.2/ghc-7.4.2-x86_64-unknown-freebsd.tar.bz2';;
	'7.2.2')	echo 'https://downloads.haskell.org/~ghc/7.2.2/ghc-7.2.2-x86_64-unknown-freebsd.tar.bz2';;
	'7.0.4')	echo 'https://downloads.haskell.org/~ghc/7.0.4/ghc-7.0.4-x86_64-unknown-freebsd.tar.bz2';;
	'6.12.3')	echo 'https://downloads.haskell.org/~ghc/6.12.3/ghc-6.12.3-amd64-freebsd-8.tar.bz2';;
	*)
		log_error "Unexpected GHC version for FreeBSD: ${ghc_version}"
		return 1
	esac
}


map_ghc_version_to_osx_x86_64_url () {
	local ghc_version
	expect_args ghc_version -- "$@"

	# TODO: Improve cross-version compatibility.
	case "${ghc_version}" in
	'7.10.1-rc2')	echo 'http://www.ozonehouse.com/mark/platform/ghc-7.10.0.20150123-x86_64-apple-darwin.tar.bz2';;
	'7.8.4')	echo 'http://www.ozonehouse.com/mark/platform/ghc-7.8.4-x86_64-apple-darwin.tar.bz2';;
	'7.8.3')	echo 'https://downloads.haskell.org/~ghc/7.8.3/ghc-7.8.3-x86_64-apple-darwin.tar.xz';; # 10.7+
	'7.8.2')	echo 'https://downloads.haskell.org/~ghc/7.8.2/ghc-7.8.2-x86_64-apple-darwin-mavericks.tar.xz';; # 10.9 only?
	'7.6.3')	echo 'https://downloads.haskell.org/~ghc/7.6.3/ghc-7.6.3-x86_64-apple-darwin.tar.bz2';; # 10.7+?
	'7.6.1')	echo 'https://downloads.haskell.org/~ghc/7.6.1/ghc-7.6.1-x86_64-apple-darwin.tar.bz2';; # 10.7+?
	'7.4.2')	echo 'https://downloads.haskell.org/~ghc/7.4.2/ghc-7.4.2-x86_64-apple-darwin.tar.bz2';; # 10.7+?
	'7.2.2')	echo 'https://downloads.haskell.org/~ghc/7.2.2/ghc-7.2.2-x86_64-apple-darwin.tar.bz2';; # 10.6+?
	'7.0.4')	echo 'https://downloads.haskell.org/~ghc/7.0.4/ghc-7.0.4-x86_64-apple-darwin.tar.bz2';; # 10.6+?
	*)
		log_error "Unexpected GHC version for OS X (x86_64): ${ghc_version}"
		return 1
	esac
}


map_base_package_version_to_ghc_version () {
	local base_version
	expect_args base_version -- "$@"

	case "${base_version}" in
	'4.8.0.0')	echo '7.10.1-rc2';;
	'4.7.0.2')	echo '7.8.4';;
	'4.7.0.1')	echo '7.8.3';;
	'4.7.0.0')	echo '7.8.2';;
	'4.6.0.1')	echo '7.6.3';;
	'4.6.0.0')	echo '7.6.1';;
	'4.5.1.0')	echo '7.4.2';;
	'4.4.1.0')	echo '7.2.2';;
	'4.3.1.0')	echo '7.0.4';;
	'4.2.0.2')	echo '6.12.3';;
	'4.1.0.0')	echo '6.10.4';;
	*)
		log_error "Unexpected base package version: ${base_version}"
		return 1
	esac
}


map_constraints_to_ghc_version () {
	local constraints
	expect_args constraints -- "$@"

	local base_version
	if ! base_version=$( match_package_version 'base' <<<"${constraints}" ); then
		log_warning 'Expected base package constraint'
		return 0
	fi

	map_base_package_version_to_ghc_version "${base_version}" || return 1
}


create_ghc_tag () {
	local ghc_version ghc_magic_hash
	expect_args ghc_version ghc_magic_hash -- "$@"

	create_tag '' '' '' '' '' \
		"${ghc_version}" "${ghc_magic_hash}" \
		'' '' '' '' \
		''
}


detect_ghc_tag () {
	local tag_file
	expect_args tag_file -- "$@"

	local tag_pattern
	tag_pattern=$( create_ghc_tag '.*' '.*' )

	local tag
	if ! tag=$( detect_tag "${tag_file}" "${tag_pattern}" ); then
		log_error 'Failed to detect GHC tag'
		return 1
	fi

	echo "${tag}"
}


derive_ghc_tag () {
	local tag
	expect_args tag -- "$@"

	local ghc_version ghc_magic_hash
	ghc_version=$( get_tag_ghc_version "${tag}" )
	ghc_magic_hash=$( get_tag_ghc_magic_hash "${tag}" )

	create_ghc_tag "${ghc_version}" "${ghc_magic_hash}"
}


format_ghc_id () {
	local tag
	expect_args tag -- "$@"

	local ghc_version ghc_magic_hash
	ghc_version=$( get_tag_ghc_version "${tag}" )
	ghc_magic_hash=$( get_tag_ghc_magic_hash "${tag}" )

	echo "${ghc_version}${ghc_magic_hash:+.${ghc_magic_hash:0:7}}"
}


format_ghc_description () {
	local tag
	expect_args tag -- "$@"

	format_ghc_id "${tag}"
}


format_ghc_archive_name () {
	local tag
	expect_args tag -- "$@"

	local ghc_id
	ghc_id=$( format_ghc_id "${tag}" )

	echo "halcyon-ghc-${ghc_id}.tar.gz"
}


hash_ghc_magic () {
	local source_dir
	expect_args source_dir -- "$@"

	local ghc_magic_hash
	if ! ghc_magic_hash=$( hash_tree "${source_dir}/.halcyon" -path './ghc*' ); then
		log_error 'Failed to hash GHC magic files'
		return 1
	fi

	echo "${ghc_magic_hash}"
}


copy_ghc_magic () {
	expect_vars HALCYON_BASE

	local source_dir
	expect_args source_dir -- "$@"

	expect_existing "${HALCYON_BASE}/ghc" || return 1

	local ghc_magic_hash
	ghc_magic_hash=$( hash_ghc_magic "${source_dir}" ) || return 1
	if [[ -z "${ghc_magic_hash}" ]]; then
		return 0
	fi

	local file
	find_tree "${source_dir}/.halcyon" -type f -path './ghc*' |
		while read -r file; do
			copy_file "${source_dir}/.halcyon/${file}" \
				"${HALCYON_BASE}/ghc/.halcyon/${file}" || return 1
		done || return 0
}


symlink_ghc_libs () {
	expect_vars HALCYON_BASE \
		HALCYON_INTERNAL_PLATFORM

	local tag
	expect_args tag -- "$@"

	local ghc_version ghc_major ghc_minor
	ghc_version=$( get_tag_ghc_version "${tag}" )
	ghc_major="${ghc_version%%.*}"
	ghc_minor="${ghc_version#*.}"
	ghc_minor="${ghc_minor%%.*}"

	# NOTE: There is no libgmp.so.3 on some platforms, and there is no
	# .10-flavoured binary distribution of GHC < 7.8.  However, GHC does
	# not use the `mpn_bdivmod` function, which is the only difference
	# between the ABI of .3 and .10.  Hence, on some platforms, .10 is
	# symlinked to .3, and the .3-flavoured binary distribution is used.
	local gmp_name gmp_file tinfo_file url
	case "${HALCYON_INTERNAL_PLATFORM}" in
	'freebsd-10'*'-x86_64')
		url=$( map_ghc_version_to_freebsd_x86_64_url "${ghc_version}" ) || return 1
		;;
	'linux-debian-7-x86_64'|'linux-ubuntu-14'*'-x86_64')
		gmp_file='/usr/lib/x86_64-linux-gnu/libgmp.so.10'
		tinfo_file='/lib/x86_64-linux-gnu/libtinfo.so.5'
		if (( ghc_major < 7 || ghc_minor < 8 )); then
			gmp_name='libgmp.so.3'
			url=$( map_ghc_version_to_linux_x86_64_gmp3_url "${ghc_version}" ) || return 1
		else
			gmp_name='libgmp.so.10'
			url=$( map_ghc_version_to_linux_x86_64_gmp10_url "${ghc_version}" ) || return 1
		fi
		;;
	'linux-ubuntu-12'*'-x86_64')
		if (( ghc_major < 7 || ghc_minor < 8 )); then
			gmp_file='/usr/lib/libgmp.so.3'
			tinfo_file='/lib/x86_64-linux-gnu/libtinfo.so.5'
			gmp_name='libgmp.so.3'
			url=$( map_ghc_version_to_linux_x86_64_gmp3_url "${ghc_version}" ) || return 1
		else
			gmp_file='/usr/lib/x86_64-linux-gnu/libgmp.so.10'
			tinfo_file='/lib/x86_64-linux-gnu/libtinfo.so.5'
			gmp_name='libgmp.so.10'
			url=$( map_ghc_version_to_linux_x86_64_gmp10_url "${ghc_version}" ) || return 1
		fi
		;;
	'linux-debian-6-x86_64'|'linux-ubuntu-10'*'-x86_64')
		gmp_file='/usr/lib/libgmp.so.3'
		tinfo_file='/lib/libncurses.so.5'
		if (( ghc_major < 7 || ghc_minor < 10 )); then
			gmp_name='libgmp.so.3'
			url=$( map_ghc_version_to_linux_x86_64_gmp3_url "${ghc_version}" ) || return 1
		else
			log_error "Unexpected GHC version: ${ghc_version}"
			log
			log_indent 'To continue, use GHC 7.8.4 or older'
			log
			return 1
		fi
		;;
	'linux-centos-7-x86_64'|'linux-fedora-21-x86_64'|'linux-fedora-20-x86_64'|'linux-fedora-19-x86_64'|'linux-rhel-7-x86_64')
		gmp_file='/usr/lib64/libgmp.so.10'
		tinfo_file='/usr/lib64/libtinfo.so.5'
		if (( ghc_major < 7 || ghc_minor < 8 )); then
			gmp_name='libgmp.so.3'
			url=$( map_ghc_version_to_linux_x86_64_gmp3_url "${ghc_version}" ) || return 1
		else
			gmp_name='libgmp.so.10'
			url=$( map_ghc_version_to_linux_x86_64_gmp10_url "${ghc_version}" ) || return 1
		fi
		;;
	'linux-centos-6-x86_64'|'linux-amzn-2014.09-x86_64'|'linux-rhel-6-x86_64')
		gmp_file='/usr/lib64/libgmp.so.3'
		tinfo_file='/lib64/libtinfo.so.5'
		if (( ghc_major < 7 || ghc_minor < 10 )); then
			gmp_name='libgmp.so.3'
			url=$( map_ghc_version_to_linux_x86_64_gmp3_url "${ghc_version}" ) || return 1
		else
			gmp_name='libgmp.so.10'
			url=$( map_ghc_version_to_linux_x86_64_gmp10_url "${ghc_version}" ) || return 1
		fi
		;;
	'linux-arch-x86_64')
		gmp_file='/usr/lib/libgmp.so.10'
		tinfo_file='/usr/lib/libncurses.so.5'
		if (( ghc_major < 7 || ghc_minor < 8 )); then
			gmp_name='libgmp.so.3'
			url=$( map_ghc_version_to_linux_x86_64_gmp3_url "${ghc_version}" ) || return 1
		else
			gmp_name='libgmp.so.10'
			url=$( map_ghc_version_to_linux_x86_64_gmp10_url "${ghc_version}" ) || return 1
		fi
		;;
	'osx-'*'-x86_64')
		url=$( map_ghc_version_to_osx_x86_64_url "${ghc_version}" ) || return 1
		;;
	*)
		local description
		description=$( format_platform_description "${HALCYON_INTERNAL_PLATFORM}" )

		log_error "Unexpected platform: ${description}"
		return 1
	esac

	if [ -n "${gmp_file:-}" ]; then
		expect_existing "${gmp_file}" || return 1

		if ! mkdir -p "${HALCYON_BASE}/ghc/usr/lib" ||
			! ln -fs "${gmp_file}" "${HALCYON_BASE}/ghc/usr/lib/${gmp_name}" ||
			! ln -fs "${gmp_file}" "${HALCYON_BASE}/ghc/usr/lib/libgmp.so"
		then
			log_error 'Failed to symlink GHC libraries (libgmp.so)'
			return 1
		fi
	fi

	if [ -n "${tinfo_file:-}" ]; then
		expect_existing "${tinfo_file}" || return 1

		if ! mkdir -p "${HALCYON_BASE}/ghc/usr/lib" ||
			! ln -fs "${tinfo_file}" "${HALCYON_BASE}/ghc/usr/lib/libtinfo.so.5" ||
			! ln -fs "${tinfo_file}" "${HALCYON_BASE}/ghc/usr/lib/libtinfo.so"
		then
			log_error 'Failed to symlink GHC libraries (libtinfo.so)'
			return 1
		fi
	fi

	echo "${url}"
}


build_ghc_dir () {
	expect_vars HALCYON_BASE \
		HALCYON_INTERNAL_PLATFORM

	local tag source_dir
	expect_args tag source_dir -- "$@"

	if ! rm -rf "${HALCYON_BASE}/ghc"; then
		log_error 'Failed to prepare GHC directory'
		return 1
	fi

	local ghc_version ghc_original_url ghc_dir
	ghc_version=$( get_tag_ghc_version "${tag}" )
	ghc_original_url=$( symlink_ghc_libs "${tag}" ) || return 1
	ghc_dir=$( get_tmp_dir "ghc-${ghc_version}" ) || return 1

	log 'Building GHC directory'

	acquire_original_source "${ghc_original_url}" "${ghc_dir}" || return 1

	local ghc_sub_dir
	if ! ghc_sub_dir=$(
		find_tree "${ghc_dir}" -type d -maxdepth 1 -name 'ghc-*' |
		match_exactly_one
	); then
		log_error 'Failed to detect GHC source directory'
		return 1
	fi

	local ghc_build_dir
	ghc_build_dir="${ghc_dir}/${ghc_sub_dir}"
	expect_existing "${ghc_build_dir}" || return 1

	if [[ -f "${source_dir}/.halcyon/ghc-pre-build-hook" ]]; then
		log 'Executing GHC pre-build hook'
		if ! HALCYON_INTERNAL_RECURSIVE=1 \
			"${source_dir}/.halcyon/ghc-pre-build-hook" \
				"${tag}" "${source_dir}" "${ghc_build_dir}" 2>&1 | quote
		then
			log_error 'Failed to execute GHC pre-build hook'
			return 1
		fi
		log 'GHC pre-build hook executed'
	fi

	local cc make
	local -a opts_a
	cc=''
	make='make'
	opts_a=()
	opts_a+=( --prefix="${HALCYON_BASE}/ghc" )

	case "${HALCYON_INTERNAL_PLATFORM}" in
	'freebsd-'*)
		# NOTE: As described in:
		# https://downloads.haskell.org/~ghc/7.8.4/README.fbsd.html
		cc='gcc48'
		make='gmake'
		opts_a+=( --with-gcc='gcc48' )
		opts_a+=( --with-ld='/usr/local/bin/ld' )
		;;
	esac

	log 'Installing GHC'

	local installed_size
	if ! (
		cd "${ghc_build_dir}" &&
		CC="${cc}" \
			./configure "${opts_a[@]}" 2>&1 | quote &&
		"${make}" install 2>&1 | quote
	) ||
		! copy_ghc_magic "${source_dir}" ||
		! installed_size=$( get_size "${HALCYON_BASE}/ghc" )
	then
		log_error 'Failed to install GHC'
		return 1
	fi
	log "GHC installed, ${installed_size}"

	if [[ -f "${source_dir}/.halcyon/ghc-post-build-hook" ]]; then
		log 'Executing GHC post-build hook'
		if ! HALCYON_INTERNAL_RECURSIVE=1 \
			"${source_dir}/.halcyon/ghc-post-build-hook" \
				"${tag}" "${source_dir}" "${ghc_build_dir}" 2>&1 | quote
		then
			log_error 'Failed to execute GHC post-build hook'
			return 1
		fi
		log 'GHC post-build hook executed'
	fi

	if [[ -d "${HALCYON_BASE}/ghc/share/doc" ]]; then
		log_indent_begin 'Removing documentation from GHC directory...'

		local trimmed_size
		if ! rm -rf "${HALCYON_BASE}/ghc/share/doc" ||
			! trimmed_size=$( get_size "${HALCYON_BASE}/ghc" )
		then
			log_indent_end 'error'
			return 1
		fi
		log_indent_end "done, ${trimmed_size}"
	fi

	log_indent_begin 'Stripping GHC directory...'

	local stripped_size
	if ! strip_tree "${HALCYON_BASE}/ghc" ||
		! stripped_size=$( get_size "${HALCYON_BASE}/ghc" )
	then
		log_indent_end 'error'
		return 1
	fi
	log_indent_end "done, ${stripped_size}"

	if ! derive_ghc_tag "${tag}" >"${HALCYON_BASE}/ghc/.halcyon-tag"; then
		log_error 'Failed to write GHC tag'
		return 1
	fi
}


archive_ghc_dir () {
	expect_vars HALCYON_BASE HALCYON_NO_ARCHIVE \
		HALCYON_INTERNAL_PLATFORM

	if (( HALCYON_NO_ARCHIVE )); then
		return 0
	fi

	expect_existing "${HALCYON_BASE}/ghc/.halcyon-tag" || return 1

	local ghc_tag archive_name
	ghc_tag=$( detect_ghc_tag "${HALCYON_BASE}/ghc/.halcyon-tag") || return 1
	archive_name=$( format_ghc_archive_name "${ghc_tag}" )

	log 'Archiving GHC directory'

	create_cached_archive "${HALCYON_BASE}/ghc" "${archive_name}" || return 1
	upload_cached_file "${HALCYON_INTERNAL_PLATFORM}" "${archive_name}" || return 1
}


validate_ghc_dir () {
	expect_vars HALCYON_BASE

	local tag
	expect_args tag -- "$@"

	local ghc_tag
	ghc_tag=$( derive_ghc_tag "${tag}" )
	detect_tag "${HALCYON_BASE}/ghc/.halcyon-tag" "${ghc_tag//./\.}" || return 1
}


restore_ghc_dir () {
	expect_vars HALCYON_BASE \
		HALCYON_INTERNAL_PLATFORM

	local tag
	expect_args tag -- "$@"

	local archive_name
	archive_name=$( format_ghc_archive_name "${tag}" )

	if validate_ghc_dir "${tag}" >'/dev/null'; then
		log 'Using existing GHC directory'

		touch_cached_file "${archive_name}"
		return 0
	fi
	rm -rf "${HALCYON_BASE}/ghc" || true

	log 'Restoring GHC directory'

	if ! extract_cached_archive_over "${archive_name}" "${HALCYON_BASE}/ghc" ||
		! validate_ghc_dir "${tag}" >'/dev/null'
	then
		rm -rf "${HALCYON_BASE}/ghc" || true
		cache_stored_file "${HALCYON_INTERNAL_PLATFORM}" "${archive_name}" || return 1

		if ! extract_cached_archive_over "${archive_name}" "${HALCYON_BASE}/ghc" ||
			! validate_ghc_dir "${tag}" >'/dev/null'
		then
			rm -rf "${HALCYON_BASE}/ghc" || true

			log_error 'Failed to restore GHC directory'
			return 1
		fi
	else
		touch_cached_file "${archive_name}"
	fi
}


recache_ghc_package_db () {
	if ! ghc-pkg recache --global 2>&1 | quote; then
		log_warning 'Failed to recache GHC package database'
	fi
}


install_ghc_dir () {
	expect_vars HALCYON_NO_BUILD HALCYON_NO_BUILD_DEPENDENCIES \
		HALCYON_GHC_REBUILD

	local tag source_dir
	expect_args tag source_dir -- "$@"

	if ! (( HALCYON_GHC_REBUILD )); then
		if restore_ghc_dir "${tag}"; then
			recache_ghc_package_db
			return 0
		fi

		# NOTE: Returns 2 if build is needed.
		if (( HALCYON_NO_BUILD )) || (( HALCYON_NO_BUILD_DEPENDENCIES )); then
			log_error 'Cannot build GHC directory'
			return 2
		fi
	fi

	build_ghc_dir "${tag}" "${source_dir}" || return 1
	recache_ghc_package_db
	archive_ghc_dir || return 1
}
