#!/bin/bash

source ./common.sh
App_name=catalogue

check_root
app_setup
nodejs_setup
systemd_setup

cp $SCRIPT_DIR/mongodb.repo /etc/yum.repos.d/mongo.repo
VALIDATE $? "copying mongodb repo file"

dnf install mongodb-mongosh -y &>>$LOG_FILE
VALIDATE $? "installing mongodb client"

STATUS=$(mongosh --host mongodb.hellodevsecops.space --eval 'db.getMongo().getDBNames().indexOf("catalogue")')
if [ $STATUS -lt 0 ]
then
    mongosh --host mongodb.hellodevsecops.space </app/db/master-data.js &>>$LOG_FILE
    VALIDATE $? "loading catalogue schema and data"
else
        echo -e "Data is already loaded ... $Y SKIPPING $N"
fi

print_time