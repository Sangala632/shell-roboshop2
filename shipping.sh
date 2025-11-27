#!/bin/bash

source ./common.sh
App_name=shipping

check_root
echo "enter the mysql root password"
read -s mysql_root_password

app_setup
maven_setup
systemd_setup

dnf install mysql -y  &>>$LOGFILE
VALIDATE $? "installing the mysql"

mysql -h mysql.hellodevsecops.space -u root -p$MYSQL_ROOT_PASSWORD -e 'use cities' &>>$LOG_FILE
if [ $? -ne 0 ]
then
    mysql -h mysql.hellodevsecops.space  -uroot -p$MYSQL_ROOT_PASSWORD < /app/db/schema.sql &>>$LOGFILE
    mysql -h mysql.hellodevsecops.space  -uroot -p$MYSQL_ROOT_PASSWORD < /app/db/app-user.sql &>>$LOGFILE
    mysql -h mysql.hellodevsecops.space  -uroot -p$MYSQL_ROOT_PASSWORD < /app/db/master-data.sql &>>$LOGFILE
    VALIDATE $? "loading data into mysql"
else
    echo -e "Data is already loaded into MySQL ... $Y SKIPPING $N"
fi

systemctl restart shipping &>>$LOGFILE
VALIDATE $? "Restart shipping"

print_time

