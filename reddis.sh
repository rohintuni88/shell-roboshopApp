#!/bin/bash

LOG_FOLDER="/var/log/ShellLogs"
sudo mkdir -p $LOG_FOLDER
sudo chown -R ec2-user:ec2-user $LOG_FOLDER
sudo chmod -R 755 $LOG_FOLDER
LOG_FILE="$LOG_FOLDER/$0.log"

USERID=$(id -u)
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"
TIME_STAMP=$(date "+%Y-%m-%d %H:%M:%S")

if [ $USERID -ne 0 ]; then
    echo -e "$TIME_STAMP [ERROR] $R Please Run with ROOT access $N " | tee -a $LOG_FILE
    exit 1
fi

VALIDATE(){
 if [ $1 -ne 0 ]; then
    echo -e "$TIME_STAMP [ERROR] $2... $R Failure $N" |   tee -a $LOG_FILE 
    exit 1
 else 
   echo -e "$TIME_STAMP [INFO] $2... $G SUCCESS $N" |   tee -a $LOG_FILE
fi
}

dnf module disable redis -y
dnf module enable redis:7 -y
dnf install redis -y 
VALIDATE $? "Installing redis Server"

netstat -lntp | tee -a $LOG_FILE
VALIDATE $? "check port running or not"
 
sed -i -e 's/127.0.0.1/0.0.0.0/g' -e '/protected-mode/ c protected-mode no' /etc/redis/redis.conf | tee -a $LOG_FILE
VALIDATE $? "Allowing remote connection to redis"


systemctl enable redis &>> $LOG_FILE
systemctl start redis  &>> $LOG_FILE
VALIDATE $? "Restart redis"

netstat -lntp | tee -a $LOG_FILE
VALIDATE $? "check port running or not"
