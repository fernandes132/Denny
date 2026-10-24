#!/usr/bin/env python3
"""Deterministic, dependency-free Xcode project generation. Run only after adding/removing files."""
from pathlib import Path
import hashlib, json, plistlib, xml.etree.ElementTree as ET
ROOT = Path(__file__).resolve().parents[1]
objects = {}
def uid(label): return hashlib.sha1(label.encode()).hexdigest()[:24].upper()
def add(label, **fields):
    key = uid(label); objects[key] = fields; return key
def ref(path, kind):
    return add('file:'+path, isa='PBXFileReference', lastKnownFileType=kind, path=path, sourceTree='<group>')
def phase(label, kind, files):
    buildfiles=[add(label+':'+f, isa='PBXBuildFile', fileRef=f) for f in files]
    return add(label, isa=kind, buildActionMask='2147483647', files=buildfiles, runOnlyForDeploymentPostprocessing='0')
def configurations(label, settings):
    configs=[]
    for name in ['Debug','Release']:
        values=dict(settings)
        values['SWIFT_OPTIMIZATION_LEVEL']='-Onone' if name=='Debug' else '-O'
        values['DEBUG_INFORMATION_FORMAT']='dwarf' if name=='Debug' else 'dwarf-with-dsym'
        if name=='Debug': values['ENABLE_TESTABILITY']='YES'
        configs.append(add(label+name, isa='XCBuildConfiguration', buildSettings=values, name=name))
    return add(label+'list',isa='XCConfigurationList',buildConfigurations=configs,defaultConfigurationIsVisible='0',defaultConfigurationName='Release')
base_info={
 'CFBundleDevelopmentRegion':'nl','CFBundleDisplayName':'Luma','CFBundleExecutable':'$(EXECUTABLE_NAME)',
 'CFBundleIdentifier':'$(PRODUCT_BUNDLE_IDENTIFIER)','CFBundleInfoDictionaryVersion':'6.0',
 'CFBundleName':'$(PRODUCT_NAME)','CFBundlePackageType':'APPL',
 'CFBundleShortVersionString':'$(MARKETING_VERSION)','CFBundleVersion':'$(CURRENT_PROJECT_VERSION)',
 'LSRequiresIPhoneOS':True,'UILaunchScreen':{},'UIUserInterfaceStyle':'Dark',
 'UIApplicationSceneManifest':{'UIApplicationSupportsMultipleScenes':False},
 'UISupportedInterfaceOrientations':['UIInterfaceOrientationPortrait','UIInterfaceOrientationLandscapeLeft','UIInterfaceOrientationLandscapeRight'],
 'UISupportedInterfaceOrientations~ipad':['UIInterfaceOrientationPortrait','UIInterfaceOrientationPortraitUpsideDown','UIInterfaceOrientationLandscapeLeft','UIInterfaceOrientationLandscapeRight']}
cp_info=dict(base_info)
cp_info['UIApplicationSceneManifest']={'UIApplicationSupportsMultipleScenes':True,'UISceneConfigurations':{
 'CPTemplateApplicationSceneSessionRoleApplication':[{'UISceneClassName':'CPTemplateApplicationScene','UISceneConfigurationName':'Luma CarPlay','UISceneDelegateClassName':'$(PRODUCT_MODULE_NAME).CarPlaySceneDelegate'}]}}
# Only the optional native CarPlay test may keep an audio session active; never extract YouTube audio.
cp_info['UIBackgroundModes']=['audio']
for name,info in [('Info.plist',base_info),('Info-CarPlay.plist',cp_info)]:
 (ROOT/'Luma'/name).write_bytes(plistlib.dumps(info,sort_keys=False))
privacy={'NSPrivacyTracking':False,'NSPrivacyTrackingDomains':[], 'NSPrivacyCollectedDataTypes':[],
 'NSPrivacyAccessedAPITypes':[{'NSPrivacyAccessedAPIType':'NSPrivacyAccessedAPICategoryUserDefaults','NSPrivacyAccessedAPITypeReasons':['CA92.1']}]}
(ROOT/'Luma/Resources/PrivacyInfo.xcprivacy').write_bytes(plistlib.dumps(privacy))
swift_files=sorted(p.relative_to(ROOT).as_posix() for p in (ROOT/'Luma').rglob('*.swift'))
sources=[ref(p,'sourcecode.swift') for p in swift_files]
resources=[ref('Luma/Resources/Assets.xcassets','folder.assetcatalog'),ref('Luma/Resources/YouTubePlayer.html','text.html'),ref('Luma/Resources/PrivacyInfo.xcprivacy','text.xml')]
others=[ref('Luma/Info.plist','text.plist.xml'),ref('Luma/Info-CarPlay.plist','text.plist.xml'),ref('Luma/CarPlay/CarPlay.entitlements','text.plist.entitlements')]
test_refs=[ref(p.relative_to(ROOT).as_posix(),'sourcecode.swift') for p in sorted((ROOT/'LumaTests').glob('*.swift'))]
product_refs=[]; targets=[]
common={'SDKROOT':'iphoneos','SWIFT_VERSION':'5.0','IPHONEOS_DEPLOYMENT_TARGET':'17.0',
 'CLANG_ENABLE_MODULES':'YES','CLANG_ENABLE_OBJC_ARC':'YES','CODE_SIGN_STYLE':'Automatic',
 'TARGETED_DEVICE_FAMILY':'1,2','SUPPORTED_PLATFORMS':'iphoneos iphonesimulator',
 'SUPPORTS_MACCATALYST':'NO','MARKETING_VERSION':'1.1','CURRENT_PROJECT_VERSION':'2',
 'ASSETCATALOG_COMPILER_APPICON_NAME':'AppIcon','GENERATE_INFOPLIST_FILE':'NO',
 'LD_RUNPATH_SEARCH_PATHS':['$(inherited)','@executable_path/Frameworks'],
 'PRODUCT_MODULE_NAME':'Luma','SWIFT_EMIT_LOC_STRINGS':'YES'}
for name,carplay in [('Luma',False),('Luma-CarPlay',True)]:
    product=add(name+'product',isa='PBXFileReference',explicitFileType='wrapper.application',includeInIndex='0',path=name+'.app',sourceTree='BUILT_PRODUCTS_DIR')
    product_refs.append(product)
    settings=dict(common,PRODUCT_NAME=name,PRODUCT_BUNDLE_IDENTIFIER='nl.luma.pilot'+('.carplay' if carplay else ''),INFOPLIST_FILE='Luma/Info-CarPlay.plist' if carplay else 'Luma/Info.plist')
    if carplay:
        settings.update(IPHONEOS_DEPLOYMENT_TARGET='27.0',SWIFT_ACTIVE_COMPILATION_CONDITIONS='$(inherited) LUMA_CARPLAY',CODE_SIGN_ENTITLEMENTS='Luma/CarPlay/CarPlay.entitlements')
    phases=[phase(name+'sources','PBXSourcesBuildPhase',sources),phase(name+'frameworks','PBXFrameworksBuildPhase',[]),phase(name+'resources','PBXResourcesBuildPhase',resources)]
    targets.append(add('target:'+name,isa='PBXNativeTarget',buildConfigurationList=configurations(name,settings),buildPhases=phases,buildRules=[],dependencies=[],name=name,productName=name,productReference=product,productType='com.apple.product-type.application'))
project_id=uid('project')
proxy=add('proxy',isa='PBXContainerItemProxy',containerPortal=project_id,proxyType='1',remoteGlobalIDString=targets[0],remoteInfo='Luma')
dependency=add('testdependency',isa='PBXTargetDependency',target=targets[0],targetProxy=proxy)
test_product=add('testproduct',isa='PBXFileReference',explicitFileType='wrapper.cfbundle',includeInIndex='0',path='LumaTests.xctest',sourceTree='BUILT_PRODUCTS_DIR')
product_refs.append(test_product)
test_settings=dict(common,PRODUCT_NAME='$(TARGET_NAME)',PRODUCT_MODULE_NAME='LumaTests',PRODUCT_BUNDLE_IDENTIFIER='nl.luma.pilot.tests',GENERATE_INFOPLIST_FILE='YES',TEST_HOST='$(BUILT_PRODUCTS_DIR)/Luma.app/Luma',BUNDLE_LOADER='$(TEST_HOST)')
test_settings.pop('ASSETCATALOG_COMPILER_APPICON_NAME')
test_phases=[phase('testsources','PBXSourcesBuildPhase',test_refs),phase('testframeworks','PBXFrameworksBuildPhase',[]),phase('testresources','PBXResourcesBuildPhase',[])]
test_target=add('target:LumaTests',isa='PBXNativeTarget',buildConfigurationList=configurations('LumaTests',test_settings),buildPhases=test_phases,buildRules=[],dependencies=[dependency],name='LumaTests',productName='LumaTests',productReference=test_product,productType='com.apple.product-type.bundle.unit-test')
targets.append(test_target)
products=add('products',isa='PBXGroup',children=product_refs,name='Products',sourceTree='<group>')
main_group=add('main',isa='PBXGroup',children=sources+resources+others+test_refs+[products],sourceTree='<group>')
add('project',isa='PBXProject',attributes={'BuildIndependentTargetsInParallel':'YES','LastUpgradeCheck':'1600','TargetAttributes':{targets[0]:{'CreatedOnToolsVersion':'16.0'},targets[1]:{'CreatedOnToolsVersion':'27.0'},test_target:{'CreatedOnToolsVersion':'16.0','TestTargetID':targets[0]}}},buildConfigurationList=configurations('project',{'CLANG_ENABLE_MODULES':'YES','SWIFT_VERSION':'5.0','SDKROOT':'iphoneos'}),compatibilityVersion='Xcode 14.0',developmentRegion='nl',hasScannedForEncodings='0',knownRegions=['nl','en','Base'],mainGroup=main_group,productRefGroup=products,projectDirPath='',projectRoot='',targets=targets)
def encode(value, depth=0):
    if isinstance(value,dict): return '{\n'+'\n'.join('\t'*(depth+1)+json.dumps(k)+' = '+encode(v,depth+1)+';' for k,v in value.items())+'\n'+'\t'*depth+'}'
    if isinstance(value,list): return '('+', '.join(encode(x,depth) for x in value)+')'
    return json.dumps(str(value))
project=ROOT/'Luma.xcodeproj'; project.mkdir(exist_ok=True)
(project/'project.pbxproj').write_text('// !$*UTF8*$!\n'+encode({'archiveVersion':'1','classes':{},'objectVersion':'56','objects':objects,'rootObject':project_id})+'\n')
shared=project/'xcshareddata/xcschemes';shared.mkdir(parents=True,exist_ok=True)
for name,index in [('Luma',0),('Luma-CarPlay',1)]:
    scheme=ET.Element('Scheme',LastUpgradeVersion='1600',version='1.3')
    build=ET.SubElement(scheme,'BuildAction',parallelizeBuildables='YES',buildImplicitDependencies='YES')
    entries=ET.SubElement(build,'BuildActionEntries')
    def buildable(parent,target,filename): return ET.SubElement(parent,'BuildableReference',BuildableIdentifier='primary',BlueprintIdentifier=target,BuildableName=filename,BlueprintName=name if target==targets[index] else 'LumaTests',ReferencedContainer='container:Luma.xcodeproj')
    entry=ET.SubElement(entries,'BuildActionEntry',buildForTesting='YES',buildForRunning='YES',buildForProfiling='YES',buildForArchiving='YES',buildForAnalyzing='YES');buildable(entry,targets[index],name+'.app')
    test=ET.SubElement(scheme,'TestAction',buildConfiguration='Debug',selectedDebuggerIdentifier='Xcode.DebuggerFoundation.Debugger.LLDB',selectedLauncherIdentifier='Xcode.IDEFoundation.Launcher.LLDB',shouldUseLaunchSchemeArgsEnv='YES')
    testables=ET.SubElement(test,'Testables')
    if index==0:
        testable=ET.SubElement(testables,'TestableReference',skipped='NO',parallelizable='NO');buildable(testable,test_target,'LumaTests.xctest')
    launch=ET.SubElement(scheme,'LaunchAction',buildConfiguration='Debug',selectedDebuggerIdentifier='Xcode.DebuggerFoundation.Debugger.LLDB',selectedLauncherIdentifier='Xcode.IDEFoundation.Launcher.LLDB',launchStyle='0',useCustomWorkingDirectory='NO',ignoresPersistentStateOnLaunch='NO',debugDocumentVersioning='YES',debugServiceExtension='internal',allowLocationSimulation='YES')
    runnable=ET.SubElement(launch,'BuildableProductRunnable',runnableDebuggingMode='0');buildable(runnable,targets[index],name+'.app')
    profile=ET.SubElement(scheme,'ProfileAction',buildConfiguration='Release',shouldUseLaunchSchemeArgsEnv='YES',savedToolIdentifier='',useCustomWorkingDirectory='NO',debugDocumentVersioning='YES')
    runnable=ET.SubElement(profile,'BuildableProductRunnable',runnableDebuggingMode='0');buildable(runnable,targets[index],name+'.app')
    ET.SubElement(scheme,'AnalyzeAction',buildConfiguration='Debug');ET.SubElement(scheme,'ArchiveAction',buildConfiguration='Release',revealArchiveInOrganizer='YES')
    ET.indent(scheme)
    (shared/(name+'.xcscheme')).write_bytes(ET.tostring(scheme,encoding='utf-8',xml_declaration=True))
workspace=project/'project.xcworkspace'; workspace.mkdir(exist_ok=True)
(workspace/'contents.xcworkspacedata').write_text('<?xml version="1.0" encoding="UTF-8"?><Workspace version="1.0"><FileRef location="self:"></FileRef></Workspace>')
print(f'Generated {project.name}: {len(swift_files)} app source files, 2 app targets, 1 test target.')
