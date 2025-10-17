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

# --- NEW: Function to remove selected plugins from the IPA ---
handle_plugins() {
    local original_ipa="packages/instagram.ipa"
    local temp_dir="packages/temp_unzip"
    
    echo -e "${C_BLUE}Processing IPA plugins...${C_RESET}"
    
    # Unzip the IPA quietly
    unzip -q "$original_ipa" -d "$temp_dir"
    
    local app_path="$temp_dir/Payload/Instagram.app"
    
    # Conditionally remove plugins based on environment variables
    if [ "${REMOVE_SHARE}" == "true" ]; then
        echo "  - Removing Share Extension"
        rm -rf "${app_path}/Plugins/InstagramShareExtension.appex"
    fi
    if [ "${REMOVE_WIDGET}" == "true" ]; then
        echo "  - Removing Widget Extension"
        rm -rf "${app_path}/Plugins/InstagramWidgetExtension.appex"
    fi
    if [ "${REMOVE_NOTIFICATION}" == "true" ]; then
        echo "  - Removing Notification Extensions"
        rm -rf "${app_path}/Plugins/InstagramNotificationContentExtension.appex"
        rm -rf "${app_path}/Plugins/InstagramNotificationExtension.appex"
    fi
    if [ "${REMOVE_LIVEACTIVITIES}" == "true" ]; then
        echo "  - Removing Live Activities Extension"
        rm -rf "${app_path}/Plugins/InstagramWidgetExtensionLiveActivities.appex"
    fi
    
    echo -e "${C_BLUE}Re-packaging cleaned IPA...${C_RESET}"
    
    # Zip the contents back into a new IPA
    (cd "$temp_dir" && zip -qr "../instagram-cleaned.ipa" .)
    
    # Clean up the temporary directory
    rm -rf "$temp_dir"
    
    # Return the name of the new IPA file to be used by cyan
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
        
        # Check for original IPA
        if [ ! -f "packages/instagram.ipa" ]; then
            echo -e "${C_BOLD}${C_RED}packages/instagram.ipa not found.${C_RESET}"
            exit 1
        fi
        
        # --- MODIFIED: Call the plugin handler ---
        # It will return the path to the (potentially modified) IPA
        ipaFile=$(handle_plugins)
        
        echo -e "${C_BOLD}${C_GREEN}Building SCInsta for sideloading...${C_RESET}"
        
        MAKEARGS='SIDELOAD=1'
        FLEXPATH='.theos/obj/debug/FLEXing.dylib .theos/obj/debug/libflex.dylib'
        COMPRESSION=9

        make $MAKEARGS

        echo -e "${C_GREEN}Creating the final IPA file...${C_RESET}"
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
        echo -e "${C_BOLD}${C_GREEN}Building SCInsta for rootless...${C_RESET}"
        export THEOS_PACKAGE_SCHEME=rootless
        make package
        ;;

    rootful)
        clean_artifacts
        echo -e "${C_BOLD}${C_GREEN}Building SCInsta for rootful...${C_RESET}"
        unset THEOS_PACKAGE_SCHEME
        make package
        ;;

    *)
        echo -e "${C_RED}Error: Unknown build mode '$1'${C_RESET}\n"
        show_usage
        exit 1
        ;;
esac

echo -e "\n${C_BOLD}${C_GREEN}Build finished successfully!${C_RESET}"
