#!/usr/bin/env python3
"""Validate a real built CarPlay candidate, without claiming approval or signing."""
import plistlib
import sys
import zipfile
from verify_device_binary import verify

def verify_package(path):
    with zipfile.ZipFile(path) as archive:
        if archive.testzip() is not None:
            raise ValueError('CarPlay ZIP integrity check failed.')
        root='Payload/Luma-CarPlay.app/'
        info=plistlib.loads(archive.read(root+'Info.plist'))
        if info.get('CFBundleSupportedPlatforms') != ['iPhoneOS']:
            raise ValueError('Not a physical iOS device package.')
        if int(info.get('MinimumOSVersion','0').split('.')[0]) < 27:
            raise ValueError('CarPlay candidate must target iOS 27 or newer.')
        scenes=info.get('UIApplicationSceneManifest',{}).get('UISceneConfigurations',{}).get('CPTemplateApplicationSceneSessionRoleApplication',[])
        if not any(s.get('UISceneClassName')=='CPTemplateApplicationScene' and s.get('UISceneDelegateClassName')=='Luma.CarPlaySceneDelegate' for s in scenes):
            raise ValueError('CarPlay scene registration missing or unresolved.')
        verify(archive.read(root+info['CFBundleExecutable']))
        print('PASS: actual arm64 iOS package, iOS 27 minimum, resolved CarPlay scene registration.')
        print('This does not validate Apple approval, signing, car compatibility or YouTube playback.')

if __name__=='__main__':
    if len(sys.argv)!=2:
        raise SystemExit('Usage: verify_carplay_package.py <CarPlay IPA>')
    verify_package(sys.argv[1])
