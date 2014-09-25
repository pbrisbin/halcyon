#!/usr/bin/env bash


function log_add_config_help () {
	local sandbox_constraints
	expect_args sandbox_constraints -- "$@"

	log_file_indent <<-EOF
		To use explicit constraints, add cabal.config:
		$ cat >cabal.config <<EOF
EOF
	echo_constraints <<<"${sandbox_constraints}" >&2 || die
	echo 'EOF' >&2
}




function echo_sandbox_tag () {
	expect_vars HALCYON_DIR

	local ghc_version app_label sandbox_digest
	expect_args ghc_version app_label sandbox_digest -- "$@"

	local os
	os=$( detect_os ) || die

	echo -e "${HALCYON_DIR}\t${os}\tghc-${ghc_version}\t${app_label}\t${sandbox_digest}"
}


function echo_sandbox_tag_ghc_version () {
	local sandbox_tag
	expect_args sandbox_tag -- "$@"

	awk '{ print $3 }' <<<"${sandbox_tag}" | sed 's/^ghc-//'
}


function echo_sandbox_tag_app_label () {
	local sandbox_tag
	expect_args sandbox_tag -- "$@"

	awk '{ print $4 }' <<<"${sandbox_tag}"
}


function echo_sandbox_tag_digest () {
	local sandbox_tag
	expect_args sandbox_tag -- "$@"

	awk '{ print $5 }' <<<"${sandbox_tag}"
}




function echo_sandbox_archive () {
	local sandbox_tag
	expect_args sandbox_tag -- "$@"

	local ghc_version app_label sandbox_digest
	ghc_version=$( echo_sandbox_tag_ghc_version "${sandbox_tag}" ) || die
	app_label=$( echo_sandbox_tag_app_label "${sandbox_tag}" ) || die
	sandbox_digest=$( echo_sandbox_tag_digest "${sandbox_tag}" ) || die

	echo "halcyon-sandbox-ghc-${ghc_version}-${app_label}-${sandbox_digest}.tar.gz"
}


function echo_sandbox_config () {
	local sandbox_tag
	expect_args sandbox_tag -- "$@"

	local ghc_version app_label sandbox_digest
	ghc_version=$( echo_sandbox_tag_ghc_version "${sandbox_tag}" ) || die
	app_label=$( echo_sandbox_tag_app_label "${sandbox_tag}" ) || die
	sandbox_digest=$( echo_sandbox_tag_digest "${sandbox_tag}" ) || die

	echo "halcyon-sandbox-ghc-${ghc_version}-${app_label}-${sandbox_digest}.cabal.config"
}




function echo_sandbox_config_ghc_version () {
	local sandbox_config
	expect_args sandbox_config -- "$@"

	local config_part
	config_part="${sandbox_config#halcyon-sandbox-ghc-}"

	echo "${config_part%%-*}"
}


function echo_sandbox_config_app_label () {
	local sandbox_config
	expect_args sandbox_config -- "$@"

	local config_part
	config_part="${sandbox_config#halcyon-sandbox-ghc-*-}"

	echo "${config_part%-*.cabal.config}"
}


function echo_sandbox_config_digest () {
	local sandbox_config
	expect_args sandbox_config -- "$@"

	local config_part
	config_part="${sandbox_config##*-}"

	echo "${config_part%.cabal.config}"
}




function echo_sandbox_config_prefix () {
	local ghc_version
	expect_args ghc_version -- "$@"

	echo "halcyon-sandbox-ghc-${ghc_version}-"
}


function echo_sandbox_config_pattern () {
	local ghc_version
	expect_args ghc_version -- "$@"

	echo "halcyon-sandbox-ghc-${ghc_version//./\.}.*\.cabal\.config"
}




function echo_sandbox_description () {
	local sandbox_tag
	expect_args sandbox_tag -- "$@"

	local app_label sandbox_digest
	app_label=$( echo_sandbox_tag_app_label "${sandbox_tag}" ) || die
	sandbox_digest=$( echo_sandbox_tag_digest "${sandbox_tag}" ) || die

	echo "sandbox ${sandbox_digest:0:7} (${app_label})"
}




function echo_tmp_sandbox_config () {
	mktemp -u '/tmp/halcyon-sandbox.cabal.config.XXXXXXXXXX'
}


function echo_tmp_customize_sandbox_dir () {
	mktemp -du '/tmp/halcyon-customize-sandbox.XXXXXXXXXX'
}




function validate_sandbox_tag () {
	local sandbox_tag
	expect_args sandbox_tag -- "$@"

	local candidate_tag
	candidate_tag=$( match_exactly_one ) || die

	if [ "${candidate_tag}" != "${sandbox_tag}" ]; then
		return 1
	fi
}


function validate_sandbox_config () {
	local sandbox_digest
	expect_args sandbox_digest -- "$@"

	local candidate_digest
	candidate_digest=$( read_constraints | echo_constraints_digest ) || die

	if [ "${candidate_digest}" != "${sandbox_digest}" ]; then
		return 1
	fi
}




function build_sandbox () {
	expect_vars HALCYON_DIR
	expect_existing "${HALCYON_DIR}/ghc/tag" "${HALCYON_DIR}/cabal/tag"

	local app_dir sandbox_constraints sandbox_tag
	expect_args app_dir sandbox_constraints sandbox_tag -- "$@"
	expect_existing "${app_dir}"

	local sandbox_digest sandbox_description
	sandbox_digest=$( echo_sandbox_tag_digest "${sandbox_tag}" ) || die
	sandbox_description=$( echo_sandbox_description "${sandbox_tag}" ) || die

	log "Building ${sandbox_description}"

	if ! [ -d "${HALCYON_DIR}/sandbox" ]; then
		cabal_create_sandbox "${HALCYON_DIR}/sandbox" || die

		# NOTE: Listing executable-only packages in build-tools causes Cabal to
		# expect the executables to be installed, but not to install the packages.
		# https://github.com/haskell/cabal/issues/220

		# NOTE: Listing executable-only packages in build-depends causes Cabal to
		# install the packages, and to fail to recognise the packages have been
		# installed.
		# https://github.com/haskell/cabal/issues/779

		local script_constraint
		if script_constraint=$( detect_customize_sandbox_script_constraint <<<"${sandbox_constraints}" ); then
			expect_vars HALCYON_CUSTOMIZE_SANDBOX_SCRIPT
			expect_existing "${app_dir}/${HALCYON_CUSTOMIZE_SANDBOX_SCRIPT}"

			log "Customizing ${sandbox_description}"

			local script_digest candidate_digest
			script_digest="${script_constraint##* }"
			candidate_digest=$( echo_customize_sandbox_script_digest <"${app_dir}/${HALCYON_CUSTOMIZE_SANDBOX_SCRIPT}" ) || die

			if [ "${candidate_digest}" != "${script_digest}" ]; then
				die "Expected customize sandbox script ${script_digest:0:7} and not ${candidate_digest:0:7}"
			fi

			source "${app_dir}/${HALCYON_CUSTOMIZE_SANDBOX_SCRIPT}"
			customize_sandbox "${app_dir}"

			local customized_size
			customized_size=$( measure_recursively "${HALCYON_DIR}/sandbox" ) || die
			log "Customized ${sandbox_description}, ${customized_size}"
		fi
	fi
	cabal_install_deps "${HALCYON_DIR}/sandbox" "${app_dir}" || die

	echo_constraints <<<"${sandbox_constraints}" >"${HALCYON_DIR}/sandbox/cabal.config" || die
	echo "${sandbox_tag}" >"${HALCYON_DIR}/sandbox/tag" || die

	local sandbox_size
	sandbox_size=$( measure_recursively "${HALCYON_DIR}/sandbox" ) || die
	log "Built ${sandbox_description}, ${sandbox_size}"

	log "Validating ${sandbox_description}"

	# NOTE: Frozen constraints should never differ before and after installation.
	# https://github.com/haskell/cabal/issues/1896

	local actual_constraints actual_digest
	actual_constraints=$( freeze_actual_constraints "${HALCYON_DIR}/sandbox" "${app_dir}" ) || die
	actual_digest=$( echo_constraints_digest <<<"${actual_constraints}" ) || die

	if [ "${actual_digest}" != "${sandbox_digest}" ]; then
		log_warning "Actual sandbox digest is ${actual_digest:0:7}"
		log_warning 'Unexpected constraints difference:'
		echo_constraints_difference "${sandbox_constraints}" "${actual_constraints}" | log_file_indent
	fi
}


function strip_sandbox () {
	expect_vars HALCYON_DIR
	expect_existing "${HALCYON_DIR}/sandbox/tag"

	local sandbox_tag sandbox_description
	sandbox_tag=$( <"${HALCYON_DIR}/sandbox/tag" ) || die
	sandbox_description=$( echo_sandbox_description "${sandbox_tag}" ) || die

	log_begin "Stripping ${sandbox_description}..."

	find "${HALCYON_DIR}/sandbox"       \
			-type f        -and \
			\(                  \
			-name '*.so'   -or  \
			-name '*.so.*' -or  \
			-name '*.a'         \
			\)                  \
			-print0 |
		strip0 --strip-unneeded

	local sandbox_size
	sandbox_size=$( measure_recursively "${HALCYON_DIR}/sandbox" ) || die
	log_end "done, ${sandbox_size}"
}




function archive_sandbox () {
	expect_vars HALCYON_DIR HALCYON_CACHE_DIR HALCYON_NO_ARCHIVE
	expect_existing "${HALCYON_DIR}/sandbox/tag"

	if (( ${HALCYON_NO_ARCHIVE} )); then
		return 0
	fi

	local sandbox_tag sandbox_description
	sandbox_tag=$( <"${HALCYON_DIR}/sandbox/tag" ) || die
	sandbox_description=$( echo_sandbox_description "${sandbox_tag}" ) || die

	log "Archiving ${sandbox_description}"

	local sandbox_archive sandbox_config os
	sandbox_archive=$( echo_sandbox_archive "${sandbox_tag}" ) || die
	sandbox_config=$( echo_sandbox_config "${sandbox_tag}" ) || die
	os=$( detect_os ) || die

	rm -f "${HALCYON_CACHE_DIR}/${sandbox_archive}" "${HALCYON_CACHE_DIR}/${sandbox_config}" || die
	tar_archive "${HALCYON_DIR}/sandbox" "${HALCYON_CACHE_DIR}/${sandbox_archive}" || die
	cp "${HALCYON_DIR}/sandbox/cabal.config" "${HALCYON_CACHE_DIR}/${sandbox_config}" || die
	upload_prebuilt "${HALCYON_CACHE_DIR}/${sandbox_archive}" "${os}" || die
	upload_prebuilt "${HALCYON_CACHE_DIR}/${sandbox_config}" "${os}" || die
}


function restore_sandbox () {
	expect_vars HALCYON_DIR HALCYON_CACHE_DIR

	local sandbox_tag
	expect_args sandbox_tag -- "$@"

	local sandbox_digest sandbox_description
	sandbox_digest=$( echo_sandbox_tag_digest "${sandbox_tag}" ) || die
	sandbox_description=$( echo_sandbox_description "${sandbox_tag}" ) || die

	log "Restoring ${sandbox_description}"

	if [ -f "${HALCYON_DIR}/sandbox/tag" ] &&
		validate_sandbox_tag "${sandbox_tag}" <"${HALCYON_DIR}/sandbox/tag" &&
		validate_sandbox_config "${sandbox_digest}" <"${HALCYON_DIR}/sandbox/cabal.config"
	then
		return 0
	fi
	rm -rf "${HALCYON_DIR}/sandbox" || die

	local os sandbox_archive
	os=$( detect_os ) || die
	sandbox_archive=$( echo_sandbox_archive "${sandbox_tag}" ) || die

	if ! [ -f "${HALCYON_CACHE_DIR}/${sandbox_archive}" ] ||
		! tar_extract "${HALCYON_CACHE_DIR}/${sandbox_archive}" "${HALCYON_DIR}/sandbox" ||
		! [ -f "${HALCYON_DIR}/sandbox/tag" ] ||
		! validate_sandbox_tag "${sandbox_tag}" <"${HALCYON_DIR}/sandbox/tag" ||
		! validate_sandbox_config "${sandbox_digest}" <"${HALCYON_DIR}/sandbox/cabal.config"
	then
		rm -rf "${HALCYON_CACHE_DIR}/${sandbox_archive}" "${HALCYON_DIR}/sandbox" || die

		if ! download_prebuilt "${os}" "${sandbox_archive}" "${HALCYON_CACHE_DIR}"; then
			log_warning "${sandbox_description} is not prebuilt"
			return 1
		fi

		if ! tar_extract "${HALCYON_CACHE_DIR}/${sandbox_archive}" "${HALCYON_DIR}/sandbox" ||
			! [ -f "${HALCYON_DIR}/sandbox/tag" ] ||
			! validate_sandbox_tag "${sandbox_tag}" <"${HALCYON_DIR}/sandbox/tag" ||
			! validate_sandbox_config "${sandbox_digest}" <"${HALCYON_DIR}/sandbox/cabal.config"
		then
			rm -rf "${HALCYON_CACHE_DIR}/${sandbox_archive}" "${HALCYON_DIR}/sandbox" || die
			log_warning "Restoring ${sandbox_archive} failed"
			return 1
		fi
	fi
}




function infer_sandbox_constraints () {
	expect_vars HALCYON_FAKE_APP

	local app_dir
	expect_args app_dir -- "$@"
	expect_existing "${app_dir}"

	log 'Inferring sandbox constraints'

	local sandbox_constraints
	if [ -f "${app_dir}/cabal.config" ]; then
		sandbox_constraints=$( detect_constraints "${app_dir}" ) || die
	else
		sandbox_constraints=$( freeze_implicit_constraints "${app_dir}" ) || die
		if ! (( ${HALCYON_FAKE_APP} )); then
			log_warning 'Expected cabal.config with explicit constraints'
			log
			log_add_config_help "${sandbox_constraints}"
			log
		else
			echo_constraints <<<"${sandbox_constraints}" >&2 || die
		fi
	fi

	echo "${sandbox_constraints}"
}


function infer_sandbox_digest () {
	local sandbox_constraints
	expect_args sandbox_constraints -- "$@"

	log_begin 'Inferring sandbox digest...'

	local sandbox_digest
	sandbox_digest=$( echo_constraints_digest <<<"${sandbox_constraints}" ) || die

	log_end "done, ${sandbox_digest:0:7}"

	echo "${sandbox_digest}"
}


function locate_matched_sandbox_tag () {
	expect_vars HALCYON_DIR HALCYON_CACHE_DIR
	expect_existing "${HALCYON_DIR}/ghc/tag"

	local sandbox_constraints
	expect_args sandbox_constraints -- "$@"

	log 'Locating matched sandboxes'

	local os ghc_tag config_prefix config_pattern
	os=$( detect_os ) || die
	ghc_tag=$( <"${HALCYON_DIR}/ghc/tag" ) || die
	ghc_version=$( echo_ghc_tag_version "${ghc_tag}" ) || die
	config_prefix=$( echo_sandbox_config_prefix "${ghc_version}" ) || die
	config_pattern=$( echo_sandbox_config_pattern "${ghc_version}" ) || die

	local matched_configs
	if ! matched_configs=$(
		list_prebuilt "${os}/${config_prefix}" |
		sed "s:${os}/::" |
		filter_matching "^${config_pattern}$" |
		sort_naturally |
		match_at_least_one
	); then
		log_warning 'No matched sandbox is prebuilt'
		return 1
	fi

	local config
	while read -r config; do
		local digest
		digest=$( echo_sandbox_config_digest "${config}" ) || die

		if ! [ -f "${HALCYON_CACHE_DIR}/${config}" ] ||
			! validate_sandbox_config "${digest}" <"${HALCYON_CACHE_DIR}/${config}"
		then
			rm -f "${HALCYON_CACHE_DIR}/${config}" || die

			if ! download_prebuilt "${os}" "${config}" "${HALCYON_CACHE_DIR}"; then
				log_warning "Downloading ${config} failed"
			fi

			if ! validate_sandbox_config "${digest}" <"${HALCYON_CACHE_DIR}/${config}"; then
				rm -f "${HALCYON_CACHE_DIR}/${config}" || die
				log_warning "Restoring ${config} failed"
			fi
		fi
	done <<<"${matched_configs}"

	log 'Scoring matched sandboxes'

	local matched_scores
	if ! matched_scores=$(
		local config
		while read -r config; do
			if ! [ -f "${HALCYON_CACHE_DIR}/${config}" ]; then
				continue
			fi

			local app_label digest tag
			app_label=$( echo_sandbox_config_app_label "${config}" ) || die
			digest=$( echo_sandbox_config_digest "${config}" ) || die
			tag=$( echo_sandbox_tag "${ghc_version}" "${app_label}" "${digest}" ) || die

			local score
			if ! score=$(
				read_constraints <"${HALCYON_CACHE_DIR}/${config}" |
				sort_naturally |
				filter_valid_constraints |
				score_constraints "${sandbox_constraints}" "${tag}"
			); then
				continue
			fi

			echo -e "${score} ${tag}"
		done <<<"${matched_configs}" |
			filter_not_matching '^0 ' |
			sort_naturally |
			match_at_least_one
	); then
		log_warning 'No sandbox is matched closely enough'
		return 1
	fi

	filter_last <<<"${matched_scores}" |
		match_exactly_one |
		sed 's/^.* //'
}




function activate_sandbox () {
	expect_vars HALCYON_DIR
	expect_existing "${HALCYON_DIR}/sandbox/tag"

	local app_dir
	expect_args app_dir -- "$@"
	expect_existing "${app_dir}"

	local sandbox_tag sandbox_description
	sandbox_tag=$( <"${HALCYON_DIR}/sandbox/tag" ) || die
	sandbox_description=$( echo_sandbox_description "${sandbox_tag}" ) || die

	log_begin "Activating ${sandbox_description}..."

	if [ -e "${app_dir}/cabal.sandbox.config" ] && ! [ -h "${app_dir}/cabal.sandbox.config" ]; then
		die "Expected no actual ${app_dir}/cabal.sandbox.config"
	fi

	rm -f "${app_dir}/cabal.sandbox.config" || die
	ln -s "${HALCYON_DIR}/sandbox/cabal.sandbox.config" "${app_dir}/cabal.sandbox.config" || die

	log_end 'done'
}


function deactivate_sandbox () {
	expect_vars HALCYON_DIR
	expect_existing "${HALCYON_DIR}/sandbox/tag"

	local app_dir
	expect_args app_dir -- "$@"
	expect_existing "${app_dir}"

	local sandbox_tag sandbox_description
	sandbox_tag=$( <"${HALCYON_DIR}/sandbox/tag" ) || die
	sandbox_description=$( echo_sandbox_description "${sandbox_tag}" ) || die

	log_begin "Deactivating ${sandbox_description}..."

	if [ -e "${app_dir}/cabal.sandbox.config" ] && ! [ -h "${app_dir}/cabal.sandbox.config" ]; then
		die "Expected no actual ${app_dir}/cabal.sandbox.config"
	fi

	rm -f "${app_dir}/cabal.sandbox.config" || die

	log_end 'done'
}




function install_extended_sandbox () {
	expect_vars HALCYON_DIR

	local app_dir sandbox_constraints sandbox_tag matched_tag
	expect_args app_dir sandbox_constraints sandbox_tag matched_tag -- "$@"

	if ! restore_sandbox "${matched_tag}"; then
		return 1
	fi

	local sandbox_digest sandbox_description
	sandbox_digest=$( echo_sandbox_tag_digest "${sandbox_tag}" ) || die
	sandbox_description=$( echo_sandbox_description "${sandbox_tag}" ) || die

	local matched_digest matched_description
	matched_digest=$( echo_sandbox_tag_digest "${matched_tag}" ) || die
	matched_description=$( echo_sandbox_description "${matched_tag}" ) || die

	if [ "${matched_digest}" = "${sandbox_digest}" ]; then
		log "Using matched ${matched_description} as ${sandbox_description}"

		echo "${sandbox_tag}" >"${HALCYON_DIR}/sandbox/tag" || die
		archive_sandbox || die
		activate_sandbox "${app_dir}" || die
		return 0
	fi

	log "Extending matched ${matched_description} to ${sandbox_description}"

	rm -f "${HALCYON_DIR}/sandbox/tag" "${HALCYON_DIR}/sandbox/cabal.config" || die

	build_sandbox "${app_dir}" "${sandbox_constraints}" "${sandbox_tag}" || die
	strip_sandbox || die
	archive_sandbox || die
	activate_sandbox "${app_dir}" || die
}


function install_sandbox () {
	expect_vars HALCYON_DIR HALCYON_NO_PREBUILT HALCYON_NO_PREBUILT_SANDBOX HALCYON_PREBUILT_ONLY
	expect_existing "${HALCYON_DIR}/ghc/tag"

	local app_dir
	expect_args app_dir -- "$@"

	local ghc_tag
	ghc_tag=$( <"${HALCYON_DIR}/ghc/tag" ) || die
	ghc_version=$( echo_ghc_tag_version "${ghc_tag}" ) || die

	local sandbox_constraints sandbox_digest
	sandbox_constraints=$( infer_sandbox_constraints "${app_dir}" ) || die
	sandbox_digest=$( infer_sandbox_digest "${sandbox_constraints}" ) || die

	local app_label sandbox_tag
	app_label=$( detect_app_label "${app_dir}" ) || die
	sandbox_tag=$( echo_sandbox_tag "${ghc_version}" "${app_label}" "${sandbox_digest}" ) || die

	if ! (( ${HALCYON_NO_PREBUILT} )) &&
		! (( ${HALCYON_NO_PREBUILT_SANDBOX} )) &&
		restore_sandbox "${sandbox_tag}"
	then
		activate_sandbox "${app_dir}" || die
		return 0
	fi

	! (( ${HALCYON_PREBUILT_ONLY} )) || return 1

	local matched_tag
	if ! (( ${HALCYON_NO_PREBUILT} )) &&
		! (( ${HALCYON_NO_PREBUILT_SANDBOX} )) &&
		matched_tag=$( locate_matched_sandbox_tag "${sandbox_constraints}" ) &&
		install_extended_sandbox "${app_dir}" "${sandbox_constraints}" "${sandbox_tag}" "${matched_tag}"
	then
		return 0
	fi

	build_sandbox "${app_dir}" "${sandbox_constraints}" "${sandbox_tag}" || die
	strip_sandbox || die
	archive_sandbox || die
	activate_sandbox "${app_dir}" || die
}




# NOTE: To install just the executables of executable-only packages in
# the sandbox prior to building the sandbox, without polluting the sandbox
# with extraneous dependencies, you can use a separate sub-sandbox:
#
# function customize_sandbox () {
# 	customize_sandbox_with_cabal_package_executables alex happy
# }

function customize_sandbox_with_cabal_package_executables () {
	expect_vars HALCYON_DIR
	expect_existing "${HALCYON_DIR}/cabal/tag"
	expect_no_existing "${HALCYON_DIR}/sandbox/customized-sub-sandbox"

	local tmp_dir
	tmp_dir=$( echo_tmp_customize_sandbox_dir ) || die

	mkdir -p "${HALCYON_DIR}/sandbox/bin" "${tmp_dir}" || die

	cabal_create_sandbox "${HALCYON_DIR}/sandbox/customized-sub-sandbox" || die

	silently sandboxed_cabal_do "${HALCYON_DIR}/sandbox/customized-sub-sandbox" "${tmp_dir}" install "$@" || die

	local bin_file bin_name
	for bin_file in "${HALCYON_DIR}/sandbox/customized-sub-sandbox/bin"/*; do
		bin_name=$( basename "${bin_file}" ) || die
		ln -s "${bin_file}" "${HALCYON_DIR}/sandbox/bin/${bin_name}" || die
	done

	rm -rf "${tmp_dir}" || die
}
