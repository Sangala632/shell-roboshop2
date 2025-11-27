#!/bin/bash
source ./common.sh
App_name=rabbitmq

check_root

echo "enter the rabbitmq root password"
read -s rabbitmq_password

cp rabbitmq.repo /etc/yum.repos.d/rabbitmq.repo &>>$LOG_FILE
VALIDATE $? "copying the rabbitmq repo"

dnf install rabbitmq-server -y &>>$LOG_FILE
VALIDATE $? "installing the rabbitmq server"

systemctl enable rabbitmq-server &>>$LOG_FILE
VALIDATE $? "enable the rabbitmq server"

systemctl start rabbitmq-server &>>$LOG_FILE
VALIDATE $? "starting the rabbitmq server"

rabbitmqctl add_user roboshop $rabbitmq_password #password roboshop123
rabbitmqctl set_permissions -p / roboshop ".*" ".*" ".*"

print_time