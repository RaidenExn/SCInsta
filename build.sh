#!/usr/bin/env bash

set -e

# --- Configuration & Colors ---
C_BOLD='\033[1m'
C_GREEN='\033[0;32m'
C_YELLOW='\033[0;33m'
C_RED='\033[0;31m'
C_BLUE='\033[0;34m'
C_RESET='\033[0m'

export CMAKE_OSX_ARCHITECTURES="arm64e;arm64"
export CMAKE_OSX_SYSROOT="iphoneos"


# --- Functions ---

show_usage() {
    echo -e "${C_BOLD}+--------------------+${C_RESET}"
    echo -e "${C_BOLD}|SCInsta Build Script|${C_RESET}"
    echo -e "${C_BOLD}+--------------------+${C_RESET}"
    echo
    echo -e "Usage: ./build.sh ${C_GREEN}<sideload|rootless|rootful>${C_RESET}"
}

clean_artifacts() {
    echo -e "${C_YELLOW}Cleaning previous build artifacts...${C_RESET}"
    make clean > /dev/null 2>&1
    rm -rf .theos
}

check_submodules() {
    if [ -z "$(ls -A modules/FLEXing)" ]; then
        echo -e "${C_BOLD}${C_RED}FLEXing submodule not found.${C_RESET}"
        exit 1
    fi
}

# --- Function to remove plugins UNLESS specified to keep ---
handle_plugins() {
    local original_ipa="packages/instagram.ipa"
    local temp_dir="packages/temp_unzip"
    
    echo -e "${C_BLUE}Processing IPA plugins (removing all by default)...${C_RESET}" >&2
    
    unzip -q "$original_ipa" -d "$temp_dir"
    
    local app_path="$temp_dir/Payload/Instagram.app"
    
    # Inverted logic: Remove if the KEEP variable is NOT true
    if [ "${KEEP_SHARE}" != "true" ]; then
        echo "  - Removing Share Extension" >&2
        rm -rf "${app_path}/Plugins/InstagramShareExtension.appex"
    else
        echo "  - ✅ Keeping Share Extension" >&2
    fi

    if [ "${KEEP_WIDGET}" != "true" ]; then
        echo "  - Removing Widget Extension" >&2
        rm -rf "${app_path}/Plugins/InstagramWidgetExtension.appex"
    else
        echo "  - ✅ Keeping Widget Extension" >&2
    fi

    if [ "${KEEP_NOTIFICATION}" != "true" ]; then
        echo "  - Removing Notification Extensions" >&2
        rm -rf "${app_path}/Plugins/InstagramNotificationContentExtension.appex"
        rm -rf "${app_path}/Plugins/InstagramNotificationExtension.appex"
    else
        echo "  - ✅ Keeping Notification Extensions" >&2
    fi

    if [ "${KEEP_LIVEACTIVITIES}" != "true" ]; then
        echo "  - Removing Live Activities Extension" >&2
        rm -rf "${app_path}/Plugins/InstagramWidgetExtensionLiveActivities.appex"
    else
        echo "  - ✅ Keeping Live Activities Extension" >&2
    fi

    if [ "${KEEP_BROADCAST}" != "true" ]; then
        echo "  - Removing Broadcast Extension" >&2
        rm -rf "${app_path}/Plugins/InstagramBroadcastSampleHandlerExtension.appex"
    else
        echo "  - ✅ Keeping Broadcast Extension" >&2
    fi

    if [ "${KEEP_LOCKSCREEN_WIDGET}" != "true" ]; then
        echo "  - Removing Lock Screen Widget" >&2
        rm -rf "${app_path}/Plugins/InstagramWidgetExtensionLockScreenCameraControl.appex"
    else
        echo "  - ✅ Keeping Lock Screen Widget" >&2
    fi
    
    # Note: This extension is in a different folder
    if [ "${KEEP_LOCKSCREEN_CAMERA}" != "true" ]; then
        echo "  - Removing Lock Screen Camera Extension" >&2
        rm -rf "${app_path}/Extensions/InstagramExtensionLockScreenCamera.appex"
    else
        echo "  - ✅ Keeping Lock Screen Camera Extension" >&2
    fi
    
    echo -e "${C_BLUE}Re-packaging cleaned IPA...${C_RESET}" >&2
    
    (cd "$temp_dir" && zip -qr "../instagram-cleaned.ipa" .)
    
    rm -rf "$temp_dir"
    
    echo "packages/instagram-cleaned.ipa"
}


# --- Main Build Logic ---

check_submodules

if [ -z "$1" ]; then
    show_usage
    exit 1
fi

case "$1" in
    sideload)
        clean_artifacts
        
        if [ ! -f "packages/instagram.ipa" ]; then
            echo -e "${C_BOLD}${C_RED}packages/instagram.ipa not found.${C_RESET}" >&2
            exit 1
        fi
        
        ipaFile=$(handle_plugins)
        
        echo -e "${C_BOLD}${C_GREEN}Building SCInsta for sideloading...${C_RESET}" >&2
        
        MAKEARGS='SIDELOAD=1'
        FLEXPATH='.theos/obj/debug/FLEXing.dylib .theos/obj/debug/libflex.dylib'
        COMPRESSION=9

        make $MAKEARGS

        echo -e "${C_GREEN}Creating the final IPA file...${C_RESET}" >&2
        rm -f packages/SCInsta-sideloaded.ipa
        
        cyan -i "${ipaFile}" \
             -o packages/SCInsta-sideloaded.ipa \
             -n "${APP_NAME:-Instagram}" \
             -b "${BUNDLE_ID:-com.burbn.instagram}" \
             -f .theos/obj/debug/SCInsta.dylib .theos/obj/debug/sideloadfix.dylib $FLEXPATH \
             -c $COMPRESSION -m 15.0 -du
        ;;

    rootless)
        clean_artifacts
        echo -e "${C_BOLD}${C_GREEN}Building SCInsta for rootless...${C_RESET}" >&2
        export THEOS_PACKAGE_SCHEME=rootless
        make package
        ;;

    rootful)
        clean_artifacts
        echo -e "${C_BOLD}${C_GREEN}Building SCInsta for rootful...${C_RESET}" >&2
        unset THEOS_PACKAGE_SCHEME
        make package
        ;;

    *)
        echo -e "${C_RED}Error: Unknown build mode '$1'${C_RESET}\n" >&2
        show_usage
        exit 1
        ;;
esac

echo -e "\n${C_BOLD}${C_GREEN}Build finished successfully!${C_RESET}" >&2
