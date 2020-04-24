@ECHO OFF
setlocal

REM このバッチファイルと同じ階層にPowerShellスクリプトファイルが置かれている前提
set mydir=%~dp0
set pspath=%mydir%WorkTimeSummarizer.ps1
rem 指定されたps1を実行する
REM set pspath=%1

REM 
REM -ExecutionPolicy 一時的に実行ポリシーを緩和する
REM https://qiita.com/tomoko523/items/df8e384d32a377381ef9
powershell -NoProfile -ExecutionPolicy RemoteSigned %pspath%

REM 終了
PAUSE
endlocal
rem exit
