map_cabal_version_to_original_url () {
	local cabal_version
	expect_args cabal_version -- "$@"

	case "${cabal_version}" in
	'1.22.0.0')	echo 'https://haskell.org/cabal/release/cabal-install-1.22.0.0/cabal-install-1.22.0.0.tar.gz';;
	'1.20.0.6')	echo 'https://haskell.org/cabal/release/cabal-install-1.20.0.6/cabal-install-1.20.0.6.tar.gz';;
	'1.20.0.5')	echo 'https://haskell.org/cabal/release/cabal-install-1.20.0.5/cabal-install-1.20.0.5.tar.gz';;
	'1.20.0.3')	echo 'https://haskell.org/cabal/release/cabal-install-1.20.0.3/cabal-install-1.20.0.3.tar.gz';;
	'1.20.0.2')	echo 'https://haskell.org/cabal/release/cabal-install-1.20.0.2/cabal-install-1.20.0.2.tar.gz';;
	'1.20.0.1')	echo 'https://haskell.org/cabal/release/cabal-install-1.20.0.1/cabal-install-1.20.0.1.tar.gz';;
	'1.20.0.0')	echo 'https://haskell.org/cabal/release/cabal-install-1.20.0.0/cabal-install-1.20.0.0.tar.gz';;
	*)
		# NOTE: Bootstrapping cabal-install 1.20.0.4 does not work.
		# https://www.haskell.org/pipermail/cabal-devel/2014-December/009959.html
		log_error "Unexpected Cabal version: ${cabal_version}"
		return 1
	esac
}


create_cabal_tag () {
	local cabal_version cabal_magic_hash cabal_repo cabal_date
	expect_args cabal_version cabal_magic_hash cabal_repo cabal_date -- "$@"

	create_tag '' '' '' '' '' \
		'' '' \
		"${cabal_version}" "${cabal_magic_hash}" "${cabal_repo}" "${cabal_date}" \
		''
}


detect_cabal_tag () {
	local tag_file
	expect_args tag_file -- "$@"

	local tag_pattern
	tag_pattern=$( create_cabal_tag '.*' '.*' '.*' '.*' )

	local tag
	if ! tag=$( detect_tag "${tag_file}" "${tag_pattern}" ); then
		log_error 'Failed to detect Cabal tag'
		return 1
	fi

	echo "${tag}"
}


derive_base_cabal_tag () {
	local tag
	expect_args tag -- "$@"

	local cabal_version cabal_magic_hash
	cabal_version=$( get_tag_cabal_version "${tag}" )
	cabal_magic_hash=$( get_tag_cabal_magic_hash "${tag}" )

	create_cabal_tag "${cabal_version}" "${cabal_magic_hash}" '' ''
}


derive_updated_cabal_tag () {
	local tag cabal_date
	expect_args tag cabal_date -- "$@"

	local cabal_version cabal_magic_hash cabal_repo
	cabal_version=$( get_tag_cabal_version "${tag}" )
	cabal_magic_hash=$( get_tag_cabal_magic_hash "${tag}" )
	cabal_repo=$( get_tag_cabal_repo "${tag}" )

	create_cabal_tag "${cabal_version}" "${cabal_magic_hash}" "${cabal_repo}" "${cabal_date}"
}


derive_updated_cabal_tag_pattern () {
	local tag
	expect_args tag -- "$@"

	local cabal_version cabal_magic_hash cabal_repo
	cabal_version=$( get_tag_cabal_version "${tag}" )
	cabal_magic_hash=$( get_tag_cabal_magic_hash "${tag}" )
	cabal_repo=$( get_tag_cabal_repo "${tag}" )

	create_cabal_tag "${cabal_version//./\.}" "${cabal_magic_hash}" "${cabal_repo//.\.}" '.*'
}


format_cabal_id () {
	local tag
	expect_args tag -- "$@"

	local cabal_version cabal_magic_hash
	cabal_version=$( get_tag_cabal_version "${tag}" )
	cabal_magic_hash=$( get_tag_cabal_magic_hash "${tag}" )

	echo "${cabal_version}${cabal_magic_hash:+.${cabal_magic_hash:0:7}}"
}


format_cabal_repo_name () {
	local tag
	expect_args tag -- "$@"

	local cabal_repo
	cabal_repo=$( get_tag_cabal_repo "${tag}" )

	echo "${cabal_repo%%:*}"
}


format_cabal_description () {
	local tag
	expect_args tag -- "$@"

	local cabal_id repo_name cabal_date
	cabal_id=$( format_cabal_id "${tag}" )
	repo_name=$( format_cabal_repo_name "${tag}" )
	cabal_date=$( get_tag_cabal_date "${tag}" )

	echo "${cabal_id} ${repo_name:+(${repo_name} ${cabal_date})}"
}


format_cabal_config () {
	expect_vars HALCYON_BASE

	local tag
	expect_args tag -- "$@"

	local cabal_repo
	cabal_repo=$( get_tag_cabal_repo "${tag}" )

	cat <<-EOF
		remote-repo:        ${cabal_repo}
		remote-repo-cache:  ${HALCYON_BASE}/cabal/remote-repo-cache
		avoid-reinstalls:   True
		reorder-goals:      True
		require-sandbox:    True
		jobs:               \$ncpus
EOF
}


format_cabal_archive_name () {
	local tag
	expect_args tag -- "$@"

	local cabal_id repo_name cabal_date
	cabal_id=$( format_cabal_id "${tag}" )
	repo_name=$( format_cabal_repo_name "${tag}" | tr '[:upper:]' '[:lower:]' )
	cabal_date=$( get_tag_cabal_date "${tag}" )

	echo "halcyon-cabal-${cabal_id}${repo_name:+-${repo_name}-${cabal_date}}.tar.gz"
}


format_base_cabal_archive_name () {
	local tag
	expect_args tag -- "$@"

	local cabal_id
	cabal_id=$( format_cabal_id "${tag}" )

	echo "halcyon-cabal-${cabal_id}.tar.gz"
}


format_updated_cabal_archive_name_prefix () {
	local tag
	expect_args tag -- "$@"

	local cabal_id repo_name
	cabal_id=$( format_cabal_id "${tag}" )
	repo_name=$( format_cabal_repo_name "${tag}" | tr '[:upper:]' '[:lower:]' )

	echo "halcyon-cabal-${cabal_id}-${repo_name}-"
}


format_updated_cabal_archive_name_pattern () {
	local tag
	expect_args tag -- "$@"

	local cabal_id repo_name
	cabal_id=$( format_cabal_id "${tag}" )
	repo_name=$( format_cabal_repo_name "${tag}" | tr '[:upper:]' '[:lower:]' )

	echo "halcyon-cabal-${cabal_id//./\.}-${repo_name//./\.}-.*\.tar\.gz"
}


format_updated_cabal_archive_name_date () {
	local archive_name
	expect_args archive_name -- "$@"

	local date_etc
	date_etc="${archive_name#halcyon-cabal-*-*-}"

	echo "${date_etc%.tar.gz}"
}


hash_cabal_magic () {
	local source_dir
	expect_args source_dir -- "$@"

	local cabal_magic_hash
	if ! cabal_magic_hash=$( hash_tree "${source_dir}/.halcyon" -path './cabal*' ); then
		log_error 'Failed to hash Cabal magic files'
		return 1
	fi

	echo "${cabal_magic_hash}"
}


copy_cabal_magic () {
	expect_vars HALCYON_BASE

	local source_dir
	expect_args source_dir -- "$@"

	expect_existing "${HALCYON_BASE}/cabal" || return 1

	local cabal_magic_hash
	cabal_magic_hash=$( hash_cabal_magic "${source_dir}" ) || return 1
	if [[ -z "${cabal_magic_hash}" ]]; then
		return 0
	fi

	local file
	find_tree "${source_dir}/.halcyon" -type f -path './cabal*' |
		while read -r file; do
			copy_file "${source_dir}/.halcyon/${file}" \
				"${HALCYON_BASE}/cabal/.halcyon/${file}" || return 1
		done || return 0
}


build_cabal_dir () {
	expect_vars HALCYON_BASE

	local tag source_dir
	expect_args tag source_dir -- "$@"

	if ! rm -rf "${HALCYON_BASE}/cabal"; then
		log_error 'Failed to prepare Cabal directory'
		return 1
	fi

	local ghc_version ghc_major ghc_minor
	ghc_version=$( get_tag_ghc_version "${tag}" )
	ghc_major="${ghc_version%%.*}"
	ghc_minor="${ghc_version#*.}"
	ghc_minor="${ghc_minor%%.*}"

	# NOTE: Bootstrapping cabal-install 1.20.* with GHC 7.6.* fails.
	if (( ghc_major < 7 || ghc_minor < 8 )); then
		log_error "Unexpected GHC version: ${ghc_version}"
		log
		log_indent 'To bootstrap Cabal, use GHC 7.8.2 or newer'
		log
		return 1
	fi

	local cabal_version cabal_original_url cabal_dir cabal_home_dir
	cabal_version=$( get_tag_cabal_version "${tag}" )
	cabal_original_url=$( map_cabal_version_to_original_url "${cabal_version}" ) || return 1
	cabal_dir=$( get_tmp_dir "cabal-${cabal_version}" ) || return 1
	cabal_home_dir=$( get_tmp_dir 'disregard-this-advice' ) || return 1

	log 'Building Cabal directory'

	acquire_original_source "${cabal_original_url}" "${cabal_dir}" || return 1

	local cabal_sub_dir
	if ! cabal_sub_dir=$(
		find_tree "${cabal_dir}" -type d -maxdepth 1 -name 'cabal-install-*' |
		match_exactly_one
	); then
		log_error 'Failed to detect Cabal source directory'
		return 1
	fi

	local cabal_build_dir
	cabal_build_dir="${cabal_dir}/${cabal_sub_dir}"
	expect_existing "${cabal_build_dir}" || return 1

	if [[ -f "${source_dir}/.halcyon/cabal-pre-build-hook" ]]; then
		log 'Executing Cabal pre-build hook'
		if ! HALCYON_INTERNAL_RECURSIVE=1 \
			"${source_dir}/.halcyon/cabal-pre-build-hook" \
				"${tag}" "${source_dir}" "${cabal_build_dir}" 2>&1 | quote
		then
			log_error 'Failed to execute Cabal pre-build hook'
			return 1
		fi
		log 'Cabal pre-build hook executed'
	fi

	log 'Bootstrapping Cabal'

	if ! (
		cd "${cabal_build_dir}" &&
		patch -s <<-EOF
			--- a/bootstrap.sh
			+++ b/bootstrap.sh
			@@ -217,3 +217,3 @@ install_pkg () {

			-  \${GHC} --make Setup -o Setup ||
			+  \${GHC} -L"${HALCYON_BASE}/ghc/usr/lib" --make Setup -o Setup ||
			      die "Compiling the Setup script failed."
EOF
	); then
		log_error 'Failed to patch Cabal'
		return 1
	fi

	# NOTE: Bootstrapping cabal-install with GHC 7.8.* may fail unless
	# --no-doc is specified.
	# https://ghc.haskell.org/trac/ghc/ticket/9174
	local bootstrapped_size
	if ! (
		cd "${cabal_build_dir}" &&
		HOME="${cabal_home_dir}" \
		EXTRA_CONFIGURE_OPTS="--extra-lib-dirs=${HALCYON_BASE}/ghc/usr/lib" \
			./bootstrap.sh --no-doc 2>&1 | quote
	) ||
		! copy_file "${cabal_home_dir}/.cabal/bin/cabal" "${HALCYON_BASE}/cabal/bin/cabal" ||
		! copy_cabal_magic "${source_dir}" ||
		! bootstrapped_size=$( get_size "${HALCYON_BASE}/cabal" )
	then
		log_error 'Failed to bootstrap Cabal'
		return 1
	fi
	log "Cabal bootstrapped, ${bootstrapped_size}"

	if [[ -f "${source_dir}/.halcyon/cabal-post-build-hook" ]]; then
		log 'Executing Cabal post-build hook'
		if ! HALCYON_INTERNAL_RECURSIVE=1 \
			"${source_dir}/.halcyon/cabal-post-build-hook" \
				"${tag}" "${source_dir}" "${cabal_build_dir}" 2>&1 | quote
		then
			log_error 'Failed to execute Cabal post-build hook'
			return 1
		fi
		log 'Cabal post-build hook executed'
	fi

	log_indent_begin 'Stripping Cabal directory...'

	local stripped_size
	if ! strip_tree "${HALCYON_BASE}/cabal" ||
		! stripped_size=$( get_size "${HALCYON_BASE}/cabal" )
	then
		log_indent_end 'error'
		return 1
	fi
	log_indent_end "done, ${stripped_size}"

	if ! derive_base_cabal_tag "${tag}" >"${HALCYON_BASE}/cabal/.halcyon-tag"; then
		log_error 'Failed to write Cabal tag'
		return 1
	fi
}


cabal_update () {
	expect_vars HALCYON_BASE

	local stderr
	stderr=$( get_tmp_file 'cabal-update.stderr' ) || return 1

	# NOTE: cabal-install 1.20.0.5 enforces the require-sandbox option
	# even for the update command.
	# https://github.com/haskell/cabal/issues/2309
	local updated_size
	if ! cabal_do '.' --no-require-sandbox update >"${stderr}" 2>&1 ||
		! updated_size=$( get_size "${HALCYON_BASE}/cabal" )
	then
		log_indent_end 'error'
		quote <"${stderr}"
		return 1
	fi
	log_indent_end "done, ${updated_size}"
}


update_cabal_package_db () {
	expect_vars HALCYON_BASE

	local tag
	expect_args tag -- "$@"

	local cabal_date
	cabal_date=$( get_date '+%Y-%m-%d' )

	log 'Updating Cabal directory'

	if ! format_cabal_config "${tag}" >"${HALCYON_BASE}/cabal/config"; then
		log_error 'Failed to write Cabal config'
		return 1
	fi

	if [[ -f "${source_dir}/.halcyon/cabal-pre-update-hook" ]]; then
		log 'Executing Cabal pre-update hook'
		if ! HALCYON_INTERNAL_RECURSIVE=1 \
			"${source_dir}/.halcyon/cabal-pre-update-hook" 2>&1 | quote
		then
			log_error 'Failed to execute Cabal pre-update hook'
			return 1
		fi
		log 'Cabal pre-update hook executed'
	fi

	log_indent_begin 'Updating Cabal package database...'

	cabal_update || return 1

	if [[ -f "${source_dir}/.halcyon/cabal-post-update-hook" ]]; then
		log 'Executing Cabal post-update hook'
		if ! HALCYON_INTERNAL_RECURSIVE=1 \
			"${source_dir}/.halcyon/cabal-post-update-hook" 2>&1 | quote
		then
			log_error 'Failed to execute Cabal post-update hook'
			return 1
		fi
		log 'Cabal post-update hook executed'
	fi

	if ! derive_updated_cabal_tag "${tag}" "${cabal_date}" >"${HALCYON_BASE}/cabal/.halcyon-tag"; then
		log_error 'Failed to write Cabal tag'
		return 1
	fi
}


archive_cabal_dir () {
	expect_vars HALCYON_BASE HALCYON_NO_ARCHIVE \
		HALCYON_INTERNAL_PLATFORM

	if (( HALCYON_NO_ARCHIVE )); then
		return 0
	fi

	expect_existing "${HALCYON_BASE}/cabal/.halcyon-tag" || return 1

	local cabal_tag archive_name
	cabal_tag=$( detect_cabal_tag "${HALCYON_BASE}/cabal/.halcyon-tag" ) || return 1
	archive_name=$( format_cabal_archive_name "${cabal_tag}" )

	log 'Archiving Cabal directory'

	create_cached_archive "${HALCYON_BASE}/cabal" "${archive_name}" || return 1
	upload_cached_file "${HALCYON_INTERNAL_PLATFORM}" "${archive_name}" || return 1

	local cabal_date
	cabal_date=$( get_tag_cabal_date "${cabal_tag}" )
	if [[ -z "${cabal_date}" ]]; then
		return 0
	fi

	local updated_prefix updated_pattern
	updated_prefix=$( format_updated_cabal_archive_name_prefix "${cabal_tag}" )
	updated_pattern=$( format_updated_cabal_archive_name_pattern "${cabal_tag}" )

	delete_matching_private_stored_files "${HALCYON_INTERNAL_PLATFORM}" "${updated_prefix}" "${updated_pattern}" "${archive_name}" || return 1
}


validate_base_cabal_dir () {
	expect_vars HALCYON_BASE

	local tag
	expect_args tag -- "$@"

	local base_tag
	base_tag=$( derive_base_cabal_tag "${tag}" )
	detect_tag "${HALCYON_BASE}/cabal/.halcyon-tag" "${base_tag//./\.}" || return 1
}


validate_updated_cabal_date () {
	local candidate_date
	expect_args candidate_date -- "$@"

	local today_date
	today_date=$( get_date '+%Y-%m-%d' )

	if [[ "${candidate_date}" < "${today_date}" ]]; then
		return 1
	fi
}


validate_updated_cabal_dir () {
	expect_vars HALCYON_BASE

	local tag
	expect_args tag -- "$@"

	local updated_pattern candidate_tag
	updated_pattern=$( derive_updated_cabal_tag_pattern "${tag}" )
	candidate_tag=$( detect_tag "${HALCYON_BASE}/cabal/.halcyon-tag" "${updated_pattern}" ) || return 1

	local candidate_date
	candidate_date=$( get_tag_cabal_date "${candidate_tag}" )
	validate_updated_cabal_date "${candidate_date}" || return 1

	if [[ ! -f "${HALCYON_BASE}/cabal/config" ]]; then
		return 1
	fi

	echo "${candidate_tag}"
}


match_updated_cabal_archive_name () {
	local tag
	expect_args tag -- "$@"

	local updated_pattern candidate_name
	updated_pattern=$( format_updated_cabal_archive_name_pattern "${tag}" )
	candidate_name=$(
		filter_matching "^${updated_pattern}$" |
		sort_natural -u |
		filter_last |
		match_exactly_one
	) || return 1

	local candidate_date
	candidate_date=$( format_updated_cabal_archive_name_date "${candidate_name}" )
	validate_updated_cabal_date "${candidate_date}" || return 1

	echo "${candidate_name}"
}


restore_base_cabal_dir () {
	expect_vars HALCYON_BASE \
		HALCYON_INTERNAL_PLATFORM

	local tag
	expect_args tag -- "$@"

	local base_name
	base_name=$( format_base_cabal_archive_name "${tag}" )

	if validate_base_cabal_dir "${tag}" >'/dev/null'; then
		log 'Using existing Cabal directory'

		touch_cached_file "${base_name}"
		return 0
	fi
	rm -rf "${HALCYON_BASE}/cabal" || true

	log 'Restoring base Cabal directory'

	if ! extract_cached_archive_over "${base_name}" "${HALCYON_BASE}/cabal" ||
		! validate_base_cabal_dir "${tag}" >'/dev/null'
	then
		rm -rf "${HALCYON_BASE}/cabal" || true
		cache_stored_file "${HALCYON_INTERNAL_PLATFORM}" "${base_name}" || return 1

		if ! extract_cached_archive_over "${base_name}" "${HALCYON_BASE}/cabal" ||
			! validate_base_cabal_dir "${tag}" >'/dev/null'
		then
			rm -rf "${HALCYON_BASE}/cabal" || true

			log_error 'Failed to restore base Cabal directory'
			return 1
		fi
	else
		touch_cached_file "${base_name}"
	fi
}


restore_cached_updated_cabal_dir () {
	expect_vars HALCYON_BASE HALCYON_CACHE

	local tag
	expect_args tag -- "$@"

	local updated_name
	updated_name=$(
		find_tree "${HALCYON_CACHE}" -maxdepth 1 -type f |
		match_updated_cabal_archive_name "${tag}"
	) || true

	if validate_updated_cabal_dir "${tag}" >'/dev/null'; then
		log 'Using existing Cabal directory'

		touch_cached_file "${updated_name}"
		return 0
	fi
	rm -rf "${HALCYON_BASE}/cabal" || true

	if [[ -z "${updated_name}" ]]; then
		return 1
	fi

	log 'Restoring Cabal directory'

	if ! extract_cached_archive_over "${updated_name}" "${HALCYON_BASE}/cabal" ||
		! validate_updated_cabal_dir "${tag}" >'/dev/null'
	then
		rm -rf "${HALCYON_BASE}/cabal" || true

		log_error 'Failed to restore Cabal directory'
		return 1
	else
		touch_cached_file "${updated_name}"
	fi
}


restore_updated_cabal_dir () {
	expect_vars HALCYON_BASE \
		HALCYON_INTERNAL_PLATFORM

	local tag
	expect_args tag -- "$@"

	local archive_prefix
	archive_prefix=$( format_updated_cabal_archive_name_prefix "${tag}" )

	if restore_cached_updated_cabal_dir "${tag}"; then
		return 0
	fi

	log 'Locating Cabal directories'

	local updated_name
	updated_name=$(
		list_stored_files "${HALCYON_INTERNAL_PLATFORM}/${archive_prefix}" |
		sed "s:^${HALCYON_INTERNAL_PLATFORM}/::" |
		match_updated_cabal_archive_name "${tag}"
	) || return 1

	log 'Restoring Cabal directory'

	cache_stored_file "${HALCYON_INTERNAL_PLATFORM}" "${updated_name}" || return 1

	if ! extract_cached_archive_over "${updated_name}" "${HALCYON_BASE}/cabal" ||
		! validate_updated_cabal_dir "${tag}" >'/dev/null'
	then
		rm -rf "${HALCYON_BASE}/cabal" || true

		log_error 'Failed to restore Cabal directory'
		return 1
	fi
}


help_cabal_symlink () {
	log
	quote <<-EOF
		To symlink the Halcyon Cabal config:
		$ mv ~/.cabal/config ~/.cabal/config.original
		$ mkdir -p ~/.cabal
		$ ln -s "${HALCYON_BASE}/cabal/config" ~/.cabal/config

		To use the Halcyon Cabal config manually:
		$ cabal --config-file="${HALCYON_BASE}/cabal/config" ...
EOF
}


symlink_cabal_config () {
	expect_vars HOME HALCYON_BASE HALCYON_NO_MODIFY_HOME \
		HALCYON_INTERNAL_RECURSIVE

	if [[ ! -f "${HALCYON_BASE}/cabal/.halcyon-tag" ]] || (( HALCYON_INTERNAL_RECURSIVE )); then
		return 0
	fi

	if (( HALCYON_NO_MODIFY_HOME )); then
		log_warning 'Cannot symlink Cabal config'
		help_cabal_symlink
		return 0
	fi

	if [[ -f "${HOME}/.cabal/config" ]]; then
		# TODO: Remove the .halcyon-cabal.config line in the future.
		local actual_config
		if ! actual_config=$( readlink "${HOME}/.cabal/config" ) ||
			[[ "${actual_config}" != "${HALCYON_BASE}/cabal/.halcyon-cabal.config" &&
				"${actual_config}" != "${HALCYON_BASE}/cabal/config"
			]]
		then
			log_warning 'Cannot symlink Cabal config'
			help_cabal_symlink
			return 0
		fi
	fi

	if ! rm -f "${HOME}/.cabal/config" ||
		! mkdir -p "${HOME}/.cabal" ||
		! ln -fs "${HALCYON_BASE}/cabal/config" "${HOME}/.cabal/config"
	then
		log_warning 'Failed to symlink Cabal config'
	fi
}


install_cabal_dir () {
	expect_vars HALCYON_NO_BUILD HALCYON_NO_BUILD_DEPENDENCIES \
		HALCYON_CABAL_REBUILD HALCYON_CABAL_UPDATE

	local tag source_dir
	expect_args tag source_dir -- "$@"

	if ! (( HALCYON_CABAL_REBUILD )); then
		if ! (( HALCYON_CABAL_UPDATE )) &&
			restore_updated_cabal_dir "${tag}"
		then
			symlink_cabal_config
			return 0
		fi

		if restore_base_cabal_dir "${tag}"; then
			update_cabal_package_db "${tag}" || return 1
			archive_cabal_dir || return 1
			symlink_cabal_config
			return 0
		fi

		# NOTE: Returns 2 if build is needed.
		if (( HALCYON_NO_BUILD )) || (( HALCYON_NO_BUILD_DEPENDENCIES )); then
			log_error 'Cannot build Cabal directory'
			return 2
		fi
	fi

	build_cabal_dir "${tag}" "${source_dir}" || return 1
	archive_cabal_dir || return 1
	update_cabal_package_db "${tag}" || return 1
	archive_cabal_dir || return 1
	symlink_cabal_config
}


cabal_do () {
	expect_vars HALCYON_BASE

	expect_existing "${HALCYON_BASE}/cabal/.halcyon-tag" || return 1

	local work_dir
	expect_args work_dir -- "$@"
	shift

	expect_existing "${work_dir}" || return 1
	(
		cd "${work_dir}" &&
		cabal --config-file="${HALCYON_BASE}/cabal/config" "$@"
	) || return 1
}


sandboxed_cabal_do () {
	expect_vars HALCYON_BASE

	local work_dir
	expect_args work_dir -- "$@"
	shift

	expect_existing "${HALCYON_BASE}/sandbox" "${work_dir}" || return 1

	# NOTE: Specifying a cabal.sandbox.config file changes where Cabal
	# looks for a cabal.config file.
	# https://github.com/haskell/cabal/issues/1915
	local saved_config
	saved_config=''
	if [[ -f "${HALCYON_BASE}/sandbox/cabal.config" ]]; then
		if ! saved_config=$( get_tmp_file 'saved-sandbox-cabal.config' ) ||
			! mv "${HALCYON_BASE}/sandbox/cabal.config" "${saved_config}"
		then
			log_error 'Failed to save existing sandbox Cabal config'
			return 1
		fi
	fi
	if [[ -f "${work_dir}/cabal.config" ]]; then
		if ! copy_file "${work_dir}/cabal.config" "${HALCYON_BASE}/sandbox/cabal.config"; then
			log_error 'Failed to copy temporary sandbox Cabal config'
			return 1
		fi
	fi

	local status
	status=0
	if ! cabal_do "${work_dir}" --sandbox-config-file="${HALCYON_BASE}/sandbox/cabal.sandbox.config" "$@"; then
		status=1
	fi

	if ! rm -f "${HALCYON_BASE}/sandbox/cabal.config"; then
		log_error 'Failed to remove temporary sandbox Cabal config'
		return 1
	fi
	if [[ -n "${saved_config}" ]]; then
		if ! mv "${saved_config}" "${HALCYON_BASE}/sandbox/cabal.config"; then
			log_error 'Failed to restore saved sandbox Cabal config'
			return 1
		fi
	fi

	return "${status}"
}


cabal_create_sandbox () {
	expect_vars HALCYON_BASE

	local stderr
	stderr=$( get_tmp_file 'cabal-sandbox-init.stderr' ) || return 1

	mkdir -p "${HALCYON_BASE}/sandbox" || return 1

	if ! cabal_do "${HALCYON_BASE}/sandbox" sandbox init --sandbox '.' >"${stderr}" 2>&1; then
		quote <"${stderr}"
		return 1
	fi
}


cabal_dry_freeze_constraints () {
	local label source_dir
	expect_args label source_dir -- "$@"

	local stderr
	stderr=$( get_tmp_file 'cabal-freeze.stderr' ) || return 1

	# NOTE: Cabal automatically sets global installed constraints for
	# installed packages, even during a freeze dry run.  Hence, if a
	# local constraint conflicts with an installed package, Cabal will
	# fail to resolve dependencies.
	# Cabal freeze always ignores any constraints set both in the local
	# cabal.config file, and in the global ~/.cabal/config file.
	# https://github.com/haskell/cabal/issues/2178
	# https://github.com/haskell/cabal/issues/2265
	local constraints
	if ! constraints=$(
		cabal_do "${source_dir}" --no-require-sandbox freeze --dry-run 2>"${stderr}" |
		read_constraints_from_cabal_dry_freeze |
		filter_correct_constraints "${label}" |
		sort_natural
	); then
		quote <"${stderr}"
		return 1
	fi

	echo "${constraints}"
}


sandboxed_cabal_dry_freeze_constraints () {
	local label source_dir
	expect_args label source_dir -- "$@"

	local stderr
	stderr=$( get_tmp_file 'cabal-freeze.stderr' ) || return 1

	local constraints
	if ! constraints=$(
		sandboxed_cabal_do "${source_dir}" freeze --dry-run 2>"${stderr}" |
		read_constraints_from_cabal_dry_freeze |
		filter_correct_constraints "${label}" |
		sort_natural
	); then
		quote <"${stderr}"
		return 1
	fi

	echo "${constraints}"
}


temporarily_sandboxed_cabal_dry_freeze_constraints () {
	expect_vars HALCYON_BASE

	local label source_dir
	expect_args label source_dir -- "$@"

	local saved_sandbox
	saved_sandbox=''
	if [[ -d "${HALCYON_BASE}/sandbox" ]]; then
		if ! saved_sandbox=$( get_tmp_dir 'saved-sandbox' ) ||
			! mv "${HALCYON_BASE}/sandbox" "${saved_sandbox}"
		then
			log_error 'Failed to save existing sandbox'
			return 1
		fi
	fi

	log 'Creating temporary sandbox'

	if ! cabal_create_sandbox; then
		log_error 'Failed to create temporary sandbox'
		return 1
	fi

	if ! add_sandbox_sources "${source_dir}"; then
		log_error 'Failed to add temporary sandbox sources'
		return 1
	fi

	local constraints
	constraints=$( sandboxed_cabal_dry_freeze_constraints "${label}" "${source_dir}" ) || return 1

	if ! rm -rf "${HALCYON_BASE}/sandbox"; then
		log_error 'Failed to remove temporary sandbox'
		return 1
	fi
	if [[ -n "${saved_sandbox}" ]]; then
		if ! mv "${saved_sandbox}" "${HALCYON_BASE}/sandbox"; then
			log_error 'Failed to restore saved sandbox'
			return 1
		fi
	fi

	echo "${constraints}"
}


cabal_determine_constraints () {
	local label source_dir
	expect_args label source_dir -- "$@"

	local constraints
	if [[ -f "${source_dir}/.halcyon/sandbox-sources" ]]; then
		constraints=$( temporarily_sandboxed_cabal_dry_freeze_constraints "${label}" "${source_dir}" ) || return 1
	else
		constraints=$( cabal_dry_freeze_constraints "${label}" "${source_dir}" ) || return 1
	fi

	echo "${constraints}"
}


cabal_unpack_over () {
	local thing unpack_dir
	expect_args thing unpack_dir -- "$@"

	local stderr
	stderr=$( get_tmp_file 'cabal-unpack.stderr' ) || return 1

	rm -rf "${unpack_dir}" || return 1
	mkdir -p "${unpack_dir}" || return 1

	local label
	if ! label=$(
		cabal_do "${unpack_dir}" unpack "${thing}" 2>"${stderr}" |
		filter_matching '^Unpacking to ' |
		match_exactly_one |
		sed 's:^Unpacking to \(.*\)/$:\1:'
	); then
		quote <"${stderr}"
		return 1
	fi

	echo "${label}"
}


populate_cabal_setup_exe_cache () {
	expect_vars HOME

	# NOTE: Haste needs Cabal to generate HOME/.cabal/setup-exe-cache.
	# https://github.com/valderman/haste-compiler/issues/257
	if [[ -f "${HOME}/.cabal/setup-exe-cache" ]]; then
		return 0
	fi

	log 'Populating Cabal setup executable cache'

	local setup_dir
	setup_dir=$( get_tmp_dir 'cabal-setup-exe-cache-sandbox' ) || return 1

	if ! mkdir -p "${setup_dir}" ||
		! cabal_do "${setup_dir}" sandbox init --sandbox '.' 2>&1 | quote ||
		! cabal_do "${setup_dir}" install 'populate-setup-exe-cache' 2>&1 | quote
	then
		log_error 'Failed to populate Cabal setup executable cache'
		return 1
	fi
	expect_existing "${HOME}/.cabal/setup-exe-cache" || return 1
}
