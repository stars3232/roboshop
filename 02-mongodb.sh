#!/bin/bash

userid=$(id -u)

R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

LOG_FOLDER="/var/log/roboshop_logs"
SCRIPT_NAME=$(echo $0 | cut -d "." -f1)
LOG_FILE="$LOG_FOLDER/$SCRIPT_NAME.log"

mkdir -p $LOG_FOLDER
echo "Script started executing at $(date)" | tee -a $LOG_FILE

if [ $userid -eq 0 ]
then
    echo -e "$G u r running with root access u can go forward $N" | tee -a $LOG_FILE
else
    echo -e "$R please run as root user $N" | tee -a $LOG_FILE
    exit 1
fi

validation()
{
   if [ $1 -eq 0 ]
      then  
          echo -e "$G $2  is successful $N" | tee -a $LOG_FILE
      else
          echo -e "$R $2  is failure $N" | tee -a $LOG_FILE
          exit 1
   fi  
}

cp mongodb.repo /etc/yum.repos.d/mongo.repo
validation $? "copying mondodb.repo file"

dnf install mongodb-org -y &>>$LOG_FILE
validation $? "Installing mondodb"

systemctl enable mongod &>>$LOG_FILE
validation $? "Enabling mondodb"

systemctl start mongod &>>$LOG_FILE
validation $? "Starting mondodb"


sed -i 's/127.0.0.1/0.0.0.0/g' /etc/mongod.conf
validation $? "changing mondodb conf file"

systemctl restart mongod &>>$LOG_FILE
validation $? "Restarting mondodb"

