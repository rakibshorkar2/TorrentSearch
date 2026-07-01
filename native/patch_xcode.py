#!/usr/bin/env python3
"""Patches the Xcode project to include TorrentFlowNativeService.swift."""

import os
import re
import uuid

PBXPROJ_PATH = os.path.join(
    os.path.dirname(__file__), '..', 'ios', 'Runner.xcodeproj', 'project.pbxproj')

SWIFT_FILE = ('TorrentFlowNativeService.swift', 'sourcecode.swift')


def generate_uuid():
    return uuid.uuid4().hex.upper()[:24]


def patch_xcode_project():
    with open(PBXPROJ_PATH, 'r', encoding='utf-8') as f:
        content = f.read()

    fname, file_type = SWIFT_FILE

    if f'/* {fname} */' in content:
        print(f"Already in project: {fname}")
        return

    # Locate Runner group and Sources phase
    group = re.search(r'([A-F0-9]{24})\s+/\*\s*Runner\s*\*/', content)
    phase = re.search(
        r'/\*\s*Begin PBXSourcesBuildPhase section.*?([A-F0-9]{24})\s+/\*\s*Sources\s*\*/',
        content, re.DOTALL)

    if not group or not phase:
        print("ERROR: Could not find Runner group or Sources phase")
        return

    group_id = group.group(1)
    phase_id = phase.group(1)
    ref_id = generate_uuid()
    file_id = generate_uuid()

    # Add PBXFileReference
    content = re.sub(
        r'(/\* End PBXFileReference section \*/)',
        f"""\t\t{ref_id} /* {fname} */ = {{
\t\t\tisa = PBXFileReference;
\t\t\tlastKnownFileType = {file_type};
\t\t\tname = "{fname}";
\t\t\tpath = "{fname}";
\t\t\tsourceTree = "<group>";
\t\t}};
\\1""", content, count=1)

    # Add PBXBuildFile
    content = re.sub(
        r'(/\* End PBXBuildFile section \*/)',
        f"""\t\t{file_id} /* {fname} in Sources */ = {{
\t\t\tisa = PBXBuildFile;
\t\t\tfileRef = {ref_id} /* {fname} */;
\t\t}};
\\1""", content, count=1)

    # Add to Runner group children
    content = re.sub(
        rf'({group_id}\s+/\*\s*Runner\s*\*/.*?children\s*=\s*\()',
        lambda m: m.group(1) + f'\n\t\t\t\t{ref_id} /* {fname} */,',
        content, count=1, flags=re.DOTALL)

    # Add to Sources build phase files
    content = re.sub(
        rf'({phase_id}\s+/\*\s*Sources\s*\*/.*?files\s*=\s*\()',
        lambda m: m.group(1) + f'\n\t\t\t\t{file_id} /* {fname} in Sources */,',
        content, count=1, flags=re.DOTALL)

    with open(PBXPROJ_PATH, 'w', encoding='utf-8') as f:
        f.write(content)

    print(f"Added {fname} to Xcode project")


if __name__ == '__main__':
    print("Patching Xcode project...")
    patch_xcode_project()
    print("Done!")
