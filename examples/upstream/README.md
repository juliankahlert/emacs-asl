# Upstream ASL fixtures

These files were downloaded on 2026-09-23 from the TianoCore
[edk2-platforms repository](https://github.com/tianocore/edk2-platforms).
Their ASL contents are unchanged; line endings use LF. Each file retains its
original `BSD-2-Clause-Patent` SPDX license header.

| Local file | Upstream source |
| --- | --- |
| `SgiSsdt.asl` | [SgiPkg/AcpiTables/Ssdt.asl](https://github.com/tianocore/edk2-platforms/blob/master/Platform/ARM/SgiPkg/AcpiTables/Ssdt.asl) |
| `RPiDsdt.asl` | [RaspberryPi/AcpiTables/Dsdt.asl](https://github.com/tianocore/edk2-platforms/blob/master/Platform/RaspberryPi/AcpiTables/Dsdt.asl) |
| `RPiSsdtThermal.asl` | [RaspberryPi/AcpiTables/SsdtThermal.asl](https://github.com/tianocore/edk2-platforms/blob/master/Platform/RaspberryPi/AcpiTables/SsdtThermal.asl) |

The Raspberry Pi and SGI files depend on platform headers and are used for
fontification tests. `../simple-device.asl` is self-contained and can be
compiled with `iasl`.
