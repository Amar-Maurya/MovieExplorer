#!/bin/bash

##################################################################################
# Custom build tool for Realm Objective-C binding.
#
# (C) Copyright 2011-2022 by realm.io.
##################################################################################

set -eo pipefail

readonly source_root="$(dirname "$0")"

: "${REALM_CORE_VERSION:=$(sed -n 's/^REALM_CORE_VERSION=\(.*\)$/\1/p' "${source_root}/dependencies.list")}" # set to "current" to always use the current build

# Provide a fallback value for TMPDIR, relevant for Xcode Bots
: "${TMPDIR:=$(getconf DARWIN_USER_TEMP_DIR)}"

PATH=/usr/libexec:$PATH

if [ -n "${CI}" ]; then
    CODESIGN_PARAMS=(CODE_SIGN_IDENTITY='' CODE_SIGNING_REQUIRED=NO CODE_SIGNING_ALLOWED=NO)
fi

if [ -n "${GITHUB_WORKSPACE}" ]; then
    DERIVED_DATA="$GITHUB_WORKSPACE/build/DerivedData"
    ROOT_WORKSPACE="$GITHUB_WORKSPACE"
    BRANCH="${GITHUB_HEAD_REF:-${GITHUB_REF}}"
else
    ROOT_WORKSPACE="$(pwd)"
    DERIVED_DATA="$ROOT_WORKSPACE/build/DerivedData"
    BRANCH="$(git branch --show-current)"
fi

usage() {
cat <<EOF
Usage: sh $0 command [argument]

command:
  clean:                clean up/remove all generated files
  download-core:        downloads core library (binary version)
  build [platforms]:    builds xcframeworks for Realm and RealmSwift for given platforms (default all)
  build-static [plats]: builds static xcframework for Realm platforms (default all)
  analyze-osx:          analyzes macOS framework

  test:                 tests all iOS and macOS frameworks
  test-all:             tests all iOS and macOS frameworks in both Debug and Release configurations
  test-ios-static:      tests static iOS framework on 32-bit and 64-bit simulators
  test-ios-dynamic:     tests dynamic iOS framework on 32-bit and 64-bit simulators
  test-ios-swift:       tests RealmSwift iOS framework on 32-bit and 64-bit simulators
  test-ios-devices:     tests ObjC & Swift iOS frameworks on all attached iOS devices
  test-ios-devices-objc:  tests ObjC iOS framework on all attached iOS devices
  test-ios-devices-swift: tests Swift iOS framework on all attached iOS devices
  test-tvos:            tests tvOS framework
  test-tvos-swift:      tests RealmSwift tvOS framework
  test-tvos-devices:    tests ObjC & Swift tvOS frameworks on all attached tvOS devices
  test-osx:             tests macOS framework
  test-osx-swift:       tests RealmSwift macOS framework
  test-catalyst:        tests Mac Catalyst framework
  test-catalyst-swift:  tests RealmSwift Mac Catalyst framework
  test-swiftpm:         tests ObjC and Swift macOS frameworks via SwiftPM
  test-ios-swiftui:        tests SwiftUI framework UI tests
  verify:               verifies docs, cocoapods, swiftpm, xcframework, swiftlint, spm-ios, watchos in both Debug and Release configurations

  docs:                 builds docs in docs/output
  examples:             builds all examples
  examples-ios:         builds all objc iOS examples
  examples-ios-swift:   builds all Swift iOS examples
  examples-osx:         builds all macOS examples
  examples-tvos:        builds all objc tvOS examples
  examples-tvos-swift:  builds all Swift tvOS examples

  get-version:          get the current version
  set-version version:  set the version
  set-core-version version: set the version of core to use

  release-package-examples:       build release package the examples
  release-package-docs:           build release package the docs
  release-package-*:              build release package for the given platform, configuration and target (this is executed in XCode Cloud)
  release-create-xcframework_[xcode-version] [platform]:  creates an xcframework from the framework build by the previous step
  release-package:                creates the final packages
  release-package-test-examples:  test a built examples release package

  test-package-release: locally build a complete release package for all platforms

  publish-github:       create a Github release for the currently checked-out tag
  publish-docs:         publish a built docs release to the website
  publish-cocoapods [tag]: publish the requested tag to CocoaPods
  prepare-publish-changelog: creates a changelog file to be used in Slack

argument:
  version: version in the x.y.z format
  platform: exactly one of "osx ios watchos tvos visionos"
  platforms: one or more of "osx ios watchos tvos visionos"

environment variables:
  XCMODE: xcodebuild (default), xctool
  CONFIGURATION: Debug, Release (default), or Static
  LINKAGE: Static
  REALM_CORE_VERSION: version in x.y.z format or "current" to use local build
  REALM_EXTRA_BUILD_ARGUMENTS: additional arguments to pass to the build tool
  REALM_XCODE_VERSION: the version number of Xcode to use (e.g.: 13.3.1)
  REALM_XCODE_OLDEST_VERSION: the version number of oldest available Xcode to use (e.g.: 12.4)
  REALM_XCODE_LATEST_VERSION: the version number of latest available Xcode to use (e.g.: 13.3.1)
EOF
}

######################################
# Xcode Helpers
######################################

xcode_version_major() {
    echo "${REALM_XCODE_VERSION%%.*}"
}

xcode() {
    mkdir -p build/DerivedData
    CMD="xcodebuild -IDECustomDerivedDataLocation=build/DerivedData"
    echo "Building with command: $CMD $*"
    xcodebuild -IDECustomDerivedDataLocation=build/DerivedData "$@"
}

xc() {
    # Logs xcodebuild output in realtime
    : "${NSUnbufferedIO:=YES}"
    xcode "$@" ${REALM_EXTRA_BUILD_ARGUMENTS[@]}
}

xctest() {
    local scheme="$1"
    xc -scheme "$scheme" "${@:2}" build-for-testing
    xc -scheme "$scheme" "${@:2}" test-without-building
}

build_combined() {
    local product="$1"
    local platform="$2"
    local config="$CONFIGURATION"

    local config_suffix simulator_suffix destination build_args
    case "$platform" in
        osx)
            destination='generic/platform=macOS'
            config_suffix=
            ;;
        ios)
            destination='generic/platform=iOS'
            config_suffix=-iphoneos
            simulator_suffix=iphonesimulator
            ;;
        watchos)
            destination='generic/platform=watchOS'
            config_suffix=-watchos
            simulator_suffix=watchsimulator
            ;;
        tvos)
            destination='generic/platform=tvOS'
            config_suffix=-appletvos
            simulator_suffix=appletvsimulator
            ;;
        visionos)
            destination='generic/platform=visionOS'
            config_suffix=-xros
            simulator_suffix=xrsimulator
            ;;
        catalyst)
            destination='generic/platform=macOS,variant=Mac Catalyst'
            config_suffix=-maccatalyst
            ;;
    esac

    build_args=(-scheme "$product" -configuration "$config" build REALM_HIDE_SYMBOLS=YES)

    # Derive build paths
    local build_products_path="$DERIVED_DATA/Realm/Build/Products"
    local product_name="$product.framework"
    local os_path="$build_products_path/$config${config_suffix}/$product_name"
    local simulator_path="$build_products_path/$config-$simulator_suffix/$product_name"
    local out_path="build/$config/$platform"
    local xcframework_path="$out_path/$product.xcframework"

    # Build for each platform
    xc -destination "$destination" "${build_args[@]}"
    simulator_framework=()
    if [[ -n "$simulator_suffix" ]]; then
        xc -destination "$destination Simulator" "${build_args[@]}"
        simulator_framework+=(-framework "$simulator_path")
    fi

    # Create the xcframework
    rm -rf "$xcframework_path"
    xcodebuild -create-xcframework -allow-internal-distribution -output "$xcframework_path" \
        -framework "$os_path" "${simulator_framework[@]}"
}

create_xcframework() {
    local product="$1"
    local config="$2"

    local out_path="$ROOT_WORKSPACE/$config/$product.xcframework"
    find "$ROOT_WORKSPACE"/build-*/"$config" -name "$product.framework" \
        | sed 's/.*/-framework &/' \
        | xargs xcodebuild -create-xcframework -allow-internal-distribution -output "$out_path"
    codesign --timestamp -s "$SIGNING_IDENTITY" "$out_path"
}

# Artifacts are zipped by the artifacts store so they're endup nested zipped, so we need to unzip this zip.
unzip_artifact() {
    initial_path="$1"
    file_name=${initial_path%.*}

    unzip "$file_name.zip" -d "$file_name"
    rm "$file_name.zip"

    mv "$file_name/$file_name.zip" "$file_name.zip"
    rm -rf "$file_name"
}

clean_retrieve() {
    mkdir -p "$2"
    rm -rf "$2/$3"
    cp -R "$1" "$2"
}

plist_get() {
    /usr/libexec/PlistBuddy -c "Print :$2" "$1" 2> /dev/null
}

iphone_name() {
    if (( $(xcode_version_major) < 16 )); then
        echo 'iPhone 15'
    else
        echo 'iPhone 16'
    fi
}

######################################
# Device Test Helper
######################################

test_devices() {
    local serial_numbers=()
    local awk_script="
    /^ +Vendor ID: / { is_apple = 0; }
    /^ +Vendor ID: 0x05[aA][cC] / { is_apple = 1; }
    /^ +Serial Number: / {
        if (is_apple) {
            match(\$0, /^ +Serial Number: /);
            print substr(\$0, RLENGTH + 1);
        }
    }
    "
    local serial_numbers_text=$(/usr/sbin/system_profiler SPUSBDataType | /usr/bin/awk "$awk_script")
    while read -r number; do
        if [[ "$number" != "" ]]; then
            serial_numbers+=("$number")
        fi
    done <<< "$serial_numbers_text"
    if [[ ${#serial_numbers[@]} == 0 ]]; then
        echo "At least one iOS/tvOS device must be connected to this computer to run device tests"
        if [ -z "${JENKINS_HOME}" ]; then
            # Don't fail if running locally and there's no device
            exit 0
        fi
        exit 1
    fi
    local sdk="$1"
    local scheme="$2"
    local configuration="$3"
    local failed=0
    for device in "${serial_numbers[@]}"; do
        xc -scheme "$scheme" -configuration "$configuration" -destination "id=$device" -sdk "$sdk" test || failed=1
    done
    return $failed
}

######################################
# Docs
######################################

build_docs() {
    local language="$1"
    local version=$(sh build.sh get-version)

    local xcodebuild_arguments="--objc,Realm/Realm.h,--,-x,objective-c,-isysroot,$(xcrun --show-sdk-path),-I,$(pwd)"
    local module="Realm"
    local objc="--objc"

    if [[ "$language" == "swift" ]]; then
        xcodebuild_arguments="-scheme,RealmSwift"
        module="RealmSwift"
        objc=""
    fi

    jazzy \
      "${objc}" \
      --clean \
      --author Realm \
      --author_url https://docs.mongodb.com/realm-sdks \
      --github_url https://github.com/realm/realm-swift \
      --github-file-prefix "https://github.com/realm/realm-swift/tree/v${version}" \
      --module-version "${version}" \
      --xcodebuild-arguments "${xcodebuild_arguments}" \
      --module "${module}" \
      --root-url "https://docs.mongodb.com/realm-sdks/${language}/${version}/" \
      --output "docs/${language}_output" \
      --head "$(cat docs/custom_head.html)" \
      --exclude 'RealmSwift/Impl/*'
}

######################################
# Input Validation
######################################

if [ "$#" -eq 0 ] || [ "$#" -gt 3 ]; then
    usage
    exit 1
fi

######################################
# Variables
######################################

COMMAND="$1"
LINKAGE="dynamic"

# Use Debug config if command ends with -debug, otherwise default to Release
case "$COMMAND" in
    *-debug)
        COMMAND="${COMMAND%-debug}"
        CONFIGURATION="Debug"
        ;;
    *-static)
        COMMAND="${COMMAND%-static}"
        LINKAGE="static"
        CONFIGURATION="Static"
        ;;
esac
export CONFIGURATION=${CONFIGURATION:-Release}

# Pre-choose Xcode version for those operations that do not override it
REALM_XCODE_VERSION=${xcode_version:-$REALM_XCODE_VERSION}
source "${source_root}/scripts/swift-version.sh"
set_xcode_version

######################################
# Commands
######################################

case "$COMMAND" in

    ######################################
    # Clean
    ######################################
    "clean")
        find . -type d -name build -exec rm -r "{}" +
        exit 0
        ;;

    ######################################
    # Dependencies
    ######################################
    "download-core")
        sh scripts/download-core.sh
        exit 0
        ;;

    ######################################
    # Building
    ######################################
    "build")
        sh build.sh xcframework
        exit 0
        ;;

    "ios")
        build_combined Realm ios
        exit 0
        ;;

    "ios-swift")
        build_combined Realm ios
        build_combined RealmSwift ios
        exit 0
        ;;

    "watchos")
        build_combined Realm watchos
        exit 0
        ;;

    "watchos-swift")
        build_combined Realm watchos
        build_combined RealmSwift watchos
        exit 0
        ;;

    "tvos")
        build_combined Realm tvos
        exit 0
        ;;

    "tvos-swift")
        build_combined Realm tvos
        build_combined RealmSwift tvos
        exit 0
        ;;

    "osx")
        build_combined Realm osx
        exit 0
        ;;

    "osx-swift")
        build_combined Realm osx
        build_combined RealmSwift osx
        exit 0
        ;;

    "catalyst")
        build_combined Realm catalyst
        ;;

    "catalyst-swift")
        build_combined Realm catalyst
        build_combined RealmSwift catalyst
        ;;

    "visionos")
        build_combined Realm visionos
        ;;

    "visionos-swift")
        build_combined Realm visionos
        build_combined RealmSwift visionos
        ;;

    "xcframework")
        # Build all of the requested frameworks
        shift
        PLATFORMS="${*:-osx ios watchos tvos catalyst visionos}"
        for platform in $PLATFORMS; do
            sh build.sh "$platform-swift"
        done

        # Assemble them into xcframeworks
        rm -rf "$DERIVED_DATA/Realm/Build/Products"*.xcframework
        find "$DERIVED_DATA/Realm/Build/Products" -name 'Realm.framework' \
            | sed 's/.*/-framework &/' \
            | xargs xcodebuild -create-xcframework -allow-internal-distribution -output "build/$CONFIGURATION/Realm.xcframework"
        find "$DERIVED_DATA/Realm/Build/Products" -name 'RealmSwift.framework' \
            | sed 's/.*/-framework &/' \
            | xargs xcodebuild -create-xcframework -allow-internal-distribution -output "build/$CONFIGURATION/RealmSwift.xcframework"

        # Because we have a module named Realm and a type named Realm we need to manually resolve the naming
        # collisions that are happening. These collisions create a red herring which tells the user the xcframework
        # was compiled with an older Swift version and is not compatible with the current compiler.
        find "build/$CONFIGURATION/RealmSwift.xcframework" -name "*.swiftinterface" \
            -exec sed -i '' 's/Realm\.//g' {} \; \
            -exec sed -i '' 's/import Private/import Realm.Private\nimport Realm.Swift/g' {} \; \
            -exec sed -i '' 's/RealmSwift.Configuration/RealmSwift.Realm.Configuration/g' {} \; \
            -exec sed -i '' 's/extension Configuration/extension Realm.Configuration/g' {} \; \
            -exec sed -i '' 's/RealmSwift.Error[[:>:]]/RealmSwift.Realm.Error/g' {} \; \
            -exec sed -i '' 's/extension Error/extension Realm.Error/g' {} \; \
            -exec sed -i '' 's/RealmSwift.AsyncOpenTask/RealmSwift.Realm.AsyncOpenTask/g' {} \; \
            -exec sed -i '' 's/RealmSwift.UpdatePolicy/RealmSwift.Realm.UpdatePolicy/g' {} \; \
            -exec sed -i '' 's/RealmSwift.Notification[[:>:]]/RealmSwift.Realm.Notification/g' {} \; \
            -exec sed -i '' 's/τ_1_0/V/g' {} \; # Generics will use τ_1_0 which needs to be changed to the correct type name.

        exit 0
        ;;

    ######################################
    # Analysis
    ######################################

    "analyze-osx")
        xc -scheme Realm -configuration "$CONFIGURATION" analyze
        exit 0
        ;;

    ######################################
    # Testing
    ######################################
    "test")
        set +e # Run both sets of tests even if the first fails
        failed=0
        sh build.sh test-ios || failed=1
        sh build.sh test-ios-swift || failed=1
        sh build.sh test-ios-devices || failed=1
        sh build.sh test-tvos-devices || failed=1
        sh build.sh test-osx || failed=1
        sh build.sh test-osx-swift || failed=1
        sh build.sh test-catalyst || failed=1
        sh build.sh test-catalyst-swift || failed=1
        exit $failed
        ;;

    "test-all")
        set +e
        failed=0
        sh build.sh test || failed=1
        sh build.sh test-debug || failed=1
        exit $failed
        ;;

    "test-ios")
        xctest Realm -configuration "$CONFIGURATION" -sdk iphonesimulator -destination "name=$(iphone_name)"
        exit 0
        ;;

    "test-ios-swift")
        xctest RealmSwift -configuration "$CONFIGURATION" -sdk iphonesimulator -destination "name=$(iphone_name)"
        exit 0
        ;;

    "test-ios-devices")
        failed=0
        trap "failed=1" ERR
        sh build.sh test-ios-devices-objc
        sh build.sh test-ios-devices-swift
        exit $failed
        ;;

    "test-ios-devices-objc")
        test_devices iphoneos "Realm" "$CONFIGURATION"
        exit $?
        ;;

    "test-ios-devices-swift")
        test_devices iphoneos "RealmSwift" "$CONFIGURATION"
        exit $?
        ;;

    "test-tvos")
        destination="Apple TV"
        xctest Realm -configuration "$CONFIGURATION" -sdk appletvsimulator -destination "name=$destination"
        exit $?
        ;;

    "test-tvos-swift")
        destination="Apple TV"
        xctest RealmSwift -configuration "$CONFIGURATION" -sdk appletvsimulator -destination "name=$destination"
        exit $?
        ;;

    "test-tvos-devices")
        test_devices appletvos TestHost "$CONFIGURATION"
        ;;

    "test-osx")
        xctest Realm -configuration "$CONFIGURATION" -destination "platform=macOS,arch=$(uname -m)"
        exit 0
        ;;

    "test-osx-swift")
        xctest RealmSwift -configuration "$CONFIGURATION" -destination "platform=macOS,arch=$(uname -m)"
        exit 0
        ;;

    test-swiftpm*)
        SANITIZER=$(echo "$COMMAND" | cut -d - -f 3)
        # FIXME: throwing an exception from a property getter corrupts Swift's
        # runtime exclusivity checking state. Unfortunately, this is something
        # we do a lot in tests.
        SWIFT_TEST_FLAGS=(-Xcc -g0 -Xswiftc -enforce-exclusivity=none)
        if [ -n "$SANITIZER" ]; then
            SWIFT_TEST_FLAGS+=(--sanitize "$SANITIZER")
            export ASAN_OPTIONS='check_initialization_order=true:detect_stack_use_after_return=true'
        fi
        xcrun swift package resolve
        xcrun swift test --configuration "$(echo "$CONFIGURATION" | tr "[:upper:]" "[:lower:]")" "${SWIFT_TEST_FLAGS[@]}"
        exit 0
        ;;

    "test-ios-swiftui")
        xctest 'SwiftUITestHost' -configuration "$CONFIGURATION" -sdk iphonesimulator -destination "name=$(iphone_name)"
        exit 0
        ;;

    "test-catalyst")
        xctest Realm -configuration "$CONFIGURATION" -destination 'platform=macOS,variant=Mac Catalyst' CODE_SIGN_IDENTITY=''
        exit 0
        ;;

    "test-catalyst-swift")
        xctest RealmSwift -configuration "$CONFIGURATION" -destination 'platform=macOS,variant=Mac Catalyst' CODE_SIGN_IDENTITY=''
        exit 0
        ;;

    "test-visionos")
        xctest Realm -configuration "$CONFIGURATION" -sdk xrsimulator -destination 'platform=visionOS Simulator,name=Apple Vision Pro' CODE_SIGN_IDENTITY=''
        exit 0
        ;;

    "test-visionos-swift")
        xctest RealmSwift -configuration "$CONFIGURATION" -sdk xrsimulator -destination 'platform=visionOS Simulator,name=Apple Vision Pro' CODE_SIGN_IDENTITY=''
        exit 0
        ;;

    ######################################
    # Full verification
    ######################################
    "verify")
        sh build.sh verify-cocoapods
        sh build.sh verify-docs
        sh build.sh verify-spm-ios
        sh build.sh verify-swiftlint
        sh build.sh verify-swiftpm
        sh build.sh verify-watchos
        sh buils.sh verify-xcframework

        sh build.sh verify-osx
        sh build.sh verify-osx-debug
        sh build.sh verify-osx-swift
        sh build.sh verify-osx-swift-debug
        sh build.sh verify-ios-static
        sh build.sh verify-ios-static-debug
        sh build.sh verify-ios-dynamic
        sh build.sh verify-ios-dynamic-debug
        sh build.sh verify-ios-swift
        sh build.sh verify-ios-swift-debug
        sh build.sh verify-ios-device-objc
        sh build.sh verify-ios-device-swift
        sh build.sh verify-tvos
        sh build.sh verify-tvos-debug
        sh build.sh verify-tvos-device
        sh build.sh verify-catalyst
        sh build.sh verify-catalyst-swift
        sh build.sh verify-ios-swiftui
        ;;

    "verify-cocoapods")
        export REALM_TEST_BRANCH="$BRANCH"
        if [[ -d .git ]]; then
            # Verify the current branch, unless one was already specified in the sha environment variable.
            if [[ -z $BRANCH ]]; then
                export REALM_TEST_BRANCH=$(git rev-parse --abbrev-ref HEAD)
            fi

            if [[ $(git log -1 '@{push}..') != "" ]] || ! git diff-index --quiet HEAD; then
                echo "WARNING: verify-cocoapods will test the latest revision of $BRANCH found on GitHub."
                echo "         Any unpushed local changes will not be tested."
                echo ""
                sleep 1
            fi
        fi

        cd examples/installation
        ./build.rb ios cocoapods static
        ./build.rb ios cocoapods dynamic
        ./build.rb osx cocoapods
        ./build.rb tvos cocoapods
        ./build.rb watchos cocoapods
        ./build.rb catalyst cocoapods
        ;;

    verify-cocoapods-*)
        PLATFORM=$(echo "$COMMAND" | cut -d - -f 3)
        cd examples/installation

        REALM_TEST_BRANCH="$BRANCH" ./build.rb "$PLATFORM" cocoapods "$LINKAGE"
        ;;

    "verify-docs")
        sh build.sh docs
        for lang in swift objc; do
            undocumented="docs/${lang}_output/undocumented.json"
            if ruby -rjson -e "j = JSON.parse(File.read('docs/${lang}_output/undocumented.json')); exit j['warnings'].length != 0"; then
                echo "Undocumented Realm $lang declarations:"
                cat "$undocumented"
                exit 1
            fi
        done
        exit 0
        ;;

    "verify-spm")
        export REALM_TEST_BRANCH="$BRANCH"
        if [[ -d .git ]]; then
            # Verify the current branch, unless one was already specified in the sha environment variable.
            if [[ -z $BRANCH ]]; then
                export REALM_TEST_BRANCH=$(git rev-parse --abbrev-ref HEAD)
            fi

            if [[ $(git log -1 '@{push}..') != "" ]] || ! git diff-index --quiet HEAD; then
                echo "WARNING: verify-spm will test the latest revision of $BRANCH found on GitHub."
                echo "         Any unpushed local changes will not be tested."
                echo ""
                sleep 1
            fi
        fi

        cd examples/installation
        ./build.rb ios spm static
        ./build.rb ios spm dynamic
        ./build.rb osx spm
        ./build.rb watchos spm
        ./build.rb tvos spm
        ./build.rb catalyst spm
        exit 0
        ;;

    verify-spm-*)
        PLATFORM=$(echo "$COMMAND" | cut -d - -f 3)
        cd examples/installation

        REALM_TEST_BRANCH="$BRANCH" ./build.rb "$PLATFORM" spm "$LINKAGE"
        exit 0
        ;;

    "verify-swiftlint")
        swiftlint lint --strict
        exit 0
        ;;

    verify-swiftpm*)
        sh build.sh "test-$(echo "$COMMAND" | cut -d - -f 2-)"
        exit 0
        ;;

    "verify-watchos")
        sh build.sh watchos-swift
        exit 0
        ;;

    "verify-xcframework")
        sh build.sh xcframework osx
        exit 0
        ;;

    "verify-osx-encryption")
        REALM_ENCRYPT_ALL=YES sh build.sh test-osx
        exit 0
        ;;

    "verify-osx")
        REALM_EXTRA_BUILD_ARGUMENTS="$REALM_EXTRA_BUILD_ARGUMENTS -workspace examples/osx/objc/RealmExamples.xcworkspace" \
            sh build.sh test-osx
        sh build.sh examples-osx

        (
            cd examples/osx/objc/build/DerivedData/RealmExamples/Build/Products/Release
            DYLD_FRAMEWORK_PATH=. ./JSONImport >/dev/null
        )
        exit 0
        ;;

    "verify-osx-swift-evolution")
        export REALM_EXTRA_BUILD_ARGUMENTS="$REALM_EXTRA_BUILD_ARGUMENTS REALM_BUILD_LIBRARY_FOR_DISTRIBUTION=YES"
        sh build.sh test-osx-swift
        exit 0
        ;;

    "verify-ios")
        REALM_EXTRA_BUILD_ARGUMENTS="$REALM_EXTRA_BUILD_ARGUMENTS -workspace examples/ios/objc/RealmExamples.xcworkspace" \
            sh build.sh test-ios
        sh build.sh examples-ios
        ;;

    "verify-ios-swift")
        REALM_EXTRA_BUILD_ARGUMENTS="$REALM_EXTRA_BUILD_ARGUMENTS -workspace examples/ios/swift/RealmExamples.xcworkspace" \
            sh build.sh test-ios-swift
        sh build.sh examples-ios-swift
        ;;

    "verify-ios-swift-evolution")
        export REALM_EXTRA_BUILD_ARGUMENTS="$REALM_EXTRA_BUILD_ARGUMENTS REALM_BUILD_LIBRARY_FOR_DISTRIBUTION=YES"
        sh build.sh test-ios-swift
        exit 0
        ;;

    "verify-tvos")
        REALM_EXTRA_BUILD_ARGUMENTS="$REALM_EXTRA_BUILD_ARGUMENTS -workspace examples/tvos/objc/RealmExamples.xcworkspace" \
            sh build.sh test-tvos
        sh build.sh examples-tvos
        exit 0
        ;;

    "verify-tvos-swift")
        REALM_EXTRA_BUILD_ARGUMENTS="$REALM_EXTRA_BUILD_ARGUMENTS -workspace examples/tvos/swift/RealmExamples.xcworkspace" \
            sh build.sh test-tvos-swift
        sh build.sh examples-tvos-swift
        exit 0
        ;;

    "verify-tvos-swift-evolution")
        export REALM_EXTRA_BUILD_ARGUMENTS="$REALM_EXTRA_BUILD_ARGUMENTS REALM_BUILD_LIBRARY_FOR_DISTRIBUTION=YES"
        sh build.sh test-tvos-swift
        exit 0
        ;;

    "verify-xcframework-evolution-mode")
        export REALM_EXTRA_BUILD_ARGUMENTS="$REALM_EXTRA_BUILD_ARGUMENTS REALM_BUILD_LIBRARY_FOR_DISTRIBUTION=YES"
        unset REALM_SWIFT_VERSION

        # Build with the oldest supported Xcode version
        REALM_XCODE_VERSION=$REALM_XCODE_OLDEST_VERSION sh build.sh xcframework osx

        # Try to import the built framework using the newest supported version
        cd examples/installation
        REALM_XCODE_VERSION=$REALM_XCODE_LATEST_VERSION ./build.rb osx xcframework

        exit 0
        ;;

    verify-*)
        sh build.sh "test-$(echo "$COMMAND" | cut -d - -f 2-)"
        exit 0
        ;;

    ######################################
    # Docs
    ######################################
    "docs")
        build_docs objc
        build_docs swift
        exit 0
        ;;

    ######################################
    # Examples
    ######################################
    "examples")
        sh build.sh clean
        sh build.sh examples-ios
        sh build.sh examples-ios-swift
        sh build.sh examples-osx
        sh build.sh examples-tvos
        sh build.sh examples-tvos-swift
        exit 0
        ;;

    "examples-ios")
        workspace="examples/ios/objc/RealmExamples.xcworkspace"

        examples="Simple TableView Migration Backlink GroupedTableView Encryption"
        versions="0 1 2 3 4 5"
        for example in $examples; do
            if [ "$example" = "Migration" ]; then
                # The migration example needs to be built for each schema version to ensure each compiles.
                for version in $versions; do
                    xc -workspace "$workspace" -scheme "$example" -configuration "$CONFIGURATION" -sdk iphonesimulator "${CODESIGN_PARAMS[@]}" GCC_PREPROCESSOR_DEFINITIONS="\$(GCC_PREPROCESSOR_DEFINITIONS) SCHEMA_VERSION_$version"
                done
            else
                xc -workspace "$workspace" -scheme "$example" -configuration "$CONFIGURATION" -sdk iphonesimulator "${CODESIGN_PARAMS[@]}"
            fi
        done
        if [ -n "$CI" ]; then
            xc -workspace "$workspace" -scheme Extension -configuration "$CONFIGURATION" -sdk iphonesimulator "${CODESIGN_PARAMS[@]}"
        fi

        exit 0
        ;;

    "examples-ios-swift")
        workspace="examples/ios/swift/RealmExamples.xcworkspace"
        if [[ ! -d "$workspace" ]]; then
            workspace="${workspace/swift/swift-$REALM_XCODE_VERSION}"
        fi

        examples="Simple TableView Migration Backlink GroupedTableView Encryption AppClip AppClipParent"
        versions="0 1 2 3 4 5"
        for example in $examples; do
            if [ "$example" = "Migration" ]; then
                # The migration example needs to be built for each schema version to ensure each compiles.
                for version in $versions; do
                    xc -workspace "$workspace" -scheme "$example" -configuration "$CONFIGURATION" -sdk iphonesimulator "${CODESIGN_PARAMS[@]}" OTHER_SWIFT_FLAGS="\$(OTHER_SWIFT_FLAGS) -DSCHEMA_VERSION_$version"
                done
            else
                xc -workspace "$workspace" -scheme "$example" -configuration "$CONFIGURATION" -sdk iphonesimulator "${CODESIGN_PARAMS[@]}"
            fi
        done

        exit 0
        ;;

    "examples-osx")
        workspace="examples/osx/objc/RealmExamples.xcworkspace"

        xc -workspace "$workspace" \
           -scheme JSONImport -configuration "${CONFIGURATION}" \
           -destination "platform=macOS,arch=$(uname -m)" \
           build "${CODESIGN_PARAMS[@]}"
        ;;

    "examples-tvos")
        workspace="examples/tvos/objc/RealmExamples.xcworkspace"

        examples="DownloadCache PreloadedData"
        for example in $examples; do
            xc -workspace "$workspace" -scheme "$example" -configuration "$CONFIGURATION" -sdk appletvsimulator "${CODESIGN_PARAMS[@]}"
        done

        exit 0
        ;;

    "examples-tvos-swift")
        workspace="examples/tvos/swift/RealmExamples.xcworkspace"
        if [[ ! -d "$workspace" ]]; then
            workspace="${workspace/swift/swift-$REALM_XCODE_VERSION}"
        fi

        examples="DownloadCache PreloadedData"
        for example in $examples; do
            xc -workspace "$workspace" -scheme "$example" -configuration "$CONFIGURATION" -sdk appletvsimulator "${CODESIGN_PARAMS[@]}"
        done

        exit 0
        ;;

    ######################################
    # Versioning
    ######################################
    "get-version")
        plist_get 'Realm/Realm-Info.plist' 'CFBundleShortVersionString'
        exit 0
        ;;

    "set-version")
        realm_version="$2"
        version_files="Realm/Realm-Info.plist"

        if [ -z "$realm_version" ]; then
            echo "You must specify a version."
            exit 1
        fi
        # The bundle version can contain only three groups of digits separated by periods,
        # so strip off any -beta.x tag from the end of the version string.
        bundle_version=$(echo "$realm_version" | cut -d - -f 1)
        for version_file in $version_files; do
            PlistBuddy -c "Set :CFBundleVersion $bundle_version" "$version_file"
            PlistBuddy -c "Set :CFBundleShortVersionString $realm_version" "$version_file"
        done
        sed -i '' "s/^VERSION=.*/VERSION=$realm_version/" dependencies.list
        sed -i '' "s/^let cocoaVersion =.*/let cocoaVersion = Version(\"$realm_version\")/" Package.swift
        sed -i '' "s/x.y.z Release notes (yyyy-MM-dd)/$realm_version Release notes ($(date '+%Y-%m-%d'))/" CHANGELOG.md

        exit 0
        ;;

    "set-core-version")
        new_version="$2"
        old_version="$(sed -n 's/^REALM_CORE_VERSION=\(.*\)$/\1/p' "${source_root}/dependencies.list")"

        sed -i '' "s/^REALM_CORE_VERSION=.*/REALM_CORE_VERSION=v$new_version/" dependencies.list
        sed -i '' "s/^let coreVersion =.*/let coreVersion = Version(\"$new_version\")/" Package.swift
        sed -i '' "s/Upgraded realm-core from ? to ?/Upgraded realm-core from $old_version to $new_version/" CHANGELOG.md

        exit 0
        ;;

    ######################################
    # Continuous Integration PR
    ######################################

    "ci-pr")
        echo "Building with Xcode Version $(xcodebuild -version)"
        export REALM_EXTRA_BUILD_ARGUMENTS='GCC_GENERATE_DEBUGGING_SYMBOLS=NO -allowProvisioningUpdates'
        target="$2"
        if [[ "$target" == visionos ]] && (( $(xcode_version_major) < 16 )); then
            echo 'Installing visionOS'
            xcodebuild -downloadPlatform visionOS
        fi
        sh build.sh "verify-$target"
        ;;

    ######################################
    # Release packaging
    ######################################

    "release-package-examples")
        ./scripts/package_examples.rb
        zip --symlinks -r realm-examples.zip examples -x "examples/installation/*"
        ;;

    "release-package-docs")
        sh build.sh docs
        zip -r docs/realm-docs.zip docs/objc_output docs/swift_output
        ;;

    "release-package")
        version="$(sed -n 's/^VERSION=\(.*\)$/\1/p' "${source_root}/dependencies.list")"
        find . -name 'build-*-1*' -maxdepth 1 \
            | sed 's@./build-[a-z]*-\(.*\)-.*@\1@' \
            | sort -u --version-sort \
            | xargs ./scripts/create-release-package.rb "${ROOT_WORKSPACE}/pkg" "${version}"
        ;;

    "release-test-examples")
        VERSION="$(sed -n 's/^VERSION=\(.*\)$/\1/p' "${source_root}/dependencies.list")"
        filename="realm-swift-${VERSION}"
        unzip "${filename}"

        cp "$0" "${filename}"
        cp -r "${source_root}/scripts" "${filename}"
        cp "dependencies.list" "${filename}"

        cd "${filename}"
        sh build.sh examples-ios
        sh build.sh examples-tvos
        sh build.sh examples-osx
        sh build.sh examples-ios-swift
        sh build.sh examples-tvos-swift
        cd ..
        rm -rf "${filename}"

        exit 0
        ;;

    "install-apple-certificates")
        # create variables
        CERTIFICATE_PATH=$RUNNER_TEMP/build_certificate.p12
        KEYCHAIN_PATH=$RUNNER_TEMP/app-signing.keychain-db

        # import certificate and provisioning profile from secrets
        echo "$DEVELOPMENT_CERTIFICATE_BASE64" | base64 --decode -o $CERTIFICATE_PATH

        # create temporary keychain
        security create-keychain -p "$KEYCHAIN_PASSWORD" $KEYCHAIN_PATH
        security set-keychain-settings -lut 21600 $KEYCHAIN_PATH
        security unlock-keychain -p "$KEYCHAIN_PASSWORD" $KEYCHAIN_PATH

        # import certificate to keychain
        security import $CERTIFICATE_PATH -P "$P12_PASSWORD" -A -t cert -f pkcs12 -k $KEYCHAIN_PATH
        security set-key-partition-list -S apple-tool:,apple: -k "$KEYCHAIN_PASSWORD" $KEYCHAIN_PATH
        security list-keychain -d user -s $KEYCHAIN_PATH

        exit 0
        ;;

    ######################################
    # Release tests
    ######################################

    "test-package-examples")
        VERSION="$(sed -n 's/^VERSION=\(.*\)$/\1/p' "${source_root}/dependencies.list")"
        dir="realm-swift-${VERSION}"

        # Unzip it
        unzip "${dir}.zip"

        # Copy the build.sh file into the downloaded directory
        cp "$0" "${dir}"

        # Copy the scripts into the downloaded directory
        cp -r "${ROOT_WORKSPACE}/scripts" "${dir}"

        # Copy dependencies.list
        cp -r "${ROOT_WORKSPACE}/dependencies.list" "${dir}"

        cd "${dir}"
        # Test Examples
        sh build.sh examples-ios
        sh build.sh examples-tvos
        sh build.sh examples-osx
        sh build.sh examples-ios-swift
        sh build.sh examples-tvos-swift
        ;;

    ######################################
    # Publish
    ######################################

    "publish-github")
        sha="$2"
        VERSION="$(sed -n 's/^VERSION=\(.*\)$/\1/p' "${source_root}/dependencies.list")"

        ./scripts/github_release.rb download-artifacts release-package "${sha}"

        unzip release-package.zip -d release-package

        ./scripts/github_release.rb create-release "$VERSION"
        exit 0
        ;;

    "publish-docs")
        sha="$2"

        ./scripts/github_release.rb download-artifacts realm-docs "${sha}"
        unzip_artifact realm-docs.zip
        unzip realm-docs.zip

        VERSION="$(sed -n 's/^VERSION=\(.*\)$/\1/p' "${source_root}/dependencies.list")"
        PRERELEASE_REGEX='alpha|beta|rc|preview'
        if [[ $VERSION =~ $PRERELEASE_REGEX ]]; then
          echo "Pre-release version"
          exit 0
        fi

        s3cmd put --no-mime-magic --guess-mime-type --recursive --acl-public docs/swift_output/ s3://realm-sdks/docs/realm-sdks/swift/${VERSION}/
        s3cmd put --no-mime-magic --guess-mime-type --recursive --acl-public docs/swift_output/ s3://realm-sdks/docs/realm-sdks/swift/latest/

        s3cmd put --no-mime-magic --guess-mime-type --recursive --acl-public docs/objc_output/ s3://realm-sdks/docs/realm-sdks/objc/${VERSION}/
        s3cmd put --no-mime-magic --guess-mime-type --recursive --acl-public docs/objc_output/ s3://realm-sdks/docs/realm-sdks/objc/latest/
        ;;

    "publish-cocoapods")
        cd "${ROOT_WORKSPACE}"
        pod trunk push Realm.podspec --verbose --allow-warnings
        pod trunk push RealmSwift.podspec --verbose --allow-warnings --synchronous
        exit 0
        ;;

    "prepare-publish-changelog")
        VERSION="$(sed -n 's/^VERSION=\(.*\)$/\1/p' "${source_root}/dependencies.list")"
        ./scripts/github_release.rb package-release-notes "$VERSION"
        exit 0
        ;;

    "add-empty-changelog")
        empty_section=$(cat <<EOS
x.y.z Release notes (yyyy-MM-dd)
=============================================================
### Enhancements
* None.

### Fixed
* <How to hit and notice issue? what was the impact?> ([#????](https://github.com/realm/realm-swift/issues/????), since v?.?.?)
* None.

<!-- ### Breaking Changes - ONLY INCLUDE FOR NEW MAJOR version -->

### Compatibility
* Carthage release for Swift is built with Xcode 16.4.0.
* CocoaPods: 1.10 or later.
* Xcode: 15.3.0-16.4.

### Internal
* Upgraded realm-core from ? to ?

EOS)
        changelog=$(cat CHANGELOG.md)
        echo "$empty_section" > CHANGELOG.md
        echo >> CHANGELOG.md
        echo "$changelog" >> CHANGELOG.md
        ;;

    *)
        echo "Unknown command '$COMMAND'"
        usage
        exit 1
        ;;
esac
