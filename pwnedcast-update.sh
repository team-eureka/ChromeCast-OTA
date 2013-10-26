#!/bin/busybox

echo "PWNEDCAST-OTA: Running PwnedCast OTA Updater!"

#are we allowed to run?
if [ -f /data/disable_ota ]
then
    echo "PWNEDCAST-OTA: OTA updates disabled per user request, exiting"
	exit 0
fi

#delete any existing OTA
if [ -f /cache/flashcast.zip ]
then
    rm /cache/flashcast.zip
fi

#variables
BuildVersion="$(getprop ro.build.version.incremental)"
Serial="$(cat /factory/serial.txt)"
URL="http://servernetworktech.com/pwnedcast-ota/update.php?version=$BuildVersion&serial=$Serial"

#Download update response as a file as we don't have curl :(
echo "PWNEDCAST-OTA: Checking for Updates"
busybox wget $URL -O /tmp/updateurl.txt >/dev/null 2>&1

Response="$(cat /tmp/updateurl.txt)"
rm /tmp/updateurl.txt

if [ "$Response" != "NoUpdate" ]
then
    echo "PWNEDCAST-OTA: Update Found! Downloading now!"
    busybox wget "$Response" -O /cache/eureka_image.zip >/dev/null 2>&1
    if [ $? -ne 0 ];
    then
        echo "PWNEDCAST-OTA: Error Downloading, Terminating!"
        rm /cache/flashcast.zip
        exit 1
    else
        echo "PWNEDCAST-OTA: Update Downloaded Successfully"
        echo "PWNEDCAST-OTA: Rebooting into Flashcast To Update..."
        reboot recovery
    fi
else
    echo "PWNEDCAST-OTA: No Update Required!"
fi
