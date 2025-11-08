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

dnf module disable nginx -y &>>$LOG_FILE
validation $? "Disabling nginx"

dnf module enable nginx:1.24 -y &>>$LOG_FILE
validation $? "Enabling nginx"

dnf install nginx -y &>>$LOG_FILE
validation $? "Installing nginx"

systemctl enable nginx &>>$LOG_FILE
systemctl start nginx &>>$LOG_FILE
validation $? "Starting nginx"

rm -rf /usr/share/nginx/html/*
validation $? "Removing default nginx content" 

curl -o /tmp/frontend.zip https://roboshop-artifacts.s3.amazonaws.com/frontend-v3.zip &>>$LOG_FILE
validation $? "Downloading Roboshop content"

cd /usr/share/nginx/html 
unzip /tmp/frontend.zip &>>$LOG_FILE
validation $? "Adding Roboshop Content"

cp $SCRIPT_PATH/nginx.conf /etc/nginx/nginx.conf
validation $? "Copying nginx conf file"

systemctl restart nginx &>>$LOG_FILE
validation $? "Restarting nginx"