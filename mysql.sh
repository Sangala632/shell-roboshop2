#!/bin/bash

source ./common.sh
App_name=mysql

check_root

echo "enter the mysql root password"
read -s mysql_root_password

dnf install mysql-server -y &>>$LOG_FILE
VALIDATE $? "installing mysql server"

systemctl enable mysqld &>>$LOG_FILE
VALIDATE $? "enable mysql server"

systemctl start mysqld  
VALIDATE $? "starting mysql server"

mysql_secure_installation --set-root-pass $mysql_root_password &>>$LOG_FILE
VALIDATE $? "SETTING THE MYSQL ROOT PASSWORD"

print_time