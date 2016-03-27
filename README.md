Not Another Trader (Temporary Name)
(pun on YAT intended)


What this Script is currently:
Currently it is a Manager-based Trading Script for Stations:
-> As usual the Manager does regular tries in Zonetrading, but also gets Order Requests from his Trading Ships and sends them getting his desired Wares.
-> This is done by using each Ships Trade Order List, so the Player can always see what each of his Ships is up to.
(the menu item to clear this List is available, but the Player can not clear it or remove Trade Orders - this is intentional)
-> Also the Manager knows about priorities and takes ordered but not yet delivered Wares into account, but wont lock up if a priority item is unavailable.
-> He may also send Ships to Mine instead of Trading if they are equipped for it. (the Ship will mine infinietely for now, but one of the next steps is it to change this behavior to one Mining run)
-> Also the basics for a new (written from Scratch) Dialogue Tree are used for the Manager and the Captains of his Subordinate Ships - 
 it currently offers the minimal necessary functionality to make it useable with this Script, but many additions are planned.

Also there are some Debug and Cleanup Features available, like switching Logging on and off per entity/NPC or cleanup (removes either only the Actor or his whole Ship from the Game)

How to use:
-> Assign a Manager to a Station
-> Talk with him and use the Menu Item "Convert to UT CAC | 1"
-> Now give him some Money (hint: fastest way when you now talk to him is 1 - 2 - 5  (Personal Settings - Money - Give wanted Money)
-> also give him some Trading Mining Ships by
 A) telling the captain he shall work for the Manager or
 B) talk to the Manager and use 4 - 1 (Subordinate Managment - Take all Ships in Player Squad) (ships added with this method will inherit the managers log debug behavior)
 - - note that Ships not useable by the Manager will not be accepted by the Manager and therefore be without Superior then, but otherwise remain unchanged 


Planned Short-term additions/changes:
-> Gas and Asteroid Mining by the Manager using Station Drones
-> proper usage of my new Command Structure for the mining Script so Mining Ships may be used for Trading again (yep, this point should have made it to the release Version, but i noticed only after i prepared everything)

Planned Mid-term additions
-> Usage of Fight Ships for Station Defence or Escorts of Trading Ships
-> Adding Experience Gain to NPCs for certain activities
-> Usage of this Experience by the Scripts
-> Better useable Dialogue Trees for Player NPCs with more Functions than currently
-> Apporiate Equipping of Ships for their Jobs (Mining Ships will gett Mining Drones if they have none for example)

Planned Long-Term Additions/Changes
-> make Fight Ships seperate from Stations as beginning for Managing Fleets
-> make the Scripts also available to the Player for his direct Subordinates for better Control
 - - Better usage of emergency calls: you can tell all NPCs in how bad the Situation must become to call the superior for assistance (btw: no outstanding Orders and no useful stuff to do is the "worst" possible situation)

Planned Long-Long-term goal
-> full Fleet Management, more Control of what Ship will do what and when based on Order Lists (similiar to Trade Lists, but with more functions) so you can plan your invasion for days in detail just to see everything fall apart on first contact
-> completely new Scripts for everything, written from Scratch
-> all of this is also used by NPCs, not just for Player assets
-> completely rewritten Dialogue Trees for everyone (or at least for Player-owned NPCs)


Technical Info: internally used Command Structure (the core of it all - over-complicated for stuff like Trade runs, but opens many possibilities)
With this Script package i am using a diffrent Approach for managing Orders to Objects (not the usual "each Ship runs a main Script depending on its Job" but a more generic approach):
-> Similiar to Trade Orders all NPCs use a Command queue (this.$orderlist) which is basically a list of tables
where each table entry (called $order or $params from here, depending on context) defines an Order to be executed and the table Values are the params to it,
which can be named freely with the exeption of currently one entry:
$order.$script (or a param named 'script')
this Value defines the Script Name to be executed for this Order and therefore the param name will always be the same as the script Name.
-> this is done by making a base script for each entity type which basically
A) sets up Variables (like this.$orderlist),
B) stupidly goes through the this.$orderlist and
C) if this.$orderlist is empty checks which default behavior makes most sense currently to add it to this.$orderlist (and may contact the superior for new Orders)
-> All scripts called with this also require a param named 'params' - it is the aforementoined $order/$params table passed to the script instead of Parameters because we cannt define them dnyamically when calling a Script. You can still use the usual params, but they all have to be optional (=have a default value) to avoid unnecesary Errors to the debuglog
You have to set all params from the Table first before doing anything else (or directly work with the table for small stuff)
-> Another difference to all current Scripts is the requirement that all $order s MUST end at some point to allow continuation with another Order
(best is to make run time as short as needed, like for Trading just execute a single Trade run and exit - and if you need to do more trades just add them further entries to this.$orderlist )
if you need endless loops either just exit at regular intervals and before that add yourself to the end of the this.$orderlist (just add $params to its end to execute your current command with the same params as currently) or check regluary if this.$orderlist.{2}? has been added and terminateto allow the other script to run (and maybe add yourself to the this.$orderlist again; this method is not good because this way the default/fallback orders like refueling or rearming may never be reached, so try to avoid it.)
or
you can also modify this table if you want certain values to persist or want to change certain params for the next run.






==================================================
Credits:
Thanks to:
Itaros - for the Build Tree UI Menu
