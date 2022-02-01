# DCSDrivingJTAC
An autonomous working JTAC for DCS who search for targets and lase them.
This script is based on MOOSE develope.

The JTAC is based on a group of ground vehicles, that means that the JTAC is not affected from clouds.
The JTAC search independently for enemy ground units, stops, gives a target message, create a "nine" liner and lase the  target.
After the target is destroyed, JTAC search for a new target.

Usage:
1. Create a JTAC group and give a good name
2. Create a JTAC zone. In this Zone the JTAC will search for targets.
3. Call function with drivingJTAC("JTAC","ZONE")
4. Repeat for other JTACs. Up to 10 JTACs are possible.

That's all! Enjoy!
