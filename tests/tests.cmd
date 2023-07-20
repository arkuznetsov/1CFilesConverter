ECHO OFF

set SCRIPTS_PATH=%~dp0..\scripts
set FIXTURES_PATH=%~dp0fixtures
set OUT_PATH=%~dp0..\out

echo Clear output files...
if exist "%OUT_PATH%" (
    rd /S /Q "%OUT_PATH%"
)
md "%OUT_PATH%"

echo Tests: Convert CF

echo Test: CF -^> XML (ibcmd)
call %SCRIPTS_PATH%\cf2xml.cmd "%FIXTURES_PATH%\bin\1cv8.cf" "%OUT_PATH%\111_cf2xml_i" ibcmd

echo Test: CF -^> XML (designer)
call %SCRIPTS_PATH%\cf2xml.cmd "%FIXTURES_PATH%\bin\1cv8.cf" "%OUT_PATH%\112_cf2xml_d" designer

echo ""

echo Test: CF -^> infobase (ibcmd)
call %SCRIPTS_PATH%\cf2ib.cmd "%FIXTURES_PATH%\bin\1cv8.cf" "%OUT_PATH%\113_cf2ib_i" ibcmd

echo Test: CF -^> infobase (designer)
call %SCRIPTS_PATH%\cf2ib.cmd "%FIXTURES_PATH%\bin\1cv8.cf" "%OUT_PATH%\114_cf2ib_d" designer

echo ""

echo Test: CF -^> EDT (ibcmd)
call %SCRIPTS_PATH%\cf2edt.cmd "%FIXTURES_PATH%\bin\1cv8.cf" "%OUT_PATH%\115_cf2edt_i" ibcmd

echo Test: CF -^> EDT (designer)
call %SCRIPTS_PATH%\cf2edt.cmd "%FIXTURES_PATH%\bin\1cv8.cf" "%OUT_PATH%\116_cf2edt_d" designer

echo ""

echo Test: XML -^> CF (ibcmd)
call %SCRIPTS_PATH%\xml2cf.cmd "%FIXTURES_PATH%\xml\cf" "%OUT_PATH%\121_xml2cf_i\1cv8.cf" ibcmd

echo Test: XML -^> CF (designer)
call %SCRIPTS_PATH%\xml2cf.cmd "%FIXTURES_PATH%\xml\cf" "%OUT_PATH%\122_xml2cf_d\1cv8.cf" designer

echo ""

echo Test: XML -^> infobase (ibcmd)
call %SCRIPTS_PATH%\xml2ib.cmd "%FIXTURES_PATH%\xml\cf" "%OUT_PATH%\123_xml2ib_i" ibcmd

echo Test: XML -^> infobase (designer)
call %SCRIPTS_PATH%\xml2ib.cmd "%FIXTURES_PATH%\xml\cf" "%OUT_PATH%\124_xml2ib_d" designer

echo ""

echo Test: XML -^> EDT
call %SCRIPTS_PATH%\xml2edt.cmd "%FIXTURES_PATH%\xml\cf" "%OUT_PATH%\125_xml2edt"

echo ""

echo Test: infobase -^> CF (ibcmd)
call %SCRIPTS_PATH%\ib2cf.cmd "%FIXTURES_PATH%\ib" "%OUT_PATH%\131_xml2cf_i\1cv8.cf" ibcmd

echo Test: infobase -^> CF (designer)
call %SCRIPTS_PATH%\ib2cf.cmd "%FIXTURES_PATH%\ib" "%OUT_PATH%\132_xml2cf_d\1cv8.cf" designer

echo ""

echo Test: infobase -^> XML (ibcmd)
call %SCRIPTS_PATH%\ib2xml.cmd "%FIXTURES_PATH%\ib" "%OUT_PATH%\133_xml2xml_i" ibcmd

echo Test: infobase -^> XML (designer)
call %SCRIPTS_PATH%\ib2xml.cmd "%FIXTURES_PATH%\ib" "%OUT_PATH%\134_xml2xml_d" designer

echo ""

echo Test: infobase -^> EDT (ibcmd)
call %SCRIPTS_PATH%\ib2edt.cmd "%FIXTURES_PATH%\ib" "%OUT_PATH%\135_xml2edt_i" ibcmd

echo Test: infobase -^> EDT (designer)
call %SCRIPTS_PATH%\ib2edt.cmd "%FIXTURES_PATH%\ib" "%OUT_PATH%\136_xml2edt_d" designer

echo ""

echo Test: EDT -^> CF (ibcmd)
call %SCRIPTS_PATH%\edt2cf.cmd "%FIXTURES_PATH%\edt\cf" "%OUT_PATH%\141_edt2cf_i\1cv8.cf" ibcmd

echo Test: EDT -^> CF (designer)
call %SCRIPTS_PATH%\edt2cf.cmd "%FIXTURES_PATH%\edt\cf" "%OUT_PATH%\142_edt2cf_d\1cv8.cf" designer

echo ""

echo Test: EDT -^> IB (ibcmd)
call %SCRIPTS_PATH%\edt2ib.cmd "%FIXTURES_PATH%\edt\cf" "%OUT_PATH%\143_edt2ib_i" ibcmd

echo Test: EDT -^> IB (designer)
call %SCRIPTS_PATH%\edt2ib.cmd "%FIXTURES_PATH%\edt\cf" "%OUT_PATH%\144_edt2ib_d" designer

echo ""

echo Test: EDT -^> XML
call %SCRIPTS_PATH%\edt2xml.cmd "%FIXTURES_PATH%\edt\cf" "%OUT_PATH%\145_edt2xml" ibcmd

echo ""

echo Tests: Convert Data Processors & Reports

echo Test: DP (binary) -^> XML
call %SCRIPTS_PATH%\dp-bin2xml.cmd "%FIXTURES_PATH%\bin\ВнешняяОбработка1.epf" "%OUT_PATH%\211_dp-bin2xml" ibcmd

echo ""

echo Test: DP (binary) -^> EDT
call %SCRIPTS_PATH%\dp-bin2edt.cmd "%FIXTURES_PATH%\bin\ВнешнийОтчет1.erf" "%OUT_PATH%\212_dp-bin2edt" ibcmd

echo ""

echo Test: DP (binary folder) -^> XML
call %SCRIPTS_PATH%\dp-bin-dir2xml.cmd "%FIXTURES_PATH%\bin" "%OUT_PATH%\221_dp-bin-dir2xml" ibcmd

echo ""

echo Test: DP (binary folder) -^> EDT
call %SCRIPTS_PATH%\dp-bin-dir2edt.cmd "%FIXTURES_PATH%\bin" "%OUT_PATH%\222_dp-bin-dir2edt" ibcmd

echo ""

echo Test: DP (XML) -^> binary
call %SCRIPTS_PATH%\dp-xml2epf.cmd "%FIXTURES_PATH%\xml\dp\ВнешняяОбработка2.xml" "%OUT_PATH%\231_dp-xml2epf" ibcmd

echo ""

echo Test: DP (XML folder) -^> binary
call %SCRIPTS_PATH%\dp-xml-dir2epf.cmd "%FIXTURES_PATH%\xml\dp" "%OUT_PATH%\232_dp-xml2epf" ibcmd

echo ""

echo Tests: EDT Validate

echo Tests: Validate CF

call %SCRIPTS_PATH%\edt-validate.cmd "%FIXTURES_PATH%\edt\cf" "%OUT_PATH%\311_edt-validate-cf\report.txt" ibcmd

echo ""

echo Tests: Validate data processors ^& reports

call %SCRIPTS_PATH%\edt-validate.cmd "%FIXTURES_PATH%\edt\dp" "%OUT_PATH%\321_edt-validate-dp\report.txt" ibcmd

echo ""
