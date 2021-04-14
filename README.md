# color_zzt
An attempted reproduction of the Town of ZZT for the Color Computer 3.

## Why open source?

I'm putting a lot of work into this project.  That being said it's a collection of code I've pulled from example in the TRS-80 Facebook and Discord groups along with piles of books on CoCo 3 programming I've found on the internet.  All of that to create a game that is a derivative of something I really enjoyed in the '90s.  There is truly nothing new
under the sun.  I have gained a lot from the work of others; maybe you will gain something from my work.

## Spiritual descendant?

ZZT ran on DOS machines with 80x25 text resolution and 16 colors.  I can create the 16 color palette easily enough, but I'm pretty sure I need to lower the resolution to get a decent framerate.  My boards will only have 32x24 characters each (32x23 characters with the HUD).  I'm hoping to create a similar world layout and puzzles, but it won't be identical.

## Level Design

I'm designing the levels using some C# scripts running through LINQPad.  I'll have to add those here eventually.  The binary files get built into the program at the time of assembly.  If I do this right then hopefully I'll be able to swap out data files for different games.

It doesn't hurt to dream.

## EXEC.BAT

I'm using this batch file to assemble and run programs using the Vcc emulator.  You'll need to set the variables at the top of this file to point to your own copies of lwasm and vcc.

The batch file takes 1 parameter:  The name of the file to be assembled, minus the extension.

You will want to run this batch file from the root of the project, e.g. "exec demo\ascii" to run the ASCII demo.
