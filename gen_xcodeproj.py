#!/usr/bin/env python3
"""
Generates RUMSimulator.xcodeproj/project.pbxproj
Run from the iOS-swift directory: python3 gen_xcodeproj.py
"""

import os, uuid, hashlib

ROOT = os.path.dirname(os.path.abspath(__file__))
PROJ_NAME = "RUMSimulator"
SRC_ROOT  = os.path.join(ROOT, PROJ_NAME)

def pbx_id(name: str) -> str:
    """Deterministic 24-hex PBX ID from a string."""
    h = hashlib.md5(name.encode()).hexdigest().upper()
    return h[:24]

# ── Collect all source files ────────────────────────────────────────────────

SWIFT_FILES   = []
RESOURCE_FILES = []

for dirpath, dirnames, filenames in os.walk(SRC_ROOT):
    dirnames.sort()
    for fn in sorted(filenames):
        rel = os.path.relpath(os.path.join(dirpath, fn), SRC_ROOT)
        if fn.endswith(".swift"):
            SWIFT_FILES.append(rel)
        elif fn.endswith(".plist") or fn.endswith(".xcassets"):
            RESOURCE_FILES.append(rel)

# Also include top-level Info.plist explicitly
# (already included via walk)

print(f"Found {len(SWIFT_FILES)} Swift files, {len(len(RESOURCE_FILES) and RESOURCE_FILES or [])} resource files")

# ── IDs ─────────────────────────────────────────────────────────────────────

PROJECT_ID    = pbx_id("PROJECT_ROOT")
TARGET_ID     = pbx_id("NATIVE_TARGET")
NATIVE_PROXY  = pbx_id("NATIVE_PROXY")

BUILD_CONFIG_LIST_PROJ   = pbx_id("BUILD_CONFIG_LIST_PROJ")
BUILD_CONFIG_LIST_TARGET = pbx_id("BUILD_CONFIG_LIST_TARGET")

BUILD_CONFIG_DEBUG_PROJ   = pbx_id("BUILD_CONFIG_DEBUG_PROJ")
BUILD_CONFIG_RELEASE_PROJ = pbx_id("BUILD_CONFIG_RELEASE_PROJ")
BUILD_CONFIG_DEBUG_TGT    = pbx_id("BUILD_CONFIG_DEBUG_TGT")
BUILD_CONFIG_RELEASE_TGT  = pbx_id("BUILD_CONFIG_RELEASE_TGT")

SOURCES_PHASE_ID   = pbx_id("SOURCES_PHASE")
RESOURCES_PHASE_ID = pbx_id("RESOURCES_PHASE")
FRAMEWORKS_PHASE_ID = pbx_id("FRAMEWORKS_PHASE")

MAIN_GROUP_ID   = pbx_id("MAIN_GROUP")
PRODUCTS_GROUP  = pbx_id("PRODUCTS_GROUP")
SRC_GROUP_ID    = pbx_id("SRC_GROUP")

APP_PRODUCT_REF = pbx_id("APP_PRODUCT")

# File refs
def file_ref_id(path):    return pbx_id("FILEREF_" + path)
def build_file_id(path):  return pbx_id("BUILDFILE_" + path)
def group_id(path):       return pbx_id("GROUP_" + path)

# ── Build file entries ───────────────────────────────────────────────────────

def pbx_build_files():
    lines = ["/* Begin PBXBuildFile section */"]
    for f in SWIFT_FILES:
        bid = build_file_id(f)
        fid = file_ref_id(f)
        name = os.path.basename(f)
        lines.append(f"\t\t{bid} /* {name} in Sources */ = {{isa = PBXBuildFile; fileRef = {fid} /* {name} */; }};")
    for f in RESOURCE_FILES:
        bid = build_file_id("RES_" + f)
        fid = file_ref_id(f)
        name = os.path.basename(f)
        lines.append(f"\t\t{bid} /* {name} in Resources */ = {{isa = PBXBuildFile; fileRef = {fid} /* {name} */; }};")
    lines.append("/* End PBXBuildFile section */")
    return "\n".join(lines)

# ── File references ──────────────────────────────────────────────────────────

def last_known_type(path):
    if path.endswith(".swift"):     return "sourcecode.swift"
    if path.endswith(".plist"):     return "text.plist.xml"
    if path.endswith(".storyboard"): return "file.storyboard"
    if path.endswith(".xcassets"): return "folder.assetcatalog"
    return "text"

def pbx_file_references():
    lines = ["/* Begin PBXFileReference section */"]
    # App product
    lines.append(f"\t\t{APP_PRODUCT_REF} /* {PROJ_NAME}.app */ = {{isa = PBXFileReference; explicitFileType = wrapper.application; includeInIndex = 0; path = {PROJ_NAME}.app; sourceTree = BUILT_PRODUCTS_DIR; }};")
    for f in SWIFT_FILES + RESOURCE_FILES:
        fid  = file_ref_id(f)
        name = os.path.basename(f)
        lkt  = last_known_type(f)
        # Path relative to group (we'll set sourceTree to SOURCE_ROOT and use full rel path)
        lines.append(f"\t\t{fid} /* {name} */ = {{isa = PBXFileReference; lastKnownFileType = {lkt}; name = {name}; path = {PROJ_NAME}/{f}; sourceTree = \"<group>\"; }};")
    lines.append("/* End PBXFileReference section */")
    return "\n".join(lines)

# ── Groups (flat — all files under RUMSimulator group) ───────────────────────

def build_group_tree():
    """Build nested group structure mirroring the folder hierarchy."""
    # Collect unique directory paths
    dirs = set()
    for f in SWIFT_FILES + RESOURCE_FILES:
        parts = f.split(os.sep)
        for i in range(1, len(parts)):
            dirs.add(os.sep.join(parts[:i]))
    dirs = sorted(dirs)

    # dir -> list of direct children (files and subdirs)
    dir_children = {}   # dir -> [rel_paths]
    root_children = []  # top-level items

    for f in SWIFT_FILES + RESOURCE_FILES:
        parts = f.split(os.sep)
        if len(parts) == 1:
            root_children.append(("file", f))
        else:
            parent = parts[0]
            if parent not in dir_children:
                dir_children[parent] = []
            dir_children[parent].append(("file", f))

    for d in dirs:
        parts = d.split(os.sep)
        if len(parts) == 1:
            root_children.append(("dir", d))
            # remove duplicate file entries already added
        elif len(parts) == 2:
            parent = parts[0]
            if parent not in dir_children:
                dir_children[parent] = []
            dir_children[parent].append(("dir", d))

    return root_children, dir_children, dirs

def pbx_groups():
    root_children, dir_children, dirs = build_group_tree()

    lines = ["/* Begin PBXGroup section */"]

    # Main group
    lines.append(f"\t\t{MAIN_GROUP_ID} = {{")
    lines.append(f"\t\t\tisa = PBXGroup;")
    lines.append(f"\t\t\tchildren = (")
    lines.append(f"\t\t\t\t{SRC_GROUP_ID} /* {PROJ_NAME} */,")
    lines.append(f"\t\t\t\t{PRODUCTS_GROUP} /* Products */,")
    lines.append(f"\t\t\t);")
    lines.append(f"\t\t\tsourceTree = \"<group>\";")
    lines.append(f"\t\t}};")

    # Products group
    lines.append(f"\t\t{PRODUCTS_GROUP} /* Products */ = {{")
    lines.append(f"\t\t\tisa = PBXGroup;")
    lines.append(f"\t\t\tchildren = (")
    lines.append(f"\t\t\t\t{APP_PRODUCT_REF} /* {PROJ_NAME}.app */,")
    lines.append(f"\t\t\t);")
    lines.append(f"\t\t\tname = Products;")
    lines.append(f"\t\t\tsourceTree = \"<group>\";")
    lines.append(f"\t\t}};")

    # RUMSimulator source group (top-level)
    top_level_dirs = sorted(set(f.split(os.sep)[0] for f in SWIFT_FILES + RESOURCE_FILES if os.sep in f))
    top_level_files = [f for f in SWIFT_FILES + RESOURCE_FILES if os.sep not in f]

    lines.append(f"\t\t{SRC_GROUP_ID} /* {PROJ_NAME} */ = {{")
    lines.append(f"\t\t\tisa = PBXGroup;")
    lines.append(f"\t\t\tchildren = (")
    for d in top_level_dirs:
        lines.append(f"\t\t\t\t{group_id(d)} /* {d} */,")
    for f in top_level_files:
        lines.append(f"\t\t\t\t{file_ref_id(f)} /* {os.path.basename(f)} */,")
    lines.append(f"\t\t\t);")
    lines.append(f"\t\t\tname = {PROJ_NAME};")
    lines.append(f"\t\t\tpath = {PROJ_NAME};")
    lines.append(f"\t\t\tsourceTree = \"<group>\";")
    lines.append(f"\t\t}};")

    # Sub-groups
    for d in sorted(top_level_dirs):
        gid = group_id(d)
        dname = os.path.basename(d)
        # Children: sub-dirs + files directly in this dir
        sub_dirs  = sorted(set(f.split(os.sep)[1] for f in SWIFT_FILES + RESOURCE_FILES
                          if f.startswith(d + os.sep) and f.count(os.sep) == 2))
        files_in_dir = [f for f in SWIFT_FILES + RESOURCE_FILES
                        if os.path.dirname(f) == d]
        lines.append(f"\t\t{gid} /* {dname} */ = {{")
        lines.append(f"\t\t\tisa = PBXGroup;")
        lines.append(f"\t\t\tchildren = (")
        for sd in sub_dirs:
            sub_path = d + os.sep + sd
            lines.append(f"\t\t\t\t{group_id(sub_path)} /* {sd} */,")
        for f in files_in_dir:
            lines.append(f"\t\t\t\t{file_ref_id(f)} /* {os.path.basename(f)} */,")
        lines.append(f"\t\t\t);")
        lines.append(f"\t\t\tname = {dname};")
        lines.append(f"\t\t\tsourceTree = \"<group>\";")
        lines.append(f"\t\t}};")

    # Sub-sub-groups (e.g. Screens/ControlPanel)
    for d in sorted(dirs):
        if d.count(os.sep) < 1: continue  # already handled top-level
        gid   = group_id(d)
        dname = os.path.basename(d)
        files_in_dir = [f for f in SWIFT_FILES + RESOURCE_FILES if os.path.dirname(f) == d]
        if not files_in_dir:
            continue
        lines.append(f"\t\t{gid} /* {dname} */ = {{")
        lines.append(f"\t\t\tisa = PBXGroup;")
        lines.append(f"\t\t\tchildren = (")
        for f in files_in_dir:
            lines.append(f"\t\t\t\t{file_ref_id(f)} /* {os.path.basename(f)} */,")
        lines.append(f"\t\t\t);")
        lines.append(f"\t\t\tname = {dname};")
        lines.append(f"\t\t\tsourceTree = \"<group>\";")
        lines.append(f"\t\t}};")

    lines.append("/* End PBXGroup section */")
    return "\n".join(lines)

# ── Build phases ─────────────────────────────────────────────────────────────

def pbx_sources_build_phase():
    lines = ["/* Begin PBXSourcesBuildPhase section */"]
    lines.append(f"\t\t{SOURCES_PHASE_ID} /* Sources */ = {{")
    lines.append(f"\t\t\tisa = PBXSourcesBuildPhase;")
    lines.append(f"\t\t\tbuildActionMask = 2147483647;")
    lines.append(f"\t\t\tfiles = (")
    for f in SWIFT_FILES:
        bid  = build_file_id(f)
        name = os.path.basename(f)
        lines.append(f"\t\t\t\t{bid} /* {name} in Sources */,")
    lines.append(f"\t\t\t);")
    lines.append(f"\t\t\trunOnlyForDeploymentPostprocessing = 0;")
    lines.append(f"\t\t}};")
    lines.append("/* End PBXSourcesBuildPhase section */")
    return "\n".join(lines)

def pbx_resources_build_phase():
    lines = ["/* Begin PBXResourcesBuildPhase section */"]
    lines.append(f"\t\t{RESOURCES_PHASE_ID} /* Resources */ = {{")
    lines.append(f"\t\t\tisa = PBXResourcesBuildPhase;")
    lines.append(f"\t\t\tbuildActionMask = 2147483647;")
    lines.append(f"\t\t\tfiles = (")
    for f in RESOURCE_FILES:
        bid  = build_file_id("RES_" + f)
        name = os.path.basename(f)
        lines.append(f"\t\t\t\t{bid} /* {name} in Resources */,")
    lines.append(f"\t\t\t);")
    lines.append(f"\t\t\trunOnlyForDeploymentPostprocessing = 0;")
    lines.append(f"\t\t}};")
    lines.append("/* End PBXResourcesBuildPhase section */")
    return "\n".join(lines)

def pbx_frameworks_build_phase():
    lines = ["/* Begin PBXFrameworksBuildPhase section */"]
    lines.append(f"\t\t{FRAMEWORKS_PHASE_ID} /* Frameworks */ = {{")
    lines.append(f"\t\t\tisa = PBXFrameworksBuildPhase;")
    lines.append(f"\t\t\tbuildActionMask = 2147483647;")
    lines.append(f"\t\t\tfiles = (")
    lines.append(f"\t\t\t);")
    lines.append(f"\t\t\trunOnlyForDeploymentPostprocessing = 0;")
    lines.append(f"\t\t}};")
    lines.append("/* End PBXFrameworksBuildPhase section */")
    return "\n".join(lines)

# ── Native target ────────────────────────────────────────────────────────────

def pbx_native_target():
    return f"""/* Begin PBXNativeTarget section */
\t\t{TARGET_ID} /* {PROJ_NAME} */ = {{
\t\t\tisa = PBXNativeTarget;
\t\t\tbuildConfigurationList = {BUILD_CONFIG_LIST_TARGET} /* Build configuration list for PBXNativeTarget "{PROJ_NAME}" */;
\t\t\tbuildPhases = (
\t\t\t\t{SOURCES_PHASE_ID} /* Sources */,
\t\t\t\t{RESOURCES_PHASE_ID} /* Resources */,
\t\t\t\t{FRAMEWORKS_PHASE_ID} /* Frameworks */,
\t\t\t);
\t\t\tbuildRules = (
\t\t\t);
\t\t\tdependencies = (
\t\t\t);
\t\t\tname = {PROJ_NAME};
\t\t\tproductName = {PROJ_NAME};
\t\t\tproductReference = {APP_PRODUCT_REF} /* {PROJ_NAME}.app */;
\t\t\tproductType = "com.apple.product-type.application";
\t\t}};
/* End PBXNativeTarget section */"""

# ── Project object ───────────────────────────────────────────────────────────

def pbx_project():
    return f"""/* Begin PBXProject section */
\t\t{PROJECT_ID} /* Project object */ = {{
\t\t\tisa = PBXProject;
\t\t\tattributes = {{
\t\t\t\tBuildIndependentTargetsInParallel = 1;
\t\t\t\tLastUpgradeCheck = 1500;
\t\t\t\tTargetAttributes = {{
\t\t\t\t\t{TARGET_ID} = {{
\t\t\t\t\t\tCreatedOnToolsVersion = 15.0;
\t\t\t\t\t}};
\t\t\t\t}};
\t\t\t}};
\t\t\tbuildConfigurationList = {BUILD_CONFIG_LIST_PROJ} /* Build configuration list for PBXProject "{PROJ_NAME}" */;
\t\t\tcompatibilityVersion = "Xcode 14.0";
\t\t\tdevelopmentRegion = en;
\t\t\thasScannedForEncodings = 0;
\t\t\tknownRegions = (
\t\t\t\ten,
\t\t\t\tBase,
\t\t\t);
\t\t\tmainGroup = {MAIN_GROUP_ID};
\t\t\tproductRefGroup = {PRODUCTS_GROUP} /* Products */;
\t\t\tprojectDirPath = "";
\t\t\tprojectRoot = "";
\t\t\ttargets = (
\t\t\t\t{TARGET_ID} /* {PROJ_NAME} */,
\t\t\t);
\t\t}};
/* End PBXProject section */"""

# ── Build configurations ─────────────────────────────────────────────────────

COMMON_SETTINGS = """
\t\t\t\tALWAYS_SEARCH_USER_PATHS = NO;
\t\t\t\tCLANG_ANALYZER_NONNULL = YES;
\t\t\t\tCLANG_ANALYZER_NUMBER_OBJECT_CONVERSION = YES_AGGRESSIVE;
\t\t\t\tCLANG_CXX_LANGUAGE_STANDARD = "gnu++17";
\t\t\t\tCLANG_ENABLE_MODULES = YES;
\t\t\t\tCLANG_ENABLE_OBJC_ARC = YES;
\t\t\t\tCLANG_ENABLE_OBJC_WEAK = YES;
\t\t\t\tCLANG_WARN__DUPLICATE_METHOD_MATCH = YES;
\t\t\t\tCOPY_PHASE_STRIP = NO;
\t\t\t\tENABLE_STRICT_OBJC_MSGSEND = YES;
\t\t\t\tGCC_C_LANGUAGE_STANDARD = gnu11;
\t\t\t\tGCC_WARN_ABOUT_RETURN_TYPE = YES_ERROR;
\t\t\t\tGCC_WARN_UNINITIALIZED_AUTOS = YES_AGGRESSIVE;
\t\t\t\tGCC_WARN_UNUSED_FUNCTION = YES;
\t\t\t\tGCC_WARN_UNUSED_VARIABLE = YES;
\t\t\t\tIPHONEOS_DEPLOYMENT_TARGET = 16.0;
\t\t\t\tMTL_ENABLE_DEBUG_INFO = INCLUDE_SOURCE;
\t\t\t\tONLY_ACTIVE_ARCH = YES;
\t\t\t\tSDKROOT = iphoneos;
\t\t\t\tSUPPORTED_PLATFORMS = "iphonesimulator iphoneos";
\t\t\t\tTARGETED_DEVICE_FAMILY = "1,2";
\t\t\t\tSWIFT_ACTIVE_COMPILATION_CONDITIONS = DEBUG;
\t\t\t\tSWIFT_OPTIMIZATION_LEVEL = "-Onone";"""

def pbx_build_configurations():
    p = PROJ_NAME
    lines = ["/* Begin XCBuildConfiguration section */"]

    # Project Debug
    lines.append(f"\t\t{BUILD_CONFIG_DEBUG_PROJ} /* Debug */ = {{")
    lines.append(f"\t\t\tisa = XCBuildConfiguration;")
    lines.append(f"\t\t\tbuildSettings = {{{COMMON_SETTINGS}")
    lines.append(f"\t\t\t}};")
    lines.append(f"\t\t\tname = Debug;")
    lines.append(f"\t\t}};")

    # Project Release
    lines.append(f"\t\t{BUILD_CONFIG_RELEASE_PROJ} /* Release */ = {{")
    lines.append(f"\t\t\tisa = XCBuildConfiguration;")
    lines.append(f"\t\t\tbuildSettings = {{")
    lines.append(f"\t\t\t\tIPHONEOS_DEPLOYMENT_TARGET = 16.0;")
    lines.append(f"\t\t\t\tSDKROOT = iphoneos;")
    lines.append(f"\t\t\t\tSUPPORTED_PLATFORMS = \"iphonesimulator iphoneos\";")
    lines.append(f"\t\t\t\tTARGETED_DEVICE_FAMILY = \"1,2\";")
    lines.append(f"\t\t\t\tSWIFT_OPTIMIZATION_LEVEL = \"-O\";")
    lines.append(f"\t\t\t}};")
    lines.append(f"\t\t\tname = Release;")
    lines.append(f"\t\t}};")

    # Target Debug
    lines.append(f"\t\t{BUILD_CONFIG_DEBUG_TGT} /* Debug */ = {{")
    lines.append(f"\t\t\tisa = XCBuildConfiguration;")
    lines.append(f"\t\t\tbuildSettings = {{")
    lines.append(f"\t\t\t\tASSTCAT_COMPILER_SKIP_APP_STORE_DEPLOYMENT = YES;")
    lines.append(f"\t\t\t\tCODE_SIGN_STYLE = Automatic;")
    lines.append(f"\t\t\t\tCURRENT_PROJECT_VERSION = 1;")
    lines.append(f"\t\t\t\tDEVELOPMENT_ASSET_PATHS = \"\";")
    lines.append(f"\t\t\t\tENABLE_PREVIEWS = YES;")
    lines.append(f"\t\t\t\tGENERATE_INFOPLIST_FILE = NO;")
    lines.append(f"\t\t\t\tINFOPLIST_FILE = \"{p}/Info.plist\";")
    lines.append(f"\t\t\t\tIPHONEOS_DEPLOYMENT_TARGET = 16.0;")
    lines.append(f"\t\t\t\tMARKETING_VERSION = 1.0;")
    lines.append(f"\t\t\t\tPRODUCT_BUNDLE_IDENTIFIER = \"com.rumsimulator.{p}\";")
    lines.append(f"\t\t\t\tPRODUCT_NAME = \"$(TARGET_NAME)\";")
    lines.append(f"\t\t\t\tSDKROOT = iphoneos;")
    lines.append(f"\t\t\t\tSUPPORTED_PLATFORMS = \"iphonesimulator iphoneos\";")
    lines.append(f"\t\t\t\tSWIFT_VERSION = 5.0;")
    lines.append(f"\t\t\t\tTARGETED_DEVICE_FAMILY = \"1,2\";")
    lines.append(f"\t\t\t}};")
    lines.append(f"\t\t\tname = Debug;")
    lines.append(f"\t\t}};")

    # Target Release
    lines.append(f"\t\t{BUILD_CONFIG_RELEASE_TGT} /* Release */ = {{")
    lines.append(f"\t\t\tisa = XCBuildConfiguration;")
    lines.append(f"\t\t\tbuildSettings = {{")
    lines.append(f"\t\t\t\tCODE_SIGN_STYLE = Automatic;")
    lines.append(f"\t\t\t\tCURRENT_PROJECT_VERSION = 1;")
    lines.append(f"\t\t\t\tENABLE_PREVIEWS = YES;")
    lines.append(f"\t\t\t\tGENERATE_INFOPLIST_FILE = NO;")
    lines.append(f"\t\t\t\tINFOPLIST_FILE = \"{p}/Info.plist\";")
    lines.append(f"\t\t\t\tIPHONEOS_DEPLOYMENT_TARGET = 16.0;")
    lines.append(f"\t\t\t\tMARKETING_VERSION = 1.0;")
    lines.append(f"\t\t\t\tPRODUCT_BUNDLE_IDENTIFIER = \"com.rumsimulator.{p}\";")
    lines.append(f"\t\t\t\tPRODUCT_NAME = \"$(TARGET_NAME)\";")
    lines.append(f"\t\t\t\tSDKROOT = iphoneos;")
    lines.append(f"\t\t\t\tSUPPORTED_PLATFORMS = \"iphonesimulator iphoneos\";")
    lines.append(f"\t\t\t\tSWIFT_OPTIMIZATION_LEVEL = \"-O\";")
    lines.append(f"\t\t\t\tSWIFT_VERSION = 5.0;")
    lines.append(f"\t\t\t\tTARGETED_DEVICE_FAMILY = \"1,2\";")
    lines.append(f"\t\t\t}};")
    lines.append(f"\t\t\tname = Release;")
    lines.append(f"\t\t}};")

    lines.append("/* End XCBuildConfiguration section */")
    return "\n".join(lines)

def pbx_config_lists():
    p = PROJ_NAME
    return f"""/* Begin XCConfigurationList section */
\t\t{BUILD_CONFIG_LIST_PROJ} /* Build configuration list for PBXProject "{p}" */ = {{
\t\t\tisa = XCConfigurationList;
\t\t\tbuildConfigurations = (
\t\t\t\t{BUILD_CONFIG_DEBUG_PROJ} /* Debug */,
\t\t\t\t{BUILD_CONFIG_RELEASE_PROJ} /* Release */,
\t\t\t);
\t\t\tdefaultConfigurationIsVisible = 0;
\t\t\tdefaultConfigurationName = Release;
\t\t}};
\t\t{BUILD_CONFIG_LIST_TARGET} /* Build configuration list for PBXNativeTarget "{p}" */ = {{
\t\t\tisa = XCConfigurationList;
\t\t\tbuildConfigurations = (
\t\t\t\t{BUILD_CONFIG_DEBUG_TGT} /* Debug */,
\t\t\t\t{BUILD_CONFIG_RELEASE_TGT} /* Release */,
\t\t\t);
\t\t\tdefaultConfigurationIsVisible = 0;
\t\t\tdefaultConfigurationName = Release;
\t\t}};
/* End XCConfigurationList section */"""

# ── Assemble ─────────────────────────────────────────────────────────────────

pbxproj = f"""// !$*UTF8*$!
{{
\tarchiveVersion = 1;
\tclasses = {{
\t}};
\tobjectVersion = 56;
\tobjects = {{

{pbx_build_files()}

{pbx_file_references()}

{pbx_frameworks_build_phase()}

{pbx_groups()}

{pbx_native_target()}

{pbx_project()}

{pbx_resources_build_phase()}

{pbx_sources_build_phase()}

{pbx_build_configurations()}

{pbx_config_lists()}

\t}};
\trootObject = {PROJECT_ID} /* Project object */;
}}
"""

# Write out
xcodeproj_dir = os.path.join(ROOT, f"{PROJ_NAME}.xcodeproj")
os.makedirs(xcodeproj_dir, exist_ok=True)
out_path = os.path.join(xcodeproj_dir, "project.pbxproj")
with open(out_path, "w") as f:
    f.write(pbxproj)

print(f"✅  Written: {out_path}")
print(f"   Swift files: {len(SWIFT_FILES)}")
print(f"   Resource files: {len(RESOURCE_FILES)}")
