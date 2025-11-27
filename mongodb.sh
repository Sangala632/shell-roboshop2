#!/bin/bash

source ./common.sh
App_name=mongodb

check_root

cp mongodb.repo /etc/yum.repos.d/mongo.repo
VALIDATE $? "copying mongodb repo file"

dnf install mongodb-org -y &>>$LOG_FILE
VALIDATE $? "installing mongodb server"

systemctl enable mongod &>>$LOG_FILE
VALIDATE $? "enabling mongodb service"

systemctl start mongod &>>$LOG_FILE
VALIDATE $? "starting mongodb service"

sed -i 's/127.0.0.1/0.0.0.0/g' /etc/mongod.conf
VALIDATE $? "allowing remote connections in mongodb config file"

systemctl restart mongod &>>$LOG_FILE
VALIDATE $? "restarting mongodb service"

print_time


