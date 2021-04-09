@set coco3=C:\Users\treyt\projects\personal\coco3
@set lwasm=%coco3%\bin\lwasm.exe
@set vcc=%coco3%\vcc\vcc.exe

@%lwasm% --list=%1.lst %1.asm -o%1.bin
@rem del %1.dsk
@rem C:\Users\ttomes\projects\coco3\bin\file2dsk.exe %1.bin
@%vcc% %1.bin
