#!/bin/sh

. /etc/functions.sh
include /lib/config

account=$(uci get sendmail.mail_server_setup.username)
email_list=$(uci get sendmail.send_to_1.email)

array_email_list=$(echo ${email_list//;/ })

for email in $array_email_list
do
	echo "From: Reminder: Internet data usage <$account>" > /var/mail
	echo "To: Dear User" >> /var/mail
	echo "Subject: Reminder: Internet data usage" >> /var/mail
	echo "Dear User," >> /var/mail
	echo "" >> /var/mail
	echo "	Just a reminder that you've got less than $1MB of data left." >> /var/mail
	echo "" >> /var/mail
	echo "Best Regards" >> /var/mail
	sleep 1
	cat /var/mail | ssmtp -C /var/ssmtp.conf -v $email

done
