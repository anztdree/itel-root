log -t PIFHELPER "customize: start (installer context)"
cp -f /sdcard/pif.json /data/adb/pif.json 2>/dev/null
chmod 644 /data/adb/pif.json 2>/dev/null
chcon u:object_r:adb_data_file:s0 /data/adb/pif.json 2>/dev/null
if [ -r /data/adb/pif.json ]; then
  log -t PIFHELPER "customize: READ OK $(wc -c < /data/adb/pif.json) bytes"
else
  log -t PIFHELPER "customize: READ DENIED"
fi
