"D:\SteamLibrary\SteamApps\common\X Rebirth Tools\XRCatTool.exe" -in . -include md/ t/ -out ext_01.cat -dump
"D:\SteamLibrary\SteamApps\common\X Rebirth Tools\XRCatTool.exe" -in subst_01 -out subst_01.cat -dump
"D:\SteamLibrary\SteamApps\common\X Rebirth Tools\WorkshopTool.exe" update -path . -contentdef .\content_steam.xml -minor -changenote "Update via batch file."
del ext_01.cat
del ext_01.dat
@pause