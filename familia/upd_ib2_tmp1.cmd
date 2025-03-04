@ECHO OFF

chcp %V8_ENCODING% > nul

set V8_UPDATE_SCRIPT=upd_ib2.cmd
set V8_UPDATE_SETTINGS=tmp1.env
set V8_UPDATE_LOG=log_tmp1.txt

call %~dp0%V8_UPDATE_SCRIPT% %~dp0%V8_UPDATE_SETTINGS% > %~dp0%V8_UPDATE_LOG%
