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

dnf module disable nginx -y
dnf module enable nginx:1.24 -y
dnf install nginx -y

systemctl enable nginx 
systemctl start nginx 


rm -rf /usr/share/nginx/html/* 

curl -o /tmp/frontend.zip https://roboshop-artifacts.s3.amazonaws.com/frontend-v3.zip


cd /usr/share/nginx/html 
unzip /tmp/frontend.zip