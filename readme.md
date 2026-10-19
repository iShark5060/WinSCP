# WinSCP

[![PR](https://img.shields.io/github/actions/workflow/status/iShark5060/WinSCP/pr.yml?style=flat-square&label=PR)](https://github.com/iShark5060/WinSCP/actions/workflows/pr.yml)
![C++Builder](https://img.shields.io/badge/C%2B%2BBuilder-11-E31C23?style=flat-square)
![Windows](https://img.shields.io/badge/Windows-x64-0078D6?logo=windows&logoColor=white&style=flat-square)
[![Cursor](https://img.shields.io/badge/Cursor-IDE-141414?logo=cursor&logoColor=white&style=flat-square)](https://cursor.com)
[![NuGet](https://img.shields.io/nuget/v/WinSCP?style=flat-square&logo=nuget&logoColor=white)](https://www.nuget.org/packages/WinSCP/)

WinSCP is a Windows file manager for SFTP, FTP, FTPS, SCP, S3, WebDAV, and local-to-local transfers. It edits files, synchronizes directories, stores sites, and automates transfers with a .NET assembly and scripting.

This repository is a fork of [upstream WinSCP](https://github.com/winscp/winscp). It is not an official WinSCP release, and it is not affiliated with Martin Přikryl.

If you use this fork in research, documentation, or redistribution, cite **WinSCP** as the upstream project.

## Building

[C++Builder 11 Professional](https://www.embarcadero.com/products/cbuilder), [Visual Studio 2022 Build Tools](https://visualstudio.microsoft.com/downloads/) for the C# assembly, [nasm](https://www.nasm.us/) at `buildtools/tools/nasm.exe`, and [objconv](https://www.agner.org/optimize/#objconv) at `buildtools/tools/objconv.exe`.

```bat
build.bat Win64
```

`build.bat` with no argument builds Win32. Pass `Win64` for the 64-bit build.

## Directory structure

    /source             project files of all native libraries and executables
    /source/components  native WinSCP visual components
    /source/console     console interface
    /source/core        core (non-visual) part of WinSCP
                        (SSH, SFTP, FTP, WebDAV, S3 and SCP code)
    /source/dragext     drag&drop shell extension
    /source/filezilla   source code of FileZilla FTP client
    /source/forms       visual part of WinSCP (dialogs and windows)
    /source/packages    general visual components (both mine and 3rd party)
    /source/putty       source code of PuTTY SSH client
    /source/resource    resources strings
    /source/windows     other sources
    /deployment         Inno Setup script to create setup package
                        (see /deployment/readme)
    /dotnet             source code of WinSCP .NET assembly
    /libs               3rd party libraries
    /translations       translations of WinSCP strings

The setup package is an Inno Setup script. See [`deployment/readme.txt`](deployment/readme.txt).

## Licence

WinSCP is GNU GPL v3. See [`license.txt`](license.txt).

## Links

- WinSCP home: <https://winscp.net/>
- Upstream: <https://github.com/winscp/winscp>
- NuGet: <https://www.nuget.org/packages/WinSCP/>
- C++Builder: <https://www.embarcadero.com/products/cbuilder>
