#!/usr/bin/env python3
"""Source/package checks. These do NOT compile Swift or validate iOS behavior."""
from pathlib import Path
import json, plistlib, re, sys, xml.etree.ElementTree as ET
ROOT = Path(__file__).resolve().parents[1]
checks = 0
def check(value, message):
    global checks
    if not value: raise AssertionError(message)
    checks += 1

for path in ROOT.rglob('*.plist'):
    with path.open('rb') as f: plistlib.load(f)
    checks += 1
for path in ROOT.rglob('*.xcprivacy'):
    with path.open('rb') as f: plistlib.load(f)
    checks += 1
for path in ROOT.rglob('*.entitlements'):
    with path.open('rb') as f: plistlib.load(f)
    checks += 1
for path in ROOT.rglob('Contents.json'):
    data = json.loads(path.read_text())
    for item in data.get('images', []):
        if item.get('filename'): check((path.parent/item['filename']).is_file(), f'Missing asset {item}')
    checks += 1

base = plistlib.loads((ROOT/'Luma/Info.plist').read_bytes())
cp = plistlib.loads((ROOT/'Luma/Info-CarPlay.plist').read_bytes())
check('NSAllowsArbitraryLoads' not in str(base), 'No broad ATS bypass')
scene = cp['UIApplicationSceneManifest']['UISceneConfigurations']['CPTemplateApplicationSceneSessionRoleApplication'][0]
check(scene['UISceneClassName'] == 'CPTemplateApplicationScene', 'CarPlay scene class')
check(scene['UISceneDelegateClassName'].endswith('.CarPlaySceneDelegate'), 'CarPlay scene delegate')
entitlements=plistlib.loads((ROOT/'Luma/CarPlay/CarPlay.entitlements').read_bytes())
check(entitlements=={'com.apple.developer.carplay-video':True}, 'Only intended restricted entitlement')

try:
    from openstep_parser import OpenStepDecoder
    with (ROOT/'Luma.xcodeproj/project.pbxproj').open() as f: project=OpenStepDecoder.ParseFromFile(f)
    objects=project['objects']
    check(project['rootObject'] in objects,'Root project reference')
    for value in objects.values():
        if value.get('isa')=='PBXFileReference' and value.get('sourceTree')=='<group>':
            check((ROOT/value['path']).exists(),f'Missing project file {value["path"]}')
        if value.get('isa')=='PBXBuildFile': check(value['fileRef'] in objects,'Build file reference')
    targets=[x for x in objects.values() if x.get('isa')=='PBXNativeTarget']
    check({x['name'] for x in targets}=={'Luma','Luma-CarPlay','LumaTests'},'Expected targets')
    for target in targets:
        for phase in target['buildPhases']: check(phase in objects,'Build phase reference')
    # Verify every Swift source participates in BOTH app targets; tests only in their test target.
    source_paths={str(p.relative_to(ROOT)) for p in (ROOT/'Luma').rglob('*.swift')}
    for target in targets:
        paths=set()
        for phase_id in target['buildPhases']:
            phase=objects[phase_id]
            if phase['isa']=='PBXSourcesBuildPhase':
                for build_id in phase['files']: paths.add(objects[objects[build_id]['fileRef']]['path'])
        expected = {str(p.relative_to(ROOT)) for p in (ROOT/'LumaTests').glob('*.swift')} if target['name']=='LumaTests' else source_paths
        check(paths==expected,'Source membership '+target['name'])
    print('PASS: Xcode project syntax, target membership and referenced files.')
except ImportError:
    print('SKIP: Xcode project parser missing; pip install openstep-parser for structural parsing.')

for path in (ROOT/'Luma.xcodeproj/xcshareddata/xcschemes').glob('*.xcscheme'):
    ET.parse(path); checks += 1
try:
    from tree_sitter import Language, Parser
    import tree_sitter_swift
    parser=Parser(Language(tree_sitter_swift.language()))
    for path in ROOT.rglob('*.swift'):
        tree=parser.parse(path.read_bytes())
        check(not tree.root_node.has_error,f'Swift grammar error in {path}')
    print('PASS: Swift grammar for all app/test sources (not Apple SDK type checking).')
except ImportError:
    print('SKIP: optional Swift grammar parser; pip install tree-sitter tree-sitter-swift.')

swift='\n'.join(p.read_text() for p in (ROOT/'Luma').rglob('*.swift'))
check('NSAllowsArbitraryLoads' not in swift,'No runtime ATS override')
check('https://www.ziggogo.tv' in swift,'Official Ziggo destination')
print(f'PASS: {checks} source/package checks. Xcode build and device playback remain untested here.')
