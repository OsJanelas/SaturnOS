@ECHO OFF

cls

echo "Compiling ASM File"
nasm -fbin SaturnOS 1.0/saturnos.asm   -o SaturnOS/SaturnOS.img