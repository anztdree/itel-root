#!/system/bin/sh
until [ "$(getprop sys.boot_completed)" = "1" ]; do sleep 3; done
log -t PIFHELPER "service: start (module context)"
cp -f /sdcard/pif.json /data/adb/pif.json 2>/dev/null
chmod 644 /data/adb/pif.json 2>/dev/null
chcon u:object_r:adb_data_file:s0 /data/adb/pif.json 2>/dev/null
if [ -r /data/adb/pif.json ]; then
  log -t PIFHELPER "service: READ OK $(wc -c < /data/adb/pif.json) bytes"
else
  log -t PIFHELPER "service: READ DENIED"
fi
