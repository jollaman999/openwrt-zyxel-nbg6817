./scripts/imgAlignment.sh ./common/build/ipq/nor_sbl1.mbn 131072
./scripts/imgAlignment.sh ./common/build/ipq/tools/out/NBG6817/nor4mplusemmc-system-partition.bin 131072
./scripts/imgAlignment.sh ./common/build/ipq/nor_sbl2.mbn 131072
./scripts/imgAlignment.sh ./common/build/ipq/nor_sbl3.mbn 262144
./scripts/imgAlignment.sh ./common/build/ipq/tools/out/NBG6817/NBG6817-cdt.mbn 65536
./scripts/imgAlignment.sh ./common/build/ipq/ssd.mbn 65536
./scripts/imgAlignment.sh ./common/build/ipq/tz.mbn 262144
./scripts/imgAlignment.sh ./common/build/ipq/rpm.mbn 262144

cat nor_sbl1.mbn > zld_sbl.bin
cat nor4mplusemmc-system-partition.bin >> zld_sbl.bin
cat nor_sbl2.mbn >> zld_sbl.bin
cat nor_sbl3.mbn >> zld_sbl.bin
cat NBG6817-cdt.mbn >> zld_sbl.bin
cat ssd.mbn >> zld_sbl.bin
cat tz.mbn >> zld_sbl.bin
cat rpm.mbn >> zld_sbl.bin

This is whole "zld_sbl.bin" (1280k=1310720)
No.: Name             Attributes            Start             Size
  0: 0:SBL1           0x0000ffff              0x0          0x20000 //128k=131072
  1: 0:MIBIB          0x0000ffff          0x20000          0x20000 //128k=131072
  2: 0:SBL2           0x0000ffff          0x40000          0x20000 //128k=131072
  3: 0:SBL3           0x0000ffff          0x60000          0x40000 //256k=262144
  4: 0:DDRCONFIG      0x0000ffff          0xa0000          0x10000 // 64k= 65536
  5: 0:SSD            0x0000ffff          0xb0000          0x10000 // 64k= 65536
  6: 0:TZ             0x0000ffff          0xc0000          0x40000 //256k=262144
  7: 0:RPM            0x0000ffff         0x100000          0x40000 //256k=262144
