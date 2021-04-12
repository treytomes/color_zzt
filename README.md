# color_zzt
An attempted reproduction of the Town of ZZT for the Color Computer 3.

## Why open source?

I'm putting a lot of work into this project.  That being said it's a collection of code I've pulled from example in the TRS-80 Facebook and Discord groups along with piles of books
on CoCo 3 programming I've found on the internet.  All of that to create a game that is a derivative of something I really enjoyed in the '90s.  There is truly nothing new
under the sun.  I have gained a lot from the work of others; maybe you will gain something from my work.

## EXEC.BAT

I'm using this batch file to assembly and run programs using the Vcc emulator.  You'll need to set the variables at the top of this file to point to your own copies of lwasm and vcc.

The batch file takes 1 parameter:  The name of the file to be assembled, minus the extension.

You will want to run this batch file from the root of the project, e.g. "exec demo\ascii" to run the ASCII demo.
