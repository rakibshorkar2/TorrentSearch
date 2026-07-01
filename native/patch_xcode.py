#!/usr/bin/env python3
"""Patches the Xcode project to include C++ native engine sources."""

import plistlib
import os
import shutil
import uuid

PROJECT_DIR = os.path.join(os.path.dirname(__file__), '..', 'ios', 'Runner.xcodeproj')
PBXPROJ_PATH = os.path.join(PROJECT_DIR, 'project.pbxproj')
NATIVE_SRC_DIR = os.path.join(os.path.dirname(__file__), 'torrent_engine', 'src')
NATIVE_DST_DIR = os.path.join(os.path.dirname(__file__), '..', 'ios', 'Runner', 'native')

def generate_uuid():
    return uuid.uuid4().hex.upper()[:24]

def patch_xcode_project():
    """Adds C++ source files to the Xcode project's Compile Sources phase."""

    # Read the current pbxproj
    with open(PBXPROJ_PATH, 'rb') as f:
        data = f.read()

    # Parse as plist
    try:
        plist = plistlib.loads(data)
    except:
        # Old-style pbxproj format - use regex fallback
        return patch_xcode_project_text()

    return patch_xcode_project_plist(plist)

def patch_xcode_project_text():
    """Patch pbxproj using regex for old format."""
    with open(PBXPROJ_PATH, 'r', encoding='utf-8') as f:
        content = f.read()

    # Copy C++ source files to ios/Runner/native/
    os.makedirs(NATIVE_DST_DIR, exist_ok=True)
    for fname in os.listdir(NATIVE_SRC_DIR):
        if fname.endswith('.cpp'):
            shutil.copy2(os.path.join(NATIVE_SRC_DIR, fname), os.path.join(NATIVE_DST_DIR, fname))

    # Check if native sources are already referenced
    if 'native/torrent_engine.cpp' in content or 'native/sha1.cpp' in content:
        print("C++ sources already in Xcode project")
        return

    # Find the main group and build phase
    import re

    # Find PBXBuildFile section
    build_file_id = generate_uuid()
    file_ref_ids = {}
    build_phase_id = None

    # Find main build phase
    phase_match = re.search(r'/* Begin PBXSourcesBuildPhase section \*/(.*?)/\* End PBXSourcesBuildPhase section \*/',
                            content, re.DOTALL)
    if phase_match:
        phase_section = phase_match.group(1)
        first_phase = re.search(r'([A-F0-9]{24})\s*/\*\s*Sources\s*\*/', phase_section)
        if first_phase:
            build_phase_id = first_phase.group(1)

    # Find main group ID for ios/Runner
    group_id = None
    group_match = re.search(r'([A-F0-9]{24})\s*/\*\s*Runner\s*\*/', content)
    if group_match:
        group_id = group_match.group(1)

    if not build_phase_id or not group_id:
        print("Could not find build phase or group - adding manually")
        return

    # Add each C++ file
    cpp_files = [f for f in os.listdir(NATIVE_SRC_DIR) if f.endswith('.cpp')]
    for fname in cpp_files:
        src_path = os.path.join(NATIVE_SRC_DIR, fname)
        dst_path = os.path.join(NATIVE_DST_DIR, fname)
        shutil.copy2(src_path, dst_path)

        ref_id = generate_uuid()
        file_id = generate_uuid()

        # Add file reference
        file_ref_entry = f"""\t\t{ref_id} /* native/{fname} */ = {{
\t\t\tisa = PBXFileReference;
\t\t\tlastKnownFileType = sourcecode.cpp.cpp;
\t\t\tname = "native/{fname}";
\t\t\tpath = "native/{fname}";
\t\t\tsourceTree = "<group>";
\t\t}};
"""
        # Add to build file
        build_file_entry = f"""\t\t{file_id} /* native/{fname} in Sources */ = {{
\t\t\tisa = PBXBuildFile;
\t\t\tfileRef = {ref_id} /* native/{fname} */;
\t\t}};
"""

        # Add to group (after group's children)
        children_pattern = rf'({group_id}\s*/\*\s*Runner\s*\*/.*?children\s*=\s*\()'
        content = re.sub(children_pattern,
                         lambda m: m.group(1) + f'\n\t\t\t\t{ref_id} /* native/{fname} */,',
                         content, count=1)

        # Add to build phase
        if build_phase_id:
            phase_pattern = rf'({build_phase_id}\s*/\*\s*Sources\s*\*/.*?files\s*=\s*\()'
            content = re.sub(phase_pattern,
                             lambda m: m.group(1) + f'\n\t\t\t\t{file_id} /* native/{fname} in Sources */,',
                             content, count=1)

        # Insert entries before end of respective sections
        content = re.sub(r'(/\* End PBXBuildFile section \*/)',
                         build_file_entry + r'\1',
                         content, count=1)
        content = re.sub(r'(/\* End PBXFileReference section \*/)',
                         file_ref_entry + r'\1',
                         content, count=1)

    with open(PBXPROJ_PATH, 'w', encoding='utf-8') as f:
        f.write(content)

    print(f"Added {len(cpp_files)} C++ source files to Xcode project")

def patch_xcode_project_plist(plist):
    """Patch using plist format (for newer Xcode)."""
    print("Using plist-based patch")

    objects = plist.get('objects', {})

    # Find main group
    runner_group_id = None
    for oid, obj in objects.items():
        if obj.get('path') == 'Runner' or obj.get('name') == 'Runner':
            if obj.get('isa') == 'PBXGroup':
                runner_group_id = oid
                break

    if not runner_group_id:
        print("Could not find Runner group")
        return

    # Find Sources build phase
    sources_phase_id = None
    for oid, obj in objects.items():
        if obj.get('isa') == 'PBXSourcesBuildPhase':
            sources_phase_id = oid
            break

    if not sources_phase_id:
        print("Could not find Sources build phase")
        return

    # Copy and add C++ files
    os.makedirs(NATIVE_DST_DIR, exist_ok=True)
    cpp_files = [f for f in os.listdir(NATIVE_SRC_DIR) if f.endswith('.cpp')]

    group_children = objects[runner_group_id].get('children', [])
    phase_files = objects[sources_phase_id].get('files', [])

    for fname in cpp_files:
        src_path = os.path.join(NATIVE_SRC_DIR, fname)
        dst_path = os.path.join(NATIVE_DST_DIR, fname)
        shutil.copy2(src_path, dst_path)

        ref_id = generate_uuid()
        file_id = generate_uuid()

        # Add file reference
        objects[ref_id] = {
            'isa': 'PBXFileReference',
            'lastKnownFileType': 'sourcecode.cpp.cpp',
            'name': f'native/{fname}',
            'path': f'native/{fname}',
            'sourceTree': '<group>',
        }
        group_children.append(ref_id)

        # Add build file
        objects[file_id] = {
            'isa': 'PBXBuildFile',
            'fileRef': ref_id,
        }
        phase_files.append(file_id)

    objects[runner_group_id]['children'] = group_children
    objects[sources_phase_id]['files'] = phase_files
    plist['objects'] = objects

    with open(PBXPROJ_PATH, 'wb') as f:
        plistlib.dump(plist, f)

    print(f"Added {len(cpp_files)} C++ source files to Xcode project")

if __name__ == '__main__':
    patch_xcode_project()
