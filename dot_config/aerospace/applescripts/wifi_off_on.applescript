-- Turn WiFi off
do shell script "networksetup -setairportpower en0 off"

-- Wait for 1 seconds
delay 1

-- Turn WiFi on
do shell script "networksetup -setairportpower en0 on"
