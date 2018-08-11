./scripts/imgAlignment.sh sbl1_nor.mbn 262144
./scripts/imgAlignment.sh nor-system-partition-nbg6617.bin 131072
./scripts/imgAlignment.sh tz.mbn   393216
./scripts/imgAlignment.sh cdt-nbg6617.bin  65536

cat sbl1_nor.mbn > zld_sbl.bin
cat nor-system-partition-nbg6617.bin >> zld_sbl.bin
cat tz.mbn >> zld_sbl.bin
cat cdt-nbg6617.bin >> zld_sbl.bin
../../../../../scripts/imgAlignment.sh zld_sbl.bin 917504(0xe0000)

So!!!! "zld_sbl.bin" is SBL1 + MIBIB + QSEE + CDT + DDRPARAMS

No.: Name             Attributes            Start             Size
  0: 0:SBL1           0x0000ffff              0x0          0x40000 //256k
  1: 0:MIBIB          0x001040ff          0x40000          0x20000 //128k
  2: 0:QSEE           0x0000ffff          0x60000          0x60000 //384k
  3: 0:CDT            0x0000ffff          0xc0000          0x10000 //64k
  4: 0:DDRPARAMS      0x0000ffff          0xd0000          0x10000 //64k
  5: 0:APPSBL         0x0000ffff          0xe0000          0x80000 //512k
  6: 0:APPSBLENV      0x0000ffff         0x160000          0x10000 //64k
  7: 0:ART            0x0000ffff         0x170000          0x10000 //64k
  8: 0:HLOS           0x0000ffff         0x180000         0x400000 //4M
  9: freespace        0x0000ffff         0x580000        0x1a80000 //26M

Please Reference Doc \\172.21.48.203\tpdc\SW2\Platform\Documents\QSDK\MIBIB_Adjust_ParitionLayout.docx
