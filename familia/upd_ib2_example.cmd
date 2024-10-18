@ECHO OFF

set V8_UPDATE_SCRIPT=upd_ib2.cmd
set V8_UPDATE_SETTINGS=upd_ib2.env
set V8_UPDATE_LOG=log_tmb_ib.txt

call %~dp0%V8_UPDATE_SCRIPT% %~dp0%V8_UPDATE_SETTINGS% > %~dp0%V8_UPDATE_LOG%
