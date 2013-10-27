#!/bin/busybox

# Start infinite loop to imitate the google updater
while true
do
	echo "PWNEDCAST-OTA: Running PwnedCast OTA Updater!"

	# Are we allowed to run?
	if [ -f /chrome/disable_ota ]
	then
		echo "PWNEDCAST-OTA: OTA updates disabled per user request, Terminating"
		
		# Create a empty loop so this script is never ran again.
		while true
		do
			sleep 72000
		done
		
		# Somehow, if we break out, exit, do NOT continue!
		exit 0
	fi

	# Delete any existing OTA
	if [ -f /cache/eureka_image.zip ]
	then
		rm /cache/eureka_image.zip
	fi

	# Variables used for the update check
	BuildVersion="$(getprop ro.build.version.incremental)"
	SerialHash=`busybox sha1sum /factory/serial.txt | busybox awk '{ print $1 }'` # We only use your serial hash
	URL="http://servernetworktech.com/pwnedcast-ota/update.php?version=$BuildVersion&serial=$SerialHash"
	MD5Hash="$URL.md5"

	# Check for the update
	echo "PWNEDCAST-OTA: Checking for Updates"
	Response="$(busybox wget -q $URL -O - )"

	# Error checking for update, due to server/web issues
	if [ $? -ne 0 ]
	then
		echo "PWNEDCAST-OTA: Error Checking for update, Connection Issues"
		echo "PWNEDCAST-OTA: Restarting Service in 5 Minutes"
		sleep 300
		exit 1
	# Update is available, do something
	elif [ "$Response" != "NoUpdate" ]
	then
		echo "PWNEDCAST-OTA: Update Found! Downloading now!"
		busybox wget -q "$Response" -O /cache/eureka_image.zip
		if [ $? -ne 0 ];
		then
			echo "PWNEDCAST-OTA: Error Downloading, Terminating!"
			
			# Delete the failed update if it exists
			if [ -f /cache/eureka_image.zip ]
			then
				rm /cache/eureka_image.zip
			fi
			exit 1
		else
			#Download was good, now download MD5 and check
			echo "PWNEDCAST-OTA: Update Downloaded Successfully"
			echo "PWNEDCAST-OTA: Downloading and Verifiying MD5 Hash"
			
			MD5Check=`busybox md5sum /cache/eureka_image.zip`
			MD5DL="$(busybox wget -q $MD5Hash -O - )"
			
			# Did MD5 Download Successfully?
			if [ $? -ne 0 ];
			then
				echo "PWNEDCAST-OTA: Error Downloading MD5, Terminating!"
				exit 1
			else
				# Compare MD5's
				if [ "$MD5DL" != "$MD5Check" ]
				then
					# Bad MD5 Match
					echo "PWNEDCAST-OTA: Failed to verify, Deleting file and terminating."
					
					# Delete the failed update if it exists
					if [ -f /cache/eureka_image.zip ]
					then
						rm /cache/eureka_image.zip
					fi
					exit 1
				else
					# All went good
					echo "PWNEDCAST-OTA: File Verified Successfully!"
					echo "PWNEDCAST-OTA: Rebooting into Flashcast To Update..."
					reboot recovery	
				fi
			fi
		fi
	else
		echo "PWNEDCAST-OTA: No Update Required!"
	fi

	# Sleep a while
	echo "PWNEDCAST-OTA: Sleeping 20 hours"
	sleep 72000

done
