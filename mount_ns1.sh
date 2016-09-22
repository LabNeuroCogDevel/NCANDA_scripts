#!/usr/bin/expect -f


set user_id [lindex $argv 0]
set user_pswd [lindex $argv 1] 
set timeout 60



# MOUNT SERVER
spawn /sbin/mount -t smbfs "//${user_id}@acct.upmchs.net/ns1/PAARC" /Volumes/ns1

while {1} {
	expect {
	 eof						{break}
	 "Password for acct.upmchs.net:"	{send "${user_pswd}\r"}
	 }
}
wait

# CODE to write output to stdout
# puts "\n Text \n"
