# Copyright 2023-2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit git-r3

DESCRIPTION="Apple T2 DSP configs"
HOMEPAGE="https://t2linux.org/"
EGIT_REPO_URI="https://github.com/pierolenzo/t2-apple-audio-dsp.git"

LICENSE="MIT"
SLOT="0"
KEYWORDS=""

RDEPEND="
	media-plugins/swh-plugins
	media-plugins/swh-lv2
	media-video/pipewire[extra,lv2,sound-server]
	media-video/wireplumber
	media-libs/lsp-plugins[lv2]
	media-libs/bankstown-lv2
	media-libs/triforce-lv2
"

src_install() {
	# Detect current Mac model
	local model=$(cat /sys/class/dmi/id/product_name 2>/dev/null)
	local model_dir=""

	if [[ -n "${model}" ]]; then
		# Remove all letters, keeping only numbers and the comma (e.g. MacBookPro16,2 -> 16,2)
		local stripped=${model//[a-zA-Z]/}
		if [[ ${stripped} == *,* ]]; then
			model_dir=${stripped/,/_}
		fi
	fi

	if [[ -n "${model_dir}" && -d "config/${model_dir}" ]]; then
		einfo "Installing DSP config for detected model: ${model} (${model_dir})"

		# Install WirePlumber DSP config
		insinto /etc/wireplumber/wireplumber.conf.d
		local f
		for f in "config/${model_dir}"/*-dsp.conf; do
			[[ -e ${f} ]] && doins "${f}"
		done

		# Install FIR files, DSP graph JSONs, and Lua scripts
		insinto "/usr/share/t2-linux-audio/${model_dir}"
		local files=()
		for f in "firs/${model_dir}"/*; do
			[[ -f ${f} ]] && files+=("${f}")
		done
		if [[ ${#files[@]} -gt 0 ]]; then
			doins "${files[@]}"
		fi

		# Create symlinks so WirePlumber can find Lua scripts
		dodir /usr/share/wireplumber/scripts/device
		for f in "firs/${model_dir}"/*.lua; do
			[[ -e ${f} ]] || continue
			local lua_basename=$(basename "${f}")
			dosym -r "/usr/share/t2-linux-audio/${model_dir}/${lua_basename}" "/usr/share/wireplumber/scripts/device/${lua_basename}"
		done
	else
		ewarn "Model '${model}' not detected or DSP config not found!"
		ewarn "Installing all configs to /usr/share/t2-apple-audio-dsp for manual setup."
		insinto /usr/share/t2-apple-audio-dsp
		doins -r config firs
		exeinto /usr/share/t2-apple-audio-dsp
		doexe install.sh uninstall.sh
	fi
}

pkg_postinst() {
	einfo "If the DSP config was installed, restart the user services to apply it:"
	einfo "  systemctl --user restart wireplumber pipewire pipewire-pulse"
}

