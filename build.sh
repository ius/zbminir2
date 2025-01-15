#!/usr/bin/env bash
SDK=$SIMPLICITY_SDK
TARGET=EFR32MG21A020F768IM32
OBJCOPY=arm-none-eabi-objcopy

# Shenzhen CoolKit Technology Co., Ltd
ZIGBEE_MANUF_ID=0x1286

set -e

trust_sdk()
{
	trust_file=~/SimplicityStudio/uc_workspace/.metadata/.trust/primary_trusted.trust
	grep -qF "$SDK" "$trust_file" 2>/dev/null || slc-cli signature trust --sdk "$SDK"
}

gen_build_config()
{
	slcp="$1"
	prj=$(basename -s .slcp "$slcp")
	target="$2"
	out_type="${3:-cmake}"

	[ -d "build/${prj}" ] && return 0

	slc-cli generate \
		--sdk "$SDK" \
		--export-destination build/$prj \
		--with "$target" \
		--output-type "$out_type" \
		--project-file "$slcp"
}

build()
{
	prj="$1"
	build_dir="build/${prj}"
	cmake_dir="build/${prj}/${prj}_cmake/"

	#[ -f "build/${prj}.bin" ] && return 0

	cmake --preset project -S "$cmake_dir" -B "$build_dir" -DCMAKE_EXPORT_COMPILE_COMMANDS=ON
	ninja -C "$build_dir"

	cp -a "${build_dir}/default_config/${prj}."{bin,s37} build/
}

build_gw()
{
	prj="$1"
	prj_lower="$(echo -n "$1" | tr A-Z a-z)"
	build_dir="build/${prj}"

	#[ -f "build/${prj_lower}.elf" ] && return 0

	make -C "${build_dir}" -f ${prj}.Makefile -j16
	cp -af "${build_dir}/build/debug/${prj}" "build/${prj_lower}.elf"
}

flash()
{
	bin="$1"
	offset="$2"

	openocd -f openocd/openocd_jlink.cfg \
		-c "program ${bin} ${offset}; reset; exit"
}

create_ota()
{
	bl="$1"
	app_name=$(basename -s .s37 "$2")
	ver="$3"

	basename="${app_name}_${ZIGBEE_MANUF_ID}_${ver}"

	commander-cli convert "$bl" build/${app_name}.s37 --outfile "build/${app_name}_full.s37"

	${OBJCOPY} -I srec -O binary --gap=0xff "build/${app_name}_full.s37" "build/${app_name}_full.bin"

	commander-cli gbl create \
		"build/${app_name}.gbl" \
		--app "build/${app_name}_full.s37" \
		--compress lzma

	commander-cli ota create \
		--upgrade-image "build/${app_name}.gbl" \
		--firmware-version "$ver" \
		--manufacturer-id "${ZIGBEE_MANUF_ID}" \
		--image-type 0 \
		--string "${basename}" \
		--outfile "build/${basename}.ota"
}

trust_sdk

# gateway
gen_build_config "${SDK}/protocol/zigbee/app/projects/z3/zigbee_z3_gateway/zigbee_z3_gateway.slcp" linux_arch_32 makefile
build_gw zigbee_z3_gateway

# bootloader
gen_build_config src/bootloader/bootloader-storage-internal-single-768k.slcp $TARGET
build bootloader-storage-internal-single-768k

# main firmware
gen_build_config src/zbminir2/zbminir2.slcp $TARGET

# for development - avoids having to call slc generate after making changes
cp src/zbminir2/*.c build/zbminir2/
build zbminir2

create_ota build/bootloader-storage-internal-single-768k.s37 build/zbminir2.s37 2

if [ "$1" = "flash" ]; then
	flash ./build/bootloader-storage-internal-single-768k.bin 0
	flash ./build/zbminir2.bin 0x4000
fi
