#!/bin/bash

source ./common.sh
App_name=redis
check_root


dnf module disable redis -y &>>$LOGFILE
VALIDATE $? "disabling redis module"

dnf module enable redis:7 -y &>>$LOGFILE
VALIDATE $? "enabling redis 7 module"

dnf install redis -y &>>$LOGFILE
VALIDATE $? "installing redis"

sed -i -e 's/127.0.0.1/0.0.0.0/g' -e '/protected-mode/ c protected-mode no' /etc/redis/redis.conf
VALIDATE $? "Edited redis.conf to accept remote connections"

systemctl enable redis &>>$LOGFILE
VALIDATE $? "enabling redis service"

systemctl start redis &>>$LOGFILE
VALIDATE $? "starting redis service"

print_time