@echo off
cd /d %~dp0

if "%PROCESSOR_ARCHITECTURE%" EQU "AMD64" (
  goto :ARCH_X64
) else (
  goto :ARCH_X86
)

:ARCH_X86
call C:\apps\strawberry-perl-5.22.3.1-32bit-portable\portableshell.bat /SETENV
goto :KHCODER

:ARCH_X64
call C:\apps\strawberry-perl-5.22.3.1-64bit-portable\portableshell.bat /SETENV
goto :KHCODER

:KHCODER
perl -MConfig -e "printf("""Perl executable: %%s\nPerl version   : %%vd $Config{archname}\n\n""", $^X, $^V)" 2>nul
set KHCPUB=2
perl kh_coder.pl
