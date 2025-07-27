#!/bin/bash

# Project Recovery Script for Xcode 16.4
# Created on July 20, 2025

echo "🔧 Wine Manager Project Recovery Tool"
echo "===================================="

# Paths
MAIN_PROJECT="/Users/VBLPD/Desktop/SimpleWineManager/SimpleWineManager.xcodeproj/project.pbxproj"
INNER_PROJECT="/Users/VBLPD/Desktop/SimpleWineManager/SimpleWineManager/SimpleWineManager.xcodeproj/project.pbxproj"
SOURCE_DIR="/Users/VBLPD/Desktop/SimpleWineManager/SimpleWineManager/SimpleWineManager"
BACKUP_DIR="/Users/VBLPD/Desktop/SimpleWineManager/backups/project_recovery_$(date +%Y%m%d_%H%M%S)"

# Create backup
echo "📦 Creating backup in: $BACKUP_DIR"
mkdir -p "$BACKUP_DIR"

if [ -f "$MAIN_PROJECT" ]; then
    cp "$MAIN_PROJECT" "$BACKUP_DIR/main_project.pbxproj.bak"
fi

if [ -f "$INNER_PROJECT" ]; then
    cp "$INNER_PROJECT" "$BACKUP_DIR/inner_project.pbxproj.bak"
fi

echo "✅ Backups created successfully"

# Create a new template project.pbxproj for Xcode 16.4
echo "🛠️ Creating new compatible project file..."

# Generate main project file compatible with Xcode 16.4
cat > "$MAIN_PROJECT" << 'EOL'
// !$*UTF8*$!
{
	archiveVersion = 1;
	classes = {
	};
	objectVersion = 56;
	objects = {

/* Begin PBXBuildFile section */
		8A1B51AA2B4D2A8E00CDD208 /* SimpleWineManagerApp.swift in Sources */ = {isa = PBXBuildFile; fileRef = 8A1B51A92B4D2A8E00CDD208 /* SimpleWineManagerApp.swift */; };
		8A1B51AC2B4D2A8E00CDD208 /* ContentView.swift in Sources */ = {isa = PBXBuildFile; fileRef = 8A1B51AB2B4D2A8E00CDD208 /* ContentView.swift */; };
		8A1B51AE2B4D2A9100CDD208 /* Assets.xcassets in Resources */ = {isa = PBXBuildFile; fileRef = 8A1B51AD2B4D2A9100CDD208 /* Assets.xcassets */; };
		8A1B51B12B4D2A9100CDD208 /* Preview Assets.xcassets in Resources */ = {isa = PBXBuildFile; fileRef = 8A1B51B02B4D2A9100CDD208 /* Preview Assets.xcassets */; };
		8A1B51B32B4D2A9100CDD208 /* Persistence.swift in Sources */ = {isa = PBXBuildFile; fileRef = 8A1B51B22B4D2A9100CDD208 /* Persistence.swift */; };
		8A1B51B62B4D2A9100CDD208 /* SimpleWineManager.xcdatamodeld in Sources */ = {isa = PBXBuildFile; fileRef = 8A1B51B42B4D2A9100CDD208 /* SimpleWineManager.xcdatamodeld */; };
		8A1B51C02B4D2A9200CDD208 /* SimpleWineManagerTests.swift in Sources */ = {isa = PBXBuildFile; fileRef = 8A1B51BF2B4D2A9200CDD208 /* SimpleWineManagerTests.swift */; };
		8A1B51CA2B4D2A9200CDD208 /* SimpleWineManagerUITests.swift in Sources */ = {isa = PBXBuildFile; fileRef = 8A1B51C92B4D2A9200CDD208 /* SimpleWineManagerUITests.swift */; };
		8A1B51CC2B4D2A9200CDD208 /* SimpleWineManagerUITestsLaunchTests.swift in Sources */ = {isa = PBXBuildFile; fileRef = 8A1B51CB2B4D2A9200CDD208 /* SimpleWineManagerUITestsLaunchTests.swift */; };
/* End PBXBuildFile section */

/* Begin PBXContainerItemProxy section */
		8A1B51BC2B4D2A9200CDD208 /* PBXContainerItemProxy */ = {
			isa = PBXContainerItemProxy;
			containerPortal = 8A1B519E2B4D2A8E00CDD208 /* Project object */;
			proxyType = 1;
			remoteGlobalIDString = 8A1B51A52B4D2A8E00CDD208;
			remoteInfo = SimpleWineManager;
		};
		8A1B51C62B4D2A9200CDD208 /* PBXContainerItemProxy */ = {
			isa = PBXContainerItemProxy;
			containerPortal = 8A1B519E2B4D2A8E00CDD208 /* Project object */;
			proxyType = 1;
			remoteGlobalIDString = 8A1B51A52B4D2A8E00CDD208;
			remoteInfo = SimpleWineManager;
		};
/* End PBXContainerItemProxy section */

/* Begin PBXFileReference section */
		8A1B51A62B4D2A8E00CDD208 /* SimpleWineManager.app */ = {isa = PBXFileReference; explicitFileType = wrapper.application; includeInIndex = 0; path = SimpleWineManager.app; sourceTree = BUILT_PRODUCTS_DIR; };
		8A1B51A92B4D2A8E00CDD208 /* SimpleWineManagerApp.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = SimpleWineManagerApp.swift; sourceTree = "<group>"; };
		8A1B51AB2B4D2A8E00CDD208 /* ContentView.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = ContentView.swift; sourceTree = "<group>"; };
		8A1B51AD2B4D2A9100CDD208 /* Assets.xcassets */ = {isa = PBXFileReference; lastKnownFileType = folder.assetcatalog; path = Assets.xcassets; sourceTree = "<group>"; };
		8A1B51B02B4D2A9100CDD208 /* Preview Assets.xcassets */ = {isa = PBXFileReference; lastKnownFileType = folder.assetcatalog; path = "Preview Assets.xcassets"; sourceTree = "<group>"; };
		8A1B51B22B4D2A9100CDD208 /* Persistence.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = Persistence.swift; sourceTree = "<group>"; };
		8A1B51B52B4D2A9100CDD208 /* SimpleWineManager.xcdatamodel */ = {isa = PBXFileReference; lastKnownFileType = wrapper.xcdatamodel; path = SimpleWineManager.xcdatamodel; sourceTree = "<group>"; };
		8A1B51BB2B4D2A9200CDD208 /* SimpleWineManagerTests.xctest */ = {isa = PBXFileReference; explicitFileType = wrapper.cfbundle; includeInIndex = 0; path = SimpleWineManagerTests.xctest; sourceTree = BUILT_PRODUCTS_DIR; };
		8A1B51BF2B4D2A9200CDD208 /* SimpleWineManagerTests.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = SimpleWineManagerTests.swift; sourceTree = "<group>"; };
		8A1B51C52B4D2A9200CDD208 /* SimpleWineManagerUITests.xctest */ = {isa = PBXFileReference; explicitFileType = wrapper.cfbundle; includeInIndex = 0; path = SimpleWineManagerUITests.xctest; sourceTree = BUILT_PRODUCTS_DIR; };
		8A1B51C92B4D2A9200CDD208 /* SimpleWineManagerUITests.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = SimpleWineManagerUITests.swift; sourceTree = "<group>"; };
		8A1B51CB2B4D2A9200CDD208 /* SimpleWineManagerUITestsLaunchTests.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = SimpleWineManagerUITestsLaunchTests.swift; sourceTree = "<group>"; };
		8A1B51D82B4D2B6900CDD208 /* Info.plist */ = {isa = PBXFileReference; lastKnownFileType = text.plist; path = Info.plist; sourceTree = "<group>"; };
/* End PBXFileReference section */

/* Begin PBXFrameworksBuildPhase section */
		8A1B51A32B4D2A8E00CDD208 /* Frameworks */ = {
			isa = PBXFrameworksBuildPhase;
			buildActionMask = 2147483647;
			files = (
			);
			runOnlyForDeploymentPostprocessing = 0;
		};
		8A1B51B82B4D2A9200CDD208 /* Frameworks */ = {
			isa = PBXFrameworksBuildPhase;
			buildActionMask = 2147483647;
			files = (
			);
			runOnlyForDeploymentPostprocessing = 0;
		};
		8A1B51C22B4D2A9200CDD208 /* Frameworks */ = {
			isa = PBXFrameworksBuildPhase;
			buildActionMask = 2147483647;
			files = (
			);
			runOnlyForDeploymentPostprocessing = 0;
		};
/* End PBXFrameworksBuildPhase section */

/* Begin PBXGroup section */
		8A1B519D2B4D2A8E00CDD208 = {
			isa = PBXGroup;
			children = (
				8A1B51A82B4D2A8E00CDD208 /* SimpleWineManager */,
				8A1B51BE2B4D2A9200CDD208 /* SimpleWineManagerTests */,
				8A1B51C82B4D2A9200CDD208 /* SimpleWineManagerUITests */,
				8A1B51A72B4D2A8E00CDD208 /* Products */,
			);
			sourceTree = "<group>";
		};
		8A1B51A72B4D2A8E00CDD208 /* Products */ = {
			isa = PBXGroup;
			children = (
				8A1B51A62B4D2A8E00CDD208 /* SimpleWineManager.app */,
				8A1B51BB2B4D2A9200CDD208 /* SimpleWineManagerTests.xctest */,
				8A1B51C52B4D2A9200CDD208 /* SimpleWineManagerUITests.xctest */,
			);
			name = Products;
			sourceTree = "<group>";
		};
		8A1B51A82B4D2A8E00CDD208 /* SimpleWineManager */ = {
			isa = PBXGroup;
			children = (
				8A1B51D82B4D2B6900CDD208 /* Info.plist */,
				8A1B51A92B4D2A8E00CDD208 /* SimpleWineManagerApp.swift */,
				8A1B51AB2B4D2A8E00CDD208 /* ContentView.swift */,
				8A1B51AD2B4D2A9100CDD208 /* Assets.xcassets */,
				8A1B51B22B4D2A9100CDD208 /* Persistence.swift */,
				8A1B51B42B4D2A9100CDD208 /* SimpleWineManager.xcdatamodeld */,
				8A1B51AF2B4D2A9100CDD208 /* Preview Content */,
			);
			path = SimpleWineManager;
			sourceTree = "<group>";
		};
		8A1B51AF2B4D2A9100CDD208 /* Preview Content */ = {
			isa = PBXGroup;
			children = (
				8A1B51B02B4D2A9100CDD208 /* Preview Assets.xcassets */,
			);
			path = "Preview Content";
			sourceTree = "<group>";
		};
		8A1B51BE2B4D2A9200CDD208 /* SimpleWineManagerTests */ = {
			isa = PBXGroup;
			children = (
				8A1B51BF2B4D2A9200CDD208 /* SimpleWineManagerTests.swift */,
			);
			path = SimpleWineManagerTests;
			sourceTree = "<group>";
		};
		8A1B51C82B4D2A9200CDD208 /* SimpleWineManagerUITests */ = {
			isa = PBXGroup;
			children = (
				8A1B51C92B4D2A9200CDD208 /* SimpleWineManagerUITests.swift */,
				8A1B51CB2B4D2A9200CDD208 /* SimpleWineManagerUITestsLaunchTests.swift */,
			);
			path = SimpleWineManagerUITests;
			sourceTree = "<group>";
		};
/* End PBXGroup section */

/* Begin PBXNativeTarget section */
		8A1B51A52B4D2A8E00CDD208 /* SimpleWineManager */ = {
			isa = PBXNativeTarget;
			buildConfigurationList = 8A1B51CF2B4D2A9200CDD208 /* Build configuration list for PBXNativeTarget "SimpleWineManager" */;
			buildPhases = (
				8A1B51A22B4D2A8E00CDD208 /* Sources */,
				8A1B51A32B4D2A8E00CDD208 /* Frameworks */,
				8A1B51A42B4D2A8E00CDD208 /* Resources */,
			);
			buildRules = (
			);
			dependencies = (
			);
			name = SimpleWineManager;
			productName = SimpleWineManager;
			productReference = 8A1B51A62B4D2A8E00CDD208 /* SimpleWineManager.app */;
			productType = "com.apple.product-type.application";
		};
		8A1B51BA2B4D2A9200CDD208 /* SimpleWineManagerTests */ = {
			isa = PBXNativeTarget;
			buildConfigurationList = 8A1B51D22B4D2A9200CDD208 /* Build configuration list for PBXNativeTarget "SimpleWineManagerTests" */;
			buildPhases = (
				8A1B51B72B4D2A9200CDD208 /* Sources */,
				8A1B51B82B4D2A9200CDD208 /* Frameworks */,
				8A1B51B92B4D2A9200CDD208 /* Resources */,
			);
			buildRules = (
			);
			dependencies = (
				8A1B51BD2B4D2A9200CDD208 /* PBXTargetDependency */,
			);
			name = SimpleWineManagerTests;
			productName = SimpleWineManagerTests;
			productReference = 8A1B51BB2B4D2A9200CDD208 /* SimpleWineManagerTests.xctest */;
			productType = "com.apple.product-type.bundle.unit-test";
		};
		8A1B51C42B4D2A9200CDD208 /* SimpleWineManagerUITests */ = {
			isa = PBXNativeTarget;
			buildConfigurationList = 8A1B51D52B4D2A9200CDD208 /* Build configuration list for PBXNativeTarget "SimpleWineManagerUITests" */;
			buildPhases = (
				8A1B51C12B4D2A9200CDD208 /* Sources */,
				8A1B51C22B4D2A9200CDD208 /* Frameworks */,
				8A1B51C32B4D2A9200CDD208 /* Resources */,
			);
			buildRules = (
			);
			dependencies = (
				8A1B51C72B4D2A9200CDD208 /* PBXTargetDependency */,
			);
			name = SimpleWineManagerUITests;
			productName = SimpleWineManagerUITests;
			productReference = 8A1B51C52B4D2A9200CDD208 /* SimpleWineManagerUITests.xctest */;
			productType = "com.apple.product-type.bundle.ui-testing";
		};
/* End PBXNativeTarget section */

/* Begin PBXProject section */
		8A1B519E2B4D2A8E00CDD208 /* Project object */ = {
			isa = PBXProject;
			attributes = {
				BuildIndependentTargetsInParallel = 1;
				LastSwiftUpdateCheck = 1500;
				LastUpgradeCheck = 1500;
				TargetAttributes = {
					8A1B51A52B4D2A8E00CDD208 = {
						CreatedOnToolsVersion = 15.0.1;
					};
					8A1B51BA2B4D2A9200CDD208 = {
						CreatedOnToolsVersion = 15.0.1;
						TestTargetID = 8A1B51A52B4D2A8E00CDD208;
					};
					8A1B51C42B4D2A9200CDD208 = {
						CreatedOnToolsVersion = 15.0.1;
						TestTargetID = 8A1B51A52B4D2A8E00CDD208;
					};
				};
			};
			buildConfigurationList = 8A1B51A12B4D2A8E00CDD208 /* Build configuration list for PBXProject "SimpleWineManager" */;
			compatibilityVersion = "Xcode 14.0";
			developmentRegion = en;
			hasScannedForEncodings = 0;
			knownRegions = (
				en,
				Base,
			);
			mainGroup = 8A1B519D2B4D2A8E00CDD208;
			productRefGroup = 8A1B51A72B4D2A8E00CDD208 /* Products */;
			projectDirPath = "";
			projectRoot = "";
			targets = (
				8A1B51A52B4D2A8E00CDD208 /* SimpleWineManager */,
				8A1B51BA2B4D2A9200CDD208 /* SimpleWineManagerTests */,
				8A1B51C42B4D2A9200CDD208 /* SimpleWineManagerUITests */,
			);
		};
/* End PBXProject section */

/* Begin PBXResourcesBuildPhase section */
		8A1B51A42B4D2A8E00CDD208 /* Resources */ = {
			isa = PBXResourcesBuildPhase;
			buildActionMask = 2147483647;
			files = (
				8A1B51B12B4D2A9100CDD208 /* Preview Assets.xcassets in Resources */,
				8A1B51AE2B4D2A9100CDD208 /* Assets.xcassets in Resources */,
			);
			runOnlyForDeploymentPostprocessing = 0;
		};
		8A1B51B92B4D2A9200CDD208 /* Resources */ = {
			isa = PBXResourcesBuildPhase;
			buildActionMask = 2147483647;
			files = (
			);
			runOnlyForDeploymentPostprocessing = 0;
		};
		8A1B51C32B4D2A9200CDD208 /* Resources */ = {
			isa = PBXResourcesBuildPhase;
			buildActionMask = 2147483647;
			files = (
			);
			runOnlyForDeploymentPostprocessing = 0;
		};
/* End PBXResourcesBuildPhase section */

/* Begin PBXSourcesBuildPhase section */
		8A1B51A22B4D2A8E00CDD208 /* Sources */ = {
			isa = PBXSourcesBuildPhase;
			buildActionMask = 2147483647;
			files = (
				8A1B51B32B4D2A9100CDD208 /* Persistence.swift in Sources */,
				8A1B51AC2B4D2A8E00CDD208 /* ContentView.swift in Sources */,
				8A1B51B62B4D2A9100CDD208 /* SimpleWineManager.xcdatamodeld in Sources */,
				8A1B51AA2B4D2A8E00CDD208 /* SimpleWineManagerApp.swift in Sources */,
			);
			runOnlyForDeploymentPostprocessing = 0;
		};
		8A1B51B72B4D2A9200CDD208 /* Sources */ = {
			isa = PBXSourcesBuildPhase;
			buildActionMask = 2147483647;
			files = (
				8A1B51C02B4D2A9200CDD208 /* SimpleWineManagerTests.swift in Sources */,
			);
			runOnlyForDeploymentPostprocessing = 0;
		};
		8A1B51C12B4D2A9200CDD208 /* Sources */ = {
			isa = PBXSourcesBuildPhase;
			buildActionMask = 2147483647;
			files = (
				8A1B51CC2B4D2A9200CDD208 /* SimpleWineManagerUITestsLaunchTests.swift in Sources */,
				8A1B51CA2B4D2A9200CDD208 /* SimpleWineManagerUITests.swift in Sources */,
			);
			runOnlyForDeploymentPostprocessing = 0;
		};
/* End PBXSourcesBuildPhase section */

/* Begin PBXTargetDependency section */
		8A1B51BD2B4D2A9200CDD208 /* PBXTargetDependency */ = {
			isa = PBXTargetDependency;
			target = 8A1B51A52B4D2A8E00CDD208 /* SimpleWineManager */;
			targetProxy = 8A1B51BC2B4D2A9200CDD208 /* PBXContainerItemProxy */;
		};
		8A1B51C72B4D2A9200CDD208 /* PBXTargetDependency */ = {
			isa = PBXTargetDependency;
			target = 8A1B51A52B4D2A8E00CDD208 /* SimpleWineManager */;
			targetProxy = 8A1B51C62B4D2A9200CDD208 /* PBXContainerItemProxy */;
		};
/* End PBXTargetDependency section */

/* Begin XCBuildConfiguration section */
		8A1B51CD2B4D2A9200CDD208 /* Debug */ = {
			isa = XCBuildConfiguration;
			buildSettings = {
				ALWAYS_SEARCH_USER_PATHS = NO;
				ASSETCATALOG_COMPILER_GENERATE_SWIFT_ASSET_SYMBOL_EXTENSIONS = YES;
				CLANG_ANALYZER_NONNULL = YES;
				CLANG_ANALYZER_NUMBER_OBJECT_CONVERSION = YES_AGGRESSIVE;
				CLANG_CXX_LANGUAGE_STANDARD = "gnu++20";
				CLANG_ENABLE_MODULES = YES;
				CLANG_ENABLE_OBJC_ARC = YES;
				CLANG_ENABLE_OBJC_WEAK = YES;
				CLANG_WARN_BLOCK_CAPTURE_AUTORELEASING = YES;
				CLANG_WARN_BOOL_CONVERSION = YES;
				CLANG_WARN_COMMA = YES;
				CLANG_WARN_CONSTANT_CONVERSION = YES;
				CLANG_WARN_DEPRECATED_OBJC_IMPLEMENTATIONS = YES;
				CLANG_WARN_DIRECT_OBJC_ISA_USAGE = YES_ERROR;
				CLANG_WARN_DOCUMENTATION_COMMENTS = YES;
				CLANG_WARN_EMPTY_BODY = YES;
				CLANG_WARN_ENUM_CONVERSION = YES;
				CLANG_WARN_INFINITE_RECURSION = YES;
				CLANG_WARN_INT_CONVERSION = YES;
				CLANG_WARN_NON_LITERAL_NULL_CONVERSION = YES;
				CLANG_WARN_OBJC_IMPLICIT_RETAIN_SELF = YES;
				CLANG_WARN_OBJC_LITERAL_CONVERSION = YES;
				CLANG_WARN_OBJC_ROOT_CLASS = YES_ERROR;
				CLANG_WARN_QUOTED_INCLUDE_IN_FRAMEWORK_HEADER = YES;
				CLANG_WARN_RANGE_LOOP_ANALYSIS = YES;
				CLANG_WARN_STRICT_PROTOTYPES = YES;
				CLANG_WARN_SUSPICIOUS_MOVE = YES;
				CLANG_WARN_UNGUARDED_AVAILABILITY = YES_AGGRESSIVE;
				CLANG_WARN_UNREACHABLE_CODE = YES;
				CLANG_WARN__DUPLICATE_METHOD_MATCH = YES;
				COPY_PHASE_STRIP = NO;
				DEBUG_INFORMATION_FORMAT = dwarf;
				ENABLE_STRICT_OBJC_MSGSEND = YES;
				ENABLE_TESTABILITY = YES;
				ENABLE_USER_SCRIPT_SANDBOXING = YES;
				GCC_C_LANGUAGE_STANDARD = gnu17;
				GCC_DYNAMIC_NO_PIC = NO;
				GCC_NO_COMMON_BLOCKS = YES;
				GCC_OPTIMIZATION_LEVEL = 0;
				GCC_PREPROCESSOR_DEFINITIONS = (
					"DEBUG=1",
					"$(inherited)",
				);
				GCC_WARN_64_TO_32_BIT_CONVERSION = YES;
				GCC_WARN_ABOUT_RETURN_TYPE = YES_ERROR;
				GCC_WARN_UNDECLARED_SELECTOR = YES;
				GCC_WARN_UNINITIALIZED_AUTOS = YES_AGGRESSIVE;
				GCC_WARN_UNUSED_FUNCTION = YES;
				GCC_WARN_UNUSED_VARIABLE = YES;
				IPHONEOS_DEPLOYMENT_TARGET = 17.0;
				LOCALIZATION_PREFERS_STRING_CATALOGS = YES;
				MTL_ENABLE_DEBUG_INFO = INCLUDE_SOURCE;
				MTL_FAST_MATH = YES;
				ONLY_ACTIVE_ARCH = YES;
				SDKROOT = iphoneos;
				SWIFT_ACTIVE_COMPILATION_CONDITIONS = "DEBUG $(inherited)";
				SWIFT_OPTIMIZATION_LEVEL = "-Onone";
			};
			name = Debug;
		};
		8A1B51CE2B4D2A9200CDD208 /* Release */ = {
			isa = XCBuildConfiguration;
			buildSettings = {
				ALWAYS_SEARCH_USER_PATHS = NO;
				ASSETCATALOG_COMPILER_GENERATE_SWIFT_ASSET_SYMBOL_EXTENSIONS = YES;
				CLANG_ANALYZER_NONNULL = YES;
				CLANG_ANALYZER_NUMBER_OBJECT_CONVERSION = YES_AGGRESSIVE;
				CLANG_CXX_LANGUAGE_STANDARD = "gnu++20";
				CLANG_ENABLE_MODULES = YES;
				CLANG_ENABLE_OBJC_ARC = YES;
				CLANG_ENABLE_OBJC_WEAK = YES;
				CLANG_WARN_BLOCK_CAPTURE_AUTORELEASING = YES;
				CLANG_WARN_BOOL_CONVERSION = YES;
				CLANG_WARN_COMMA = YES;
				CLANG_WARN_CONSTANT_CONVERSION = YES;
				CLANG_WARN_DEPRECATED_OBJC_IMPLEMENTATIONS = YES;
				CLANG_WARN_DIRECT_OBJC_ISA_USAGE = YES_ERROR;
				CLANG_WARN_DOCUMENTATION_COMMENTS = YES;
				CLANG_WARN_EMPTY_BODY = YES;
				CLANG_WARN_ENUM_CONVERSION = YES;
				CLANG_WARN_INFINITE_RECURSION = YES;
				CLANG_WARN_INT_CONVERSION = YES;
				CLANG_WARN_NON_LITERAL_NULL_CONVERSION = YES;
				CLANG_WARN_OBJC_IMPLICIT_RETAIN_SELF = YES;
				CLANG_WARN_OBJC_LITERAL_CONVERSION = YES;
				CLANG_WARN_OBJC_ROOT_CLASS = YES_ERROR;
				CLANG_WARN_QUOTED_INCLUDE_IN_FRAMEWORK_HEADER = YES;
				CLANG_WARN_RANGE_LOOP_ANALYSIS = YES;
				CLANG_WARN_STRICT_PROTOTYPES = YES;
				CLANG_WARN_SUSPICIOUS_MOVE = YES;
				CLANG_WARN_UNGUARDED_AVAILABILITY = YES_AGGRESSIVE;
				CLANG_WARN_UNREACHABLE_CODE = YES;
				CLANG_WARN__DUPLICATE_METHOD_MATCH = YES;
				COPY_PHASE_STRIP = NO;
				DEBUG_INFORMATION_FORMAT = "dwarf-with-dsym";
				ENABLE_NS_ASSERTIONS = NO;
				ENABLE_STRICT_OBJC_MSGSEND = YES;
				ENABLE_USER_SCRIPT_SANDBOXING = YES;
				GCC_C_LANGUAGE_STANDARD = gnu17;
				GCC_NO_COMMON_BLOCKS = YES;
				GCC_WARN_64_TO_32_BIT_CONVERSION = YES;
				GCC_WARN_ABOUT_RETURN_TYPE = YES_ERROR;
				GCC_WARN_UNDECLARED_SELECTOR = YES;
				GCC_WARN_UNINITIALIZED_AUTOS = YES_AGGRESSIVE;
				GCC_WARN_UNUSED_FUNCTION = YES;
				GCC_WARN_UNUSED_VARIABLE = YES;
				IPHONEOS_DEPLOYMENT_TARGET = 17.0;
				LOCALIZATION_PREFERS_STRING_CATALOGS = YES;
				MTL_ENABLE_DEBUG_INFO = NO;
				MTL_FAST_MATH = YES;
				SDKROOT = iphoneos;
				SWIFT_COMPILATION_MODE = wholemodule;
				VALIDATE_PRODUCT = YES;
			};
			name = Release;
		};
		8A1B51D02B4D2A9200CDD208 /* Debug */ = {
			isa = XCBuildConfiguration;
			buildSettings = {
				ASSETCATALOG_COMPILER_APPICON_NAME = AppIcon;
				ASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME = AccentColor;
				CODE_SIGN_STYLE = Automatic;
				CURRENT_PROJECT_VERSION = 4;
				DEVELOPMENT_ASSET_PATHS = "\"SimpleWineManager/Preview Content\"";
				DEVELOPMENT_TEAM = C2HM9UNJ72;
				ENABLE_PREVIEWS = YES;
				GENERATE_INFOPLIST_FILE = YES;
				INFOPLIST_FILE = SimpleWineManager/Info.plist;
				INFOPLIST_KEY_CFBundleDisplayName = Wine;
				INFOPLIST_KEY_NSCameraUsageDescription = "To take pictures of wine labels";
				INFOPLIST_KEY_NSPhotoLibraryAddUsageDescription = "To select photos of wine labels";
				INFOPLIST_KEY_UIApplicationSceneManifest_Generation = YES;
				INFOPLIST_KEY_UIApplicationSupportsIndirectInputEvents = YES;
				INFOPLIST_KEY_UILaunchScreen_Generation = YES;
				INFOPLIST_KEY_UISupportedInterfaceOrientations_iPad = "UIInterfaceOrientationPortrait UIInterfaceOrientationPortraitUpsideDown UIInterfaceOrientationLandscapeLeft UIInterfaceOrientationLandscapeRight";
				INFOPLIST_KEY_UISupportedInterfaceOrientations_iPhone = "UIInterfaceOrientationPortrait UIInterfaceOrientationLandscapeLeft UIInterfaceOrientationLandscapeRight";
				LD_RUNPATH_SEARCH_PATHS = (
					"$(inherited)",
					"@executable_path/Frameworks",
				);
				MARKETING_VERSION = 2.3;
				PRODUCT_BUNDLE_IDENTIFIER = com.dieterlempen.SimpleWineManager;
				PRODUCT_NAME = "$(TARGET_NAME)";
				SWIFT_EMIT_LOC_STRINGS = YES;
				SWIFT_VERSION = 5.0;
				TARGETED_DEVICE_FAMILY = "1,2";
			};
			name = Debug;
		};
		8A1B51D12B4D2A9200CDD208 /* Release */ = {
			isa = XCBuildConfiguration;
			buildSettings = {
				ASSETCATALOG_COMPILER_APPICON_NAME = AppIcon;
				ASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME = AccentColor;
				CODE_SIGN_STYLE = Automatic;
				CURRENT_PROJECT_VERSION = 4;
				DEVELOPMENT_ASSET_PATHS = "\"SimpleWineManager/Preview Content\"";
				DEVELOPMENT_TEAM = C2HM9UNJ72;
				ENABLE_PREVIEWS = YES;
				GENERATE_INFOPLIST_FILE = YES;
				INFOPLIST_FILE = SimpleWineManager/Info.plist;
				INFOPLIST_KEY_CFBundleDisplayName = Wine;
				INFOPLIST_KEY_NSCameraUsageDescription = "To take pictures of wine labels";
				INFOPLIST_KEY_NSPhotoLibraryAddUsageDescription = "To select photos of wine labels";
				INFOPLIST_KEY_UIApplicationSceneManifest_Generation = YES;
				INFOPLIST_KEY_UIApplicationSupportsIndirectInputEvents = YES;
				INFOPLIST_KEY_UILaunchScreen_Generation = YES;
				INFOPLIST_KEY_UISupportedInterfaceOrientations_iPad = "UIInterfaceOrientationPortrait UIInterfaceOrientationPortraitUpsideDown UIInterfaceOrientationLandscapeLeft UIInterfaceOrientationLandscapeRight";
				INFOPLIST_KEY_UISupportedInterfaceOrientations_iPhone = "UIInterfaceOrientationPortrait UIInterfaceOrientationLandscapeLeft UIInterfaceOrientationLandscapeRight";
				LD_RUNPATH_SEARCH_PATHS = (
					"$(inherited)",
					"@executable_path/Frameworks",
				);
				MARKETING_VERSION = 2.3;
				PRODUCT_BUNDLE_IDENTIFIER = com.dieterlempen.SimpleWineManager;
				PRODUCT_NAME = "$(TARGET_NAME)";
				SWIFT_EMIT_LOC_STRINGS = YES;
				SWIFT_VERSION = 5.0;
				TARGETED_DEVICE_FAMILY = "1,2";
			};
			name = Release;
		};
		8A1B51D32B4D2A9200CDD208 /* Debug */ = {
			isa = XCBuildConfiguration;
			buildSettings = {
				BUNDLE_LOADER = "$(TEST_HOST)";
				CODE_SIGN_STYLE = Automatic;
				CURRENT_PROJECT_VERSION = 4;
				DEVELOPMENT_TEAM = C2HM9UNJ72;
				GENERATE_INFOPLIST_FILE = YES;
				IPHONEOS_DEPLOYMENT_TARGET = 17.0;
				MARKETING_VERSION = 2.3;
				PRODUCT_BUNDLE_IDENTIFIER = com.dieterlempen.SimpleWineManagerTests;
				PRODUCT_NAME = "$(TARGET_NAME)";
				SWIFT_EMIT_LOC_STRINGS = NO;
				SWIFT_VERSION = 5.0;
				TARGETED_DEVICE_FAMILY = "1,2";
				TEST_HOST = "$(BUILT_PRODUCTS_DIR)/SimpleWineManager.app/$(BUNDLE_EXECUTABLE_FOLDER_PATH)/SimpleWineManager";
			};
			name = Debug;
		};
		8A1B51D42B4D2A9200CDD208 /* Release */ = {
			isa = XCBuildConfiguration;
			buildSettings = {
				BUNDLE_LOADER = "$(TEST_HOST)";
				CODE_SIGN_STYLE = Automatic;
				CURRENT_PROJECT_VERSION = 4;
				DEVELOPMENT_TEAM = C2HM9UNJ72;
				GENERATE_INFOPLIST_FILE = YES;
				IPHONEOS_DEPLOYMENT_TARGET = 17.0;
				MARKETING_VERSION = 2.3;
				PRODUCT_BUNDLE_IDENTIFIER = com.dieterlempen.SimpleWineManagerTests;
				PRODUCT_NAME = "$(TARGET_NAME)";
				SWIFT_EMIT_LOC_STRINGS = NO;
				SWIFT_VERSION = 5.0;
				TARGETED_DEVICE_FAMILY = "1,2";
				TEST_HOST = "$(BUILT_PRODUCTS_DIR)/SimpleWineManager.app/$(BUNDLE_EXECUTABLE_FOLDER_PATH)/SimpleWineManager";
			};
			name = Release;
		};
		8A1B51D62B4D2A9200CDD208 /* Debug */ = {
			isa = XCBuildConfiguration;
			buildSettings = {
				CODE_SIGN_STYLE = Automatic;
				CURRENT_PROJECT_VERSION = 4;
				DEVELOPMENT_TEAM = C2HM9UNJ72;
				GENERATE_INFOPLIST_FILE = YES;
				MARKETING_VERSION = 2.3;
				PRODUCT_BUNDLE_IDENTIFIER = com.dieterlempen.SimpleWineManagerUITests;
				PRODUCT_NAME = "$(TARGET_NAME)";
				SWIFT_EMIT_LOC_STRINGS = NO;
				SWIFT_VERSION = 5.0;
				TARGETED_DEVICE_FAMILY = "1,2";
				TEST_TARGET_NAME = SimpleWineManager;
			};
			name = Debug;
		};
		8A1B51D72B4D2A9200CDD208 /* Release */ = {
			isa = XCBuildConfiguration;
			buildSettings = {
				CODE_SIGN_STYLE = Automatic;
				CURRENT_PROJECT_VERSION = 4;
				DEVELOPMENT_TEAM = C2HM9UNJ72;
				GENERATE_INFOPLIST_FILE = YES;
				MARKETING_VERSION = 2.3;
				PRODUCT_BUNDLE_IDENTIFIER = com.dieterlempen.SimpleWineManagerUITests;
				PRODUCT_NAME = "$(TARGET_NAME)";
				SWIFT_EMIT_LOC_STRINGS = NO;
				SWIFT_VERSION = 5.0;
				TARGETED_DEVICE_FAMILY = "1,2";
				TEST_TARGET_NAME = SimpleWineManager;
			};
			name = Release;
		};
/* End XCBuildConfiguration section */

/* Begin XCConfigurationList section */
		8A1B51A12B4D2A8E00CDD208 /* Build configuration list for PBXProject "SimpleWineManager" */ = {
			isa = XCConfigurationList;
			buildConfigurations = (
				8A1B51CD2B4D2A9200CDD208 /* Debug */,
				8A1B51CE2B4D2A9200CDD208 /* Release */,
			);
			defaultConfigurationIsVisible = 0;
			defaultConfigurationName = Release;
		};
		8A1B51CF2B4D2A9200CDD208 /* Build configuration list for PBXNativeTarget "SimpleWineManager" */ = {
			isa = XCConfigurationList;
			buildConfigurations = (
				8A1B51D02B4D2A9200CDD208 /* Debug */,
				8A1B51D12B4D2A9200CDD208 /* Release */,
			);
			defaultConfigurationIsVisible = 0;
			defaultConfigurationName = Release;
		};
		8A1B51D22B4D2A9200CDD208 /* Build configuration list for PBXNativeTarget "SimpleWineManagerTests" */ = {
			isa = XCConfigurationList;
			buildConfigurations = (
				8A1B51D32B4D2A9200CDD208 /* Debug */,
				8A1B51D42B4D2A9200CDD208 /* Release */,
			);
			defaultConfigurationIsVisible = 0;
			defaultConfigurationName = Release;
		};
		8A1B51D52B4D2A9200CDD208 /* Build configuration list for PBXNativeTarget "SimpleWineManagerUITests" */ = {
			isa = XCConfigurationList;
			buildConfigurations = (
				8A1B51D62B4D2A9200CDD208 /* Debug */,
				8A1B51D72B4D2A9200CDD208 /* Release */,
			);
			defaultConfigurationIsVisible = 0;
			defaultConfigurationName = Release;
		};
/* End XCConfigurationList section */

/* Begin XCVersionGroup section */
		8A1B51B42B4D2A9100CDD208 /* SimpleWineManager.xcdatamodeld */ = {
			isa = XCVersionGroup;
			children = (
				8A1B51B52B4D2A9100CDD208 /* SimpleWineManager.xcdatamodel */,
			);
			currentVersion = 8A1B51B52B4D2A9100CDD208 /* SimpleWineManager.xcdatamodel */;
			path = SimpleWineManager.xcdatamodeld;
			sourceTree = "<group>";
			versionGroupType = wrapper.xcdatamodel;
		};
/* End XCVersionGroup section */
	};
	rootObject = 8A1B519E2B4D2A8E00CDD208 /* Project object */;
}
EOL

echo "✅ Project file created successfully"
echo ""
echo "📱 Project setup complete!"
echo ""
echo "🔥 Next steps:"
echo "1. Open the project in Xcode"
echo "2. Run a clean build"
echo "3. Commit your changes"
echo ""
echo "📋 Note: This script creates a standard Xcode project format with v2.3 version number."
echo "   Your existing source files will be recognized automatically by the project file."
echo ""
