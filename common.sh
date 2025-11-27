#!/bin/bash

START_TIME=$(date +%s)
USERID=$(id -u)
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

LOGS_FOLDER="/var/log/roboshop-logs"
SCRIPT_NAME=$(echo $0 | cut -d "." -f1)
LOG_FILE="$LOGS_FOLDER/$SCRIPT_NAME.log"

mkdir -p $LOGS_FOLDER
echo "script started executed at: $(date)" &>>$LOG_FILE

check_root(){
    if [ $USERID -ne 0 ]
    then
        echo -e "$R ERROR:: Please run this script with root access $N" | tee -a $LOG_FILE
        exit 1
    else
        echo "You are running with root access" | tee -a $LOG_FILE
    fi
}

VALIDATE() {
    if [ $1 -ne 0 ]
    then
        echo -e "$2 is ... $G SUCCESS $N" | tee -a $LOG_FILE
    else
        echo -e "$2 is ... $R FAILURE $N" | tee -a $LOG_FILE
        exit 1
    fi
}

app_setup(){
    id roboshop
    if [ $? -ne 0 ]
    then
        useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop
        VALIDATE $? "adding roboshop user"
    else
        echo -e "$Y INFO:: roboshop user already exists, skipping user creation $N" | tee -a $LOG_FILE
    fi

    mkdir /app &>>$LOG_FILE
    VALIDATE $? "creating application directory"

    curl -o /tmp/$App_name.zip https://roboshop-artifacts.s3.amazonaws.com/$App_name-v3.zip 
    VALIDATE $? "downloading $App_name application code"

    rm-rf /app/* &>>$LOG_FILE
    VALIDATE $? "removing old application content"

    cd /app 
    unzip /tmp/$App_name.zip
    VALIDATE $? "unzipping $App_name files"

}

nodejs_setup(){
    dnf module disable nodejs -y &>>$LOG_FILE
    VALIDATE $? "disabling nodejs module"

    dnf module enable nodejs:20 -y &>>$LOG_FILE
    VALIDATE $? "enabling nodejs 20 module"

    dnf install nodejs -y &>>$LOG_FILE
    VALIDATE $? "installing nodejs"


    npm install 
    VALIDATE $? "installing nodejs dependencies"
}

Python_setup(){
    dnf install python3 gcc python3-devel -y &>>$LOGFILE
    VALIDARE $? "INSTALLING python"

    pip3 install -r requirements.txt &>>$LOGFILE
    VALIDATE $? "installling the dependiecies os payment"

    cp $SCRIPT_DIR/payment.service /etc/systemd/system/payment.service &>>$LOGFILE
    VALIDATE $? "COPYING THE payment servive"
}

maven_setup(){
    dnf install maven -y &>>$LOGFILE
    VALIDARE $? "INSTALLING maven"

    mvn clean package &>>$LOGFILE
    VALIDATE $? "installing dependecies"

    mv target/shipping-1.0.jar shipping.jar &>>$LOGFILE
    VALIDATE $? "moving and renaming the jar file"
}

systemd_setup(){
    cp $SCRIPT_DIR/catalouge.service /etc/systemd/system/$App_name.service
    VALIDATE $? "copying $App_name systemd service file"

    systemctl daemon-reload &>>$LOG_FILE
    systemctl enable $App_name &>>$LOG_FILE
    systemctl start $App_name
    VALIDATE $? "starting $App_name service"
}

print_time(){
        END_TIME=$(date +%s)
        TOTAL_TIME=$(($END_TIME - $START_TIME))
        echo -e "Script exection completed successfully, $Y time taken: $TOTAL_TIME seconds $N" | tee -a $LOG_FILE
}