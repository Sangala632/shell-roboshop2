#!/bin/bash

source ./common.sh
App_name=frontend

check_root

dnf module disable nginx -y &>>$LOG_FILE
VALIDATE $? "disabling nginx module"

dnf module enable nginx:1.24 -y &>>$LOG_FILE
VALIDATE $? "enabling nginx 1.24 module"    

dnf install nginx -y &>>$LOG_FILE
VALIDATE $? "installing nginx"

systemctl enable nginx &>>$LOG_FILE
systemctl start nginx 
VALIDATE $? "starting nginx service"

rm -rf /usr/share/nginx/html/* &>>$LOG_FILE
VALIDATE $? "removing old nginx content"

curl -o /tmp/frontend.zip https://roboshop-artifacts.s3.amazonaws.com/frontend-v3.zip &>>$LOG_FILE
VALIDATE $? "downloading frontend content"

cd /usr/share/nginx/html 
unzip /tmp/frontend.zip &>>$LOG_FILE
VALIDATE $? "extracting frontend content"

cp $SCRIPT_DIR/nginx.conf /etc/nginx/nginx.conf &>>$LOG_FILE
VALIDATE $? "copying nginx configuration file"

systemctl restart nginx &>>$LOG_FILE
VALIDATE $? "restarting nginx service"

print_timecd