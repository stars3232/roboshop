#!/bin/bash

userid=$(id -u)

 R="\e[31m"
 G="\e[32m"
 Y="\e[33m"
 N="\e[0m"

 LOG_FOLDER=/var/log/roboshop_logs
 SCRIPT_NAME=$(echo "$0" | cut -d "." -f1)
 LOG_FILE=$LOG_FOLDER/$SCRIPT_NAME.log
 SCRIPT_PATH=$PWD

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

dnf module disable nodejs -y &>>$LOG_FILE
validation $? "disabling nodejs"

dnf module enable nodejs:20 -y &>>$LOG_FILE
validation $? "enabling nodejs"

dnf install nodejs -y &>>$LOG_FILE
validation $? "installing nodejs"


id roboshop
if [ $? -ne 0 ]
then
useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>>$LOG_FILE
validation $? "creating system user"
else
echo "roboshop system user already exists"
fi

mkdir -p /app 
validation $? "creating app directory"

curl -o /tmp/catalogue.zip https://roboshop-artifacts.s3.amazonaws.com/catalogue-v3.zip &>>$LOG_FILE
validation $? "downloading catalogue component"

rm -rf /app/*
cd /app
unzip /tmp/catalogue.zip &>>$LOG_FILE
validation $? "unzipping catalogue"

npm install &>>$LOG_FILE
validation $? "Installing dependencies"

cp $SCRIPT_PATH/catalogue.service /etc/systemd/system/catalogue.service
validation $? "Setting up systemctl services"

systemctl daemon-reload &>>$LOG_FILE
systemctl enable catalogue &>>$LOG_FILE
systemctl start catalogue &>>$LOG_FILE
validation $? "Starting catalogue component"

cp $SCRIPT_PATH/mongodb.repo /etc/yum.repos.d/mongo.repo
dnf install mongodb-mongosh -y &>>$LOG_FILE
VALIDATE $? "Installing MongoDB Client"

STATUS=$(mongosh --host mongodb.sivarobos.shop --eval 'db.getMongo().getDBNames().indexOf("catalogue")')
if [ $STATUS -lt 0 ]
then
mongosh --host mongodb.sivarobos.shop </app/db/master-data.js &>>$LOG_FILE
VALIDATE $? "Loading data into MongoDB"
else
echo -e "Data is already loaded ... $Y SKIPPING $N"
fi