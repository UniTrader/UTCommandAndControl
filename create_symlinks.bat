rem Param %1 is the X Rebirth Extensions directory where you want to link the Extensions
for /D %%d in (.\*) do mklink /D %1\%%d %cd%\%%d
