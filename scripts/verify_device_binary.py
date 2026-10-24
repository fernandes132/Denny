#!/usr/bin/env python3
"""Verify LC_BUILD_VERSION identifies a physical iOS arm64 binary, not a simulator."""
import struct
import sys
from pathlib import Path

def verify(data):
    if len(data) < 32:
        raise ValueError('Mach-O header ontbreekt.')
    magic, cpu, subtype, filetype, count, commands_size, flags, reserved = struct.unpack_from('<8I', data)
    if magic != 0xFEEDFACF or cpu != 0x0100000C or filetype != 2:
        raise ValueError('Geen uitvoerbare 64-bit arm64 Mach-O.')
    if 32 + commands_size > len(data):
        raise ValueError('Mach-O load commands zijn afgebroken.')
    offset = 32
    platform = None
    for _ in range(count):
        if offset + 8 > 32 + commands_size:
            raise ValueError('Ongeldige load-commandtabel.')
        command, size = struct.unpack_from('<2I', data, offset)
        if size < 8 or offset + size > 32 + commands_size:
            raise ValueError('Ongeldige load-commandgrootte.')
        if command == 0x32:  # LC_BUILD_VERSION
            if size < 24:
                raise ValueError('LC_BUILD_VERSION is afgebroken.')
            platform = struct.unpack_from('<I', data, offset + 8)[0]
        offset += size
    if platform != 2:  # PLATFORM_IOS; simulator is PLATFORM_IOSSIMULATOR (7).
        raise ValueError(f'Geen fysieke iOS-build (platform={platform}).')

if __name__ == '__main__':
    if len(sys.argv) != 2:
        raise SystemExit('Gebruik: python3 verify_device_binary.py <Mach-O>')
    try:
        verify(Path(sys.argv[1]).read_bytes())
    except (ValueError, OSError, struct.error) as error:
        raise SystemExit(str(error))
    print('PASS: physical iOS arm64 executable, not a simulator binary.')
