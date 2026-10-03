#!/system/bin/sh
# autogrid.sh - จัดหน้าต่างโคลนให้ขนาดเท่ากันอัตโนมัติ (ต้อง root)
# รัน: su -c "sh /data/local/tmp/autogrid.sh"
# หยุด: su -c "pkill -f autogrid.sh"

PATTERN="roblox"     # ชื่อแพ็กเกจที่ใช้กรอง (โคลนที่ชื่อมี roblox ติดมาด้วยจะถูกจับหมด)
COLS=0               # 0 = คำนวณอัตโนมัติ, หรือใส่เลข เช่น 3
INTERVAL=3           # ตรวจทุกกี่วินาที
MARGIN=0             # ช่องว่างระหว่างหน้าต่าง (px)

# เปิดโหมดหน้าต่างลอย
settings put global enable_freeform_support 1
settings put global force_resizable_activities 1

resize_task() {
  am task resize "$1" "$2" "$3" "$4" "$5" 2>/dev/null \
    || cmd activity task resize "$1" "$2" "$3" "$4" "$5" 2>/dev/null
}

get_ids() {
  dumpsys activity activities 2>/dev/null \
    | grep -i "Task{" | grep -i "$PATTERN" \
    | sed -n 's/.*#\([0-9][0-9]*\).*/\1/p' | sort -un
}

LAST=""
while true; do
  IDS=$(get_ids | tr '\n' ' ')
  N=$(echo $IDS | wc -w)

  if [ "$N" -gt 0 ] && [ "$IDS" != "$LAST" ]; then
    SIZE=$(wm size | tail -1 | sed 's/.*: //')
    W=${SIZE%x*}; H=${SIZE#*x}

    # ถ้าจอหมุนแนวนอน สลับกว้าง/สูง
    ROT=$(dumpsys window displays 2>/dev/null | grep -o 'rotation=[0-9]' | head -1 | cut -d= -f2)
    if [ "$ROT" = "1" ] || [ "$ROT" = "3" ]; then T=$W; W=$H; H=$T; fi

    C=$COLS
    if [ "$C" -le 0 ]; then
      C=1
      while [ $((C * C)) -lt "$N" ]; do C=$((C + 1)); done
    fi
    R=$(( (N + C - 1) / C ))
    CW=$((W / C)); CH=$((H / R))

    i=0
    for id in $IDS; do
      r=$((i / C)); c=$((i % C))
      L=$((c * CW + MARGIN)); T=$((r * CH + MARGIN))
      resize_task "$id" "$L" "$T" $((L + CW - MARGIN)) $((T + CH - MARGIN))
      i=$((i + 1))
    done
    echo "จัด $N หน้าต่าง ($C x $R) ขนาดช่องละ ${CW}x${CH}"
    LAST="$IDS"
  fi
  sleep "$INTERVAL"
done
