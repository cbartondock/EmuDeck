#!/bin/bash
#https://dl.google.com/android/repository/platform-tools-latest-linux.zip
#https://dl.google.com/android/repository/platform-tools-latest-darwin.zip
#https://dl.google.com/android/repository/platform-tools-latest-windows.zip

Android_ADB_path="$HOME/emudeck/android/platform-tools"
Android_ADB_url="https://dl.google.com/android/repository/platform-tools-latest-darwin.zip"

function Android_ADB_isInstalled(){
	if [ -e "$Android_ADB_path" ]; then
		echo "true"
		return 0
	else
		echo "false"
		return 1
	fi
}

function Android_ADB_install(){

	local outFile="adb.zip"
	local outDir="$HOME/emudeck/android/"

	Android_download "$outFile" "$Android_ADB_url" && unzip -o "$outFile" -d $outDir && rm -rf $outFile && echo "true" && return 0

}

function Android_download(){
	local outDir="$HOME/emudeck/android/"
	local outFile="$HOME/emudeck/android/$1"
	local url=$2
	mkdir -p $outDir

	request=$(curl -w $'\1'"%{response_code}" --fail -L "$url" -o "${outFile}.temp" 2>&1 && echo $'\2'0 || echo $'\2'$?)

	returnCodes="${request#*$'\1'}"
	httpCode="${returnCodes%$'\2'*}"
	exitCode="${returnCodes#*$'\2'}"

	if [ "$httpCode" = "200" ]; then
		mv -v "$outFile.temp" "$outFile"
		return 0
	else
		echo "false"
		return 1
	fi

}

function Android_ADB_connected(){
	local output=$(adb devices)
	local device_count=$(echo "$output" | grep -E "device\b" | wc -l)

	if [ "$device_count" -gt 0 ]; then
		echo "true"
		return 0
	else
		echo "false"
		return 1
	fi
}

function Android_ADB_push(){
	export PATH=$PATH:$Android_ADB_path
	echo "NYI"
}

Android_ADB_installAPK(){
	local apk=$1
	export PATH=$PATH:$Android_ADB_path
	adb install $apk && rm -rf $apk
}

Android_ADB_dl_installAPK(){
	local temp_emu=$1
	local temp_url=$2
	Android_download "$temp_emu.apk" $temp_url
	Android_ADB_installAPK "$HOME/emudeck/android/$temp_emu.apk"
}