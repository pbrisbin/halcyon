detect_package () {
	local source_dir
	expect_args source_dir -- "$@"

	expect_existing "${source_dir}" || return 1

	local package_file
	package_file=$(
		find "${source_dir}" -maxdepth 1 -type f -name '*.cabal' |
		match_exactly_one
	) || return 1

	cat "${package_file}"
}


detect_label () {
	local source_dir
	expect_args source_dir -- "$@"

	local package
	package=$( detect_package "${source_dir}" ) || return 1

	local name
	name=$(
		awk '/^ *[Nn]ame:/ { print $2 }' <<<"${package}" |
		tr -d '\r' |
		match_exactly_one
	) || return 1

	local version
	version=$(
		awk '/^ *[Vv]ersion:/ { print $2 }' <<<"${package}" |
		tr -d '\r' |
		match_exactly_one
	) || return 1

	echo "${name}-${version}"
}


detect_executable () {
	local source_dir
	expect_args source_dir -- "$@"

	local executable
	executable=$(
		detect_package "${source_dir}" |
		awk '/^ *[Ee]xecutable / { print $2 }' |
		tr -d '\r' |
		match_at_least_one |
		filter_first
	) || return 1

	echo "${executable}"
}


determine_ghc_version () {
	expect_vars HALCYON_GHC_VERSION

	local constraints
	expect_args constraints -- "$@"

	local ghc_version
	ghc_version=''
	if [[ -n "${constraints}" ]]; then
		ghc_version=$( map_constraints_to_ghc_version "${constraints}" ) || return 1
	fi
	if [[ -z "${ghc_version}" ]]; then
		ghc_version="${HALCYON_GHC_VERSION}"
	fi

	echo "${ghc_version}"
}


determine_ghc_magic_hash () {
	local source_dir
	expect_args source_dir -- "$@"

	local ghc_magic_hash
	if [[ -n "${HALCYON_INTERNAL_GHC_MAGIC_HASH:+_}" ]]; then
		ghc_magic_hash="${HALCYON_INTERNAL_GHC_MAGIC_HASH}"
	else
		ghc_magic_hash=$( hash_ghc_magic "${source_dir}" ) || return 1
	fi

	echo "${ghc_magic_hash}"
}


determine_cabal_magic_hash () {
	local source_dir
	expect_args source_dir -- "$@"

	local cabal_magic_hash
	if [[ -n "${HALCYON_INTERNAL_CABAL_MAGIC_HASH:+_}" ]]; then
		cabal_magic_hash="${HALCYON_INTERNAL_CABAL_MAGIC_HASH}"
	else
		cabal_magic_hash=$( hash_cabal_magic "${source_dir}" ) || return 1
	fi

	echo "${cabal_magic_hash}"
}


describe_extra () {
	local extra_label extra_file
	expect_args extra_label extra_file -- "$@"

	if [[ ! -f "${extra_file}" ]]; then
		return 0
	fi

	local only_first extra
	only_first="${extra_label}"
	while read -r extra; do
		log_indent_label "${only_first}" "${extra}"
		only_first=''
	done <"${extra_file}" || return 0
}


hash_source () {
	local source_dir
	expect_args source_dir -- "$@"

	# NOTE: Ignoring the same files as in prepare_build_dir.
	local -a opts_a
	opts_a=()
	opts_a+=( \( -name '.git' )
	opts_a+=( -o -name '.gitmodules' )
	opts_a+=( -o -name '.ghc' )
	opts_a+=( -o -name '.cabal' )
	opts_a+=( -o -name '.cabal-sandbox' )
	opts_a+=( -o -name 'cabal.sandbox.config' )
	if [[ -f "${source_dir}/.halcyon/extra-source-hash-ignore" ]]; then
		local ignore
		while read -r ignore; do
			opts_a+=( -o -name "${ignore}" )
		done <"${source_dir}/.halcyon/extra-source-hash-ignore"
	fi
	opts_a+=( \) -prune -o )

	local source_hash
	if ! source_hash=$( hash_tree "${source_dir}" "${opts_a[@]}" ); then
		log_error 'Failed to hash source files'
		return 1
	fi

	echo "${source_hash}"
}


hash_magic () {
	local source_dir
	expect_args source_dir -- "$@"

	# NOTE: The version number of Cabal and the contents of its package
	# database could conceivably be treated as dependencies.
	local magic_hash
	if ! magic_hash=$( hash_tree "${source_dir}/.halcyon" -not -path './cabal*' ); then
		log_error 'Failed to hash magic files'
		return 1
	fi

	echo "${magic_hash}"
}


announce_install () {
	expect_vars HALCYON_NO_APP HALCYON_DEPENDENCIES_ONLY \
		HALCYON_INTERNAL_NO_ANNOUNCE_INSTALL

	local tag
	expect_args tag -- "$@"

	if (( HALCYON_INTERNAL_NO_ANNOUNCE_INSTALL )); then
		return 0
	fi

	if (( HALCYON_NO_APP )); then
		log_label 'GHC and Cabal installed'
		return 0
	fi

	local thing label
	if (( HALCYON_DEPENDENCIES_ONLY )); then
		thing='Dependencies'
	else
		thing='App'
	fi
	label=$( get_tag_label "${tag}" )

	case "${HALCYON_INTERNAL_COMMAND}" in
	'install')
		log
		log_label "${thing} installed:" "${label}"
		;;
	'build')
		log
		log_label "${thing} built:" "${label}"
	esac
}


do_install_ghc_and_cabal_dirs () {
	expect_vars HALCYON_INTERNAL_RECURSIVE

	local tag source_dir
	expect_args tag source_dir -- "$@"

	if (( HALCYON_INTERNAL_RECURSIVE )); then
		if ! validate_ghc_dir "${tag}" >'/dev/null' ||
			! validate_updated_cabal_dir "${tag}" >'/dev/null'
		then
			log_error 'Cannot use existing GHC and Cabal directories'
			return 1
		fi
		return 0
	fi

	# NOTE: Returns 2 if build is needed.
	install_ghc_dir "${tag}" "${source_dir}" || return
	log
	install_cabal_dir "${tag}" "${source_dir}" || return
	log
}


install_ghc_and_cabal_dirs () {
	expect_vars HALCYON_GHC_VERSION \
		HALCYON_CABAL_VERSION HALCYON_CABAL_REPO \
		HALCYON_INTERNAL_RECURSIVE

	local source_dir
	expect_args source_dir -- "$@"

	local ghc_version ghc_magic_hash ghc_major ghc_minor
	ghc_version="${HALCYON_GHC_VERSION}"
	ghc_magic_hash=$( determine_ghc_magic_hash "${source_dir}" ) || return 1
	ghc_major="${ghc_version%%.*}"
	ghc_minor="${ghc_version#*.}"
	ghc_minor="${ghc_minor%%.*}"

	local cabal_version cabal_magic_hash cabal_repo cabal_major cabal_minor
	cabal_version="${HALCYON_CABAL_VERSION}"
	cabal_magic_hash=$( determine_cabal_magic_hash "${source_dir}" ) || return 1
	cabal_repo="${HALCYON_CABAL_REPO}"
	cabal_major="${cabal_version%%.*}"
	cabal_minor="${cabal_version#*.}"
	cabal_minor="${cabal_minor%%.*}"

	# NOTE: GHC 7.10.* requires Cabal 1.22.0.0 or newer.
	if (( ((ghc_major == 7 && ghc_minor >= 10) || ghc_major > 7) && cabal_major == 1 && cabal_minor < 22 )); then
		log_error 'Unexpected Cabal version'
		log
		log_indent 'To use GHC 7.10.1 or newer, use Cabal 1.22.0.0 or newer'
		log
		return 1
	fi

	if ! (( HALCYON_INTERNAL_RECURSIVE )); then
		log 'Installing GHC and Cabal'

		describe_storage

		log_indent_label 'GHC version:' "${ghc_version}"
		[[ -n "${ghc_magic_hash}" ]] && log_indent_label 'GHC magic hash:' "${ghc_magic_hash:0:7}"

		log_indent_label 'Cabal version:' "${cabal_version}"
		[[ -n "${cabal_magic_hash}" ]] && log_indent_label 'Cabal magic hash:' "${cabal_magic_hash:0:7}"
		log_indent_label 'Cabal repository:' "${cabal_repo%%:*}"
		log
	fi

	local tag
	tag=$(
		create_tag '' '' '' '' '' \
			"${ghc_version}" "${ghc_magic_hash}" \
			"${cabal_version}" "${cabal_magic_hash}" "${cabal_repo}" '' \
			''
	)

	# NOTE: Returns 2 if build is needed.
	do_install_ghc_and_cabal_dirs "${tag}" "${source_dir}" || return

	announce_install "${tag}"
}


do_fast_install_app () {
	local tag source_dir
	expect_args tag source_dir -- "$@"

	local label install_dir
	label=$( get_tag_label "${tag}" )
	install_dir=$( get_tmp_dir "install-${label}" ) || return 1

	restore_install_dir "${tag}" "${install_dir}" || return 1
	install_app "${tag}" "${source_dir}" "${install_dir}" || return 1
	symlink_cabal_config
}


fast_install_app () {
	expect_vars HALCYON_PREFIX HALCYON_DEPENDENCIES_ONLY HALCYON_KEEP_DEPENDENCIES \
		HALCYON_APP_REBUILD HALCYON_APP_RECONFIGURE HALCYON_APP_REINSTALL \
		HALCYON_GHC_VERSION HALCYON_GHC_REBUILD \
		HALCYON_CABAL_REBUILD HALCYON_CABAL_UPDATE \
		HALCYON_SANDBOX_REBUILD \
		HALCYON_INTERNAL_RECURSIVE

	local label source_hash source_dir
	expect_args label source_hash source_dir -- "$@"

	if (( HALCYON_DEPENDENCIES_ONLY )) || (( HALCYON_KEEP_DEPENDENCIES )) ||
		(( HALCYON_APP_REBUILD )) || (( HALCYON_APP_RECONFIGURE )) || (( HALCYON_APP_REINSTALL )) ||
		(( HALCYON_GHC_REBUILD )) ||
		(( HALCYON_CABAL_REBUILD )) || (( HALCYON_CABAL_UPDATE )) ||
		(( HALCYON_SANDBOX_REBUILD ))
	then
		return 1
	fi

	expect_existing "${source_dir}" || return 1

	log_indent_label 'Label:' "${label}"
	log_indent_label 'Prefix:' "${HALCYON_PREFIX}"
	log_indent_label 'Source hash:' "${source_hash:0:7}"

	describe_storage

	log_indent_label 'GHC version:' "${HALCYON_GHC_VERSION}"
	log

	local tag
	tag=$(
		create_tag "${HALCYON_PREFIX}" "${label}" "${source_hash}" '' '' \
			"${HALCYON_GHC_VERSION}" '' \
			'' '' '' '' \
			''
	)

	if ! do_fast_install_app "${tag}" "${source_dir}"; then
		log
		return 1
	fi

	if ! (( HALCYON_INTERNAL_RECURSIVE )); then
		announce_install "${tag}"
		touch_cached_ghc_and_cabal_files
	fi
}


prepare_file_option () {
	local magic_var magic_file
	expect_args magic_var magic_file -- "$@"

	if [[ -z "${magic_var}" ]]; then
		return 0
	fi

	copy_file "${magic_var}" "${magic_file}" || return 1
}


prepare_file_strings_option () {
	local magic_var magic_file
	expect_args magic_var magic_file -- "$@"

	if [[ -z "${magic_var}" ]]; then
		return 0
	fi
	if [[ -f "${magic_var}" ]]; then
		copy_file "${magic_var}" "${magic_file}" || return 1
		return 0
	fi

	local -a strings_a
	strings_a=( ${magic_var} )

	copy_file <( IFS=$'\n' && echo "${strings_a[*]}" ) "${magic_file}" || return 1
}


prepare_constraints_option () {
	local magic_var magic_file
	expect_args magic_var magic_file -- "$@"

	if [[ -z "${magic_var}" ]]; then
		return 0
	fi
	if [[ -d "${magic_var}" ]]; then
		copy_dir_over "${magic_var}" "${magic_file}" || return 1
		return 0
	fi
	if [[ -f "${magic_var}" ]]; then
		copy_file "${magic_var}" "${magic_file}" || return 1
		return 0
	fi

	copy_file <( echo "${magic_var}" ) "${magic_file}" || return 1
}


prepare_source_dir () {
	local label source_dir
	expect_args label source_dir -- "$@"

	expect_existing "${source_dir}" || return 1

	# NOTE: Listing executable-only packages in build-tools causes Cabal
	# to expect the executables to be installed, but not to install the
	# packages.
	# Listing executable-only packages in build-depends causes Cabal to
	# install the packages, and to fail to recognise the packages have
	# been installed.
	# https://github.com/haskell/cabal/issues/220
	# https://github.com/haskell/cabal/issues/779
	local magic_dir
	magic_dir="${source_dir}/.halcyon"

# Build-time magic files
	prepare_file_strings_option "${HALCYON_EXTRA_SOURCE_HASH_IGNORE}" "${magic_dir}/extra-source-hash-ignore" || return 1
	prepare_file_strings_option "${HALCYON_EXTRA_CONFIGURE_FLAGS}" "${magic_dir}/extra-configure-flags" || return 1
	prepare_file_option "${HALCYON_PRE_BUILD_HOOK}" "${magic_dir}/pre-build-hook" || return 1
	prepare_file_option "${HALCYON_POST_BUILD_HOOK}" "${magic_dir}/post-build-hook" || return 1

# Install-time magic files
	prepare_file_strings_option "${HALCYON_EXTRA_APPS}" "${magic_dir}/extra-apps" || return 1
	prepare_constraints_option "${HALCYON_EXTRA_APPS_CONSTRAINTS}" "${magic_dir}/extra-apps-constraints" || return 1
	prepare_file_strings_option "${HALCYON_EXTRA_DATA_FILES}" "${magic_dir}/extra-data-files" || return 1
	prepare_file_strings_option "${HALCYON_EXTRA_OS_PACKAGES}" "${magic_dir}/extra-os-packages" || return 1
	prepare_file_option "${HALCYON_PRE_INSTALL_HOOK}" "${magic_dir}/pre-install-hook" || return 1
	prepare_file_option "${HALCYON_POST_INSTALL_HOOK}" "${magic_dir}/post-install-hook" || return 1

# GHC magic files
	prepare_file_option "${HALCYON_GHC_PRE_BUILD_HOOK}" "${magic_dir}/ghc-pre-build-hook" || return 1
	prepare_file_option "${HALCYON_GHC_POST_BUILD_HOOK}" "${magic_dir}/ghc-post-build-hook" || return 1

# Cabal magic files
	prepare_file_option "${HALCYON_CABAL_PRE_BUILD_HOOK}" "${magic_dir}/cabal-pre-build-hook" || return 1
	prepare_file_option "${HALCYON_CABAL_POST_BUILD_HOOK}" "${magic_dir}/cabal-post-build-hook" || return 1
	prepare_file_option "${HALCYON_CABAL_PRE_UPDATE_HOOK}" "${magic_dir}/cabal-pre-update-hook" || return 1
	prepare_file_option "${HALCYON_CABAL_POST_UPDATE_HOOK}" "${magic_dir}/cabal-post-update-hook" || return 1

# Sandbox magic files
	prepare_file_strings_option "${HALCYON_SANDBOX_EXTRA_CONFIGURE_FLAGS}" "${magic_dir}/sandbox-extra-configure-flags" || return 1
	prepare_file_strings_option "${HALCYON_SANDBOX_SOURCES}" "${magic_dir}/sandbox-sources" || return 1
	prepare_file_strings_option "${HALCYON_SANDBOX_EXTRA_APPS}" "${magic_dir}/sandbox-extra-apps" || return 1
	prepare_constraints_option "${HALCYON_SANDBOX_EXTRA_APPS_CONSTRAINTS}" "${magic_dir}/sandbox-extra-apps-constraints" || return 1
	prepare_file_strings_option "${HALCYON_SANDBOX_EXTRA_OS_PACKAGES}" "${magic_dir}/sandbox-extra-os-packages" || return 1
	prepare_file_option "${HALCYON_SANDBOX_PRE_BUILD_HOOK}" "${magic_dir}/sandbox-pre-build-hook" || return 1
	prepare_file_option "${HALCYON_SANDBOX_POST_BUILD_HOOK}" "${magic_dir}/sandbox-post-build-hook" || return 1
}


do_full_install_app () {
	expect_vars HALCYON_BASE HALCYON_DEPENDENCIES_ONLY \
		HALCYON_APP_REBUILD HALCYON_APP_RECONFIGURE HALCYON_APP_REINSTALL \
		HALCYON_SANDBOX_REBUILD \
		HALCYON_INTERNAL_RECURSIVE

	local tag source_dir constraints
	expect_args tag source_dir constraints -- "$@"

	local label build_dir install_dir saved_sandbox
	label=$( get_tag_label "${tag}" )
	build_dir=$( get_tmp_dir "build-${label}" ) || return 1
	install_dir=$( get_tmp_dir "install-${label}" ) || return 1
	saved_sandbox=''

	# NOTE: Returns 2 if build is needed.
	do_install_ghc_and_cabal_dirs "${tag}" "${source_dir}" || return

	if (( HALCYON_INTERNAL_RECURSIVE )); then
		if [[ -d "${HALCYON_BASE}/sandbox" ]]; then
			if ! saved_sandbox=$( get_tmp_dir 'saved-sandbox' ) ||
				! mv "${HALCYON_BASE}/sandbox" "${saved_sandbox}"
			then
				log_error 'Failed to save existing sandbox'
				return 1
			fi
		fi
	fi

	# NOTE: Returns 2 if build is needed.
	install_sandbox_dir "${tag}" "${source_dir}" "${constraints}" || return
	validate_actual_constraints "${tag}" "${source_dir}" "${constraints}"
	log

	if ! (( HALCYON_DEPENDENCIES_ONLY )); then
		# NOTE: Returns 2 if build is needed.
		build_app "${tag}" "${source_dir}" "${build_dir}" || return
	fi

	if [[ "${HALCYON_INTERNAL_COMMAND}" == 'install' ]] &&
		! (( HALCYON_DEPENDENCIES_ONLY ))
	then
		log

		if (( HALCYON_APP_REBUILD )) ||
			(( HALCYON_APP_RECONFIGURE )) ||
			(( HALCYON_APP_REINSTALL )) ||
			(( HALCYON_SANDBOX_REBUILD )) ||
			! restore_install_dir "${tag}" "${install_dir}"
		then
			# NOTE: Returns 2 if build is needed.
			prepare_install_dir "${tag}" "${source_dir}" "${constraints}" "${build_dir}" "${install_dir}" || return
			archive_install_dir "${install_dir}" || return 1
		fi
	fi

	if (( HALCYON_INTERNAL_RECURSIVE )); then
		if ! rm -rf "${HALCYON_BASE}/sandbox"; then
			log_error 'Failed to remove sandbox'
			return 1
		fi
		if [[ -n "${saved_sandbox}" ]]; then
			if ! mv "${saved_sandbox}" "${HALCYON_BASE}/sandbox"; then
				log_error 'Failed to restore saved sandbox'
				return 1
			fi
		fi
	fi

	if [[ "${HALCYON_INTERNAL_COMMAND}" == 'install' ]] &&
		! (( HALCYON_DEPENDENCIES_ONLY ))
	then
		install_app "${tag}" "${source_dir}" "${install_dir}" || return 1
		symlink_cabal_config
	fi
}


full_install_app () {
	expect_vars HALCYON_PREFIX HALCYON_DEPENDENCIES_ONLY \
		HALCYON_CABAL_VERSION HALCYON_CABAL_REPO \
		HALCYON_INTERNAL_RECURSIVE

	local label source_dir
	expect_args label source_dir -- "$@"

	expect_existing "${source_dir}" || return 1

	case "${HALCYON_INTERNAL_COMMAND}" in
	'label')
		echo "${label}"
		return 0
		;;
	'executable')
		local executable
		if ! executable=$( detect_executable "${source_dir}" ); then
			log_error 'Failed to detect executable'
			return 1
		fi

		echo "${executable}"
		return 0
		;;
	esac

	log "Installing ${label}"

	# NOTE: First of two places where source_dir is modified.
	if ! prepare_constraints "${label}" "${source_dir}" ||
		! prepare_source_dir "${label}" "${source_dir}"
	then
		log_error 'Failed to prepare source directory'
		return 1
	fi

	local source_hash
	if [[ -f "${source_dir}/cabal.config" ]]; then
		source_hash=$( hash_source "${source_dir}" ) || return 1

		if [[ "${HALCYON_INTERNAL_COMMAND}" == 'install' ]] &&
			fast_install_app "${label}" "${source_hash}" "${source_dir}"
		then
			return 0
		fi
	fi

	local constraints
	constraints=''
	if [[ -f "${source_dir}/cabal.config" ]]; then
		log 'Determining constraints'

		if ! constraints=$( detect_constraints "${label}" "${source_dir}" ); then
			log_error 'Failed to determine constraints'
			return 1
		fi
	fi
	if [[ -z "${constraints}" ]]; then
		# NOTE: Returns 2 if build is needed.
		HALCYON_GHC_REBUILD=0 \
		HALCYON_CABAL_REBUILD=0 HALCYON_CABAL_UPDATE=0 \
		HALCYON_INTERNAL_NO_ANNOUNCE_INSTALL=1 \
			install_ghc_and_cabal_dirs "${source_dir}" || return

		log 'Determining constraints'

		if ! constraints=$( cabal_determine_constraints "${label}" "${source_dir}" ); then
			log_error 'Failed to determine constraints'
			return 1
		fi

		log_warning 'Using newest versions of all packages'
		if [[ "${HALCYON_INTERNAL_COMMAND}" != 'constraints' ]]; then
			format_constraints <<<"${constraints}" | quote
			log
		fi

		# NOTE: Second of two places where source_dir is modified.
		if ! format_constraints_to_cabal_freeze <<<"${constraints}" >"${source_dir}/cabal.config"; then
			log_error 'Failed to write Cabal config'
			return 1
		fi

		source_hash=$( hash_source "${source_dir}" ) || return 1

		if [[ "${HALCYON_INTERNAL_COMMAND}" == 'install' ]] &&
			fast_install_app "${label}" "${source_hash}" "${source_dir}"
		then
			return 0
		fi
	fi
	if [[ "${HALCYON_INTERNAL_COMMAND}" == 'constraints' ]]; then
		format_constraints <<<"${constraints}"
		return 0
	fi

	local constraints_hash magic_hash
	constraints_hash=$( hash_constraints "${constraints}" ) || return 1
	magic_hash=$( hash_magic "${source_dir}" ) || return 1

	local ghc_version ghc_magic_hash
	ghc_version=$( determine_ghc_version "${constraints}" ) || return 1
	ghc_magic_hash=$( determine_ghc_magic_hash "${source_dir}" ) || return 1

	local cabal_version cabal_magic_hash cabal_repo
	cabal_version="${HALCYON_CABAL_VERSION}"
	cabal_magic_hash=$( determine_cabal_magic_hash "${source_dir}" ) || return 1
	cabal_repo="${HALCYON_CABAL_REPO}"

	local sandbox_magic_hash
	sandbox_magic_hash=$( hash_sandbox_magic "${source_dir}" ) || return 1

	log_indent_label 'Label:' "${label}"
	log_indent_label 'Prefix:' "${HALCYON_PREFIX}"
	log_indent_label 'Source hash:' "${source_hash:0:7}"

	describe_extra 'Extra source hash ignore:' "${source_dir}/.halcyon/extra-source-hash-ignore"
	log_indent_label 'Constraints hash:' "${constraints_hash:0:7}"
	describe_extra 'Extra configure flags:' "${source_dir}/.halcyon/extra-configure-flags"
	describe_extra 'Extra apps:' "${source_dir}/.halcyon/extra-apps"
	describe_extra 'Extra data files:' "${source_dir}/.halcyon/extra-data-files"
	describe_extra 'Extra OS packages:' "${source_dir}/.halcyon/extra-os-packages"
	[[ -n "${magic_hash}" ]] && log_indent_label 'Magic hash:' "${magic_hash:0:7}"

	describe_storage

	log_indent_label 'GHC version:' "${ghc_version}"
	[[ -n "${ghc_magic_hash}" ]] && log_indent_label 'GHC magic hash:' "${ghc_magic_hash:0:7}"

	log_indent_label 'Cabal version:' "${cabal_version}"
	[[ -n "${cabal_magic_hash}" ]] && log_indent_label 'Cabal magic hash:' "${cabal_magic_hash:0:7}"
	log_indent_label 'Cabal repository:' "${cabal_repo%%:*}"

	[[ -n "${sandbox_magic_hash}" ]] && log_indent_label 'Sandbox magic hash:' "${sandbox_magic_hash:0:7}"
	describe_extra 'Sandbox extra configure flags:' "${source_dir}/.halcyon/sandbox-extra-configure-flags"
	describe_extra 'Sandbox sources:' "${source_dir}/.halcyon/sandbox-sources"
	describe_extra 'Sandbox extra apps:' "${source_dir}/.halcyon/sandbox-extra-apps"
	describe_extra 'Sandbox extra OS packages:' "${source_dir}/.halcyon/sandbox-extra-os-packages"

	local tag
	tag=$(
		create_tag "${HALCYON_PREFIX}" "${label}" "${source_hash}" "${constraints_hash}" "${magic_hash}" \
			"${ghc_version}" "${ghc_magic_hash}" \
			"${cabal_version}" "${cabal_magic_hash}" "${cabal_repo}" '' \
			"${sandbox_magic_hash}"
	)

	if [[ "${HALCYON_INTERNAL_COMMAND}" == 'tag' ]]; then
		echo "${tag}"
		return 0
	fi

	# NOTE: Returns 2 if build is needed.
	log
	do_full_install_app "${tag}" "${source_dir}" "${constraints}" || return

	if ! (( HALCYON_INTERNAL_RECURSIVE )); then
		announce_install "${tag}"
	fi
}


install_local_app () {
	expect_vars HALCYON_INTERNAL_NO_COPY_LOCAL_SOURCE

	local local_dir
	expect_args local_dir -- "$@"

	local label
	if ! label=$( detect_label "${local_dir}" ); then
		log_error 'Failed to detect app'
		return 1
	fi

	if (( HALCYON_INTERNAL_NO_COPY_LOCAL_SOURCE )); then
		# NOTE: Returns 2 if build is needed.
		full_install_app "${label}" "${local_dir}" || return
		return 0
	fi

	local source_dir
	source_dir=$( get_tmp_dir "source-${label}" ) || return 1

	copy_dir_over "${local_dir}" "${source_dir}" || return 1

	# NOTE: Returns 2 if build is needed.
	full_install_app "${label}" "${source_dir}" || return
}


install_cloned_app () {
	local url
	expect_args url -- "$@"

	local clone_dir
	clone_dir=$( get_tmp_dir 'git-clone' ) || return 1

	log_begin "Cloning ${url}..."

	local commit_hash
	if ! commit_hash=$( git_clone_over "${url}" "${clone_dir}" ); then
		log_end 'error'
		return 1
	fi
	log_end "done, ${commit_hash:0:7}"

	local label
	if ! label=$( detect_label "${clone_dir}" ); then
		log_error 'Failed to detect app'
		return 1
	fi

	local source_dir
	source_dir=$( get_tmp_dir "source-${label}" ) || return 1

	mv "${clone_dir}" "${source_dir}" || return 1

	# NOTE: Returns 2 if build is needed.
	HALCYON_INTERNAL_REMOTE_SOURCE=1 \
		full_install_app "${label}" "${source_dir}" || return
}


install_unpacked_app () {
	local thing
	expect_args thing -- "$@"

	local unpack_dir
	unpack_dir=$( get_tmp_dir 'cabal-unpack' ) || return 1

	# NOTE: Returns 2 if build is needed.
	HALCYON_NO_APP=1 \
	HALCYON_GHC_REBUILD=0 \
	HALCYON_CABAL_REBUILD=0 HALCYON_CABAL_UPDATE=0 \
	HALCYON_INTERNAL_NO_ANNOUNCE_INSTALL=1 \
		install_ghc_and_cabal_dirs '/dev/null' || return

	log 'Unpacking app'

	local label
	if ! label=$( cabal_unpack_over "${thing}" "${unpack_dir}" ); then
		log_error 'Failed to unpack app'
		return 1
	fi

	if [[ "${label}" != "${thing}" ]]; then
		log_warning "Using newest version of ${thing}: ${label}"
	fi

	local source_dir
	source_dir=$( get_tmp_dir "source-${label}" ) || return 1

	mv "${unpack_dir}/${label}" "${source_dir}" || return 1

	# NOTE: Returns 2 if build is needed.
	HALCYON_INTERNAL_REMOTE_SOURCE=1 \
		full_install_app "${label}" "${source_dir}" || return
}


halcyon_install () {
	expect_vars HALCYON_NO_APP

	if (( $# > 1 )); then
		shift
		log_error "Unexpected args: $*"
		return 1
	fi

	local cache_dir
	cache_dir=$( get_tmp_dir 'cache' ) || return 1

	if ! prepare_cache "${cache_dir}"; then
		log_error 'Failed to prepare cache'
		return 1
	fi

	# NOTE: Returns 2 if build is needed.
	if (( HALCYON_NO_APP )); then
		install_ghc_and_cabal_dirs '/dev/null' || return
	elif ! (( $# )); then
		if ! detect_label '.' >'/dev/null'; then
			HALCYON_NO_APP=1 \
				install_ghc_and_cabal_dirs '/dev/null' || return
		else
			install_local_app '.' || return
		fi
	else
		if validate_git_url "$1"; then
			install_cloned_app "$1" || return
		elif [[ -d "$1" ]]; then
			install_local_app "${1%/}" || return
		else
			install_unpacked_app "$1" || return
		fi
	fi

	if ! clean_cache "${cache_dir}"; then
		log_warning 'Failed to clean cache'
	fi
}
