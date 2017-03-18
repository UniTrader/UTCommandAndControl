REM "D:\SteamLibrary\SteamApps\common\X Rebirth Tools\XRCatTool.exe" -in . -include md/ t/ -out ext_01.cat -dump
REM "D:\SteamLibrary\SteamApps\common\X Rebirth Tools\XRCatTool.exe" -in subst_01 -out subst_01.cat -dump
"D:\SteamLibrary\SteamApps\common\X Rebirth Tools\WorkshopTool.exe" update -path . -contentdef .\content_steam.xml -changenote "Update via batch file. Change note will be updated soon."
REM del ext_01.cat
REM del ext_01.dat
@pause