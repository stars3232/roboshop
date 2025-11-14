#!/bin/bash

userid=$(id -u)

R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

LOG_FOLDER="/var/log/roboshop-logs"
SCRIPT_NAME=$(echo $0 | cut -d "." -f1)
LOG_FILE="$LOG_FOLDER/$SCRIPT_NAME.log"
SCRIPT_PATH=$PWD

mkdir -p $LOG_FOLDER
echo "Script started executing at: $(date)" | tee -a $LOG_FILE

# check the user has root priveleges or not
if [ $userid -ne 0 ]
then
    echo -e "$R ERROR:: Please run this script with root access $N" | tee -a $LOG_FILE
    exit 1 #give other than 0 upto 127
else
    echo "You are running with root access" | tee -a $LOG_FILE
fi

echo "Enter root password #Type RoboShop@1"
read -s Rootpassword

# validate functions takes input as exit status, what command they tried to install
VALIDATE(){
    if [ $1 -eq 0 ]
    then
        echo -e "$2 is ... $G SUCCESS $N" | tee -a $LOG_FILE
    else
        echo -e "$2 is ... $R FAILURE $N" | tee -a $LOG_FILE
        exit 1
    fi
}

dnf install maven -y &>>$LOG_FILE
VALIDATE $? "Installing Java"

id roboshop &>>$LOG_FILE
if [ $? -ne 0 ]
then
    echo "Creating roboshop user"
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>>$LOG_FILE
    VALIDATE $? "Creating Robosshop user"
else
    echo -e "$Y Roboshop user already exists $N"
fi

mkdir -p /app &>>$LOG_FILE
VALIDATE $? "Creating app directory"

rm -rf /app/*
cd /app
curl -L -o /tmp/shipping.zip https://roboshop-artifacts.s3.amazonaws.com/shipping-v3.zip &>>$LOG_FILE
VALIDATE $? "Downloading Shipping Component"

unzip /tmp/shipping.zip &>>$LOG_FILE
VALIDATE $? "Unzipping Shipping"

mvn clean package &>>$LOG_FILE
VALIDATE $? "Packaging the Shipping component"

mv target/shipping-1.0.jar shipping.jar &>>$LOG_FILE
VALIDATE $? "Moving and Renaming Shipping.jar file"

cp $SCRIPT_PATH/shipping.service /etc/systemd/system/shipping.service
VALIDATE $? "Copying Shipping.service file"

systemctl daemon-reload &>>$LOG_FILE
VALIDATE $? "Daemon-reload Shipping"

systemctl enable shipping &>>$LOG_FILE
VALIDATE $? "Enabling Shipping"

systemctl start shipping &>>$LOG_FILE
VALIDATE $? "Starting Shipping"

dnf install mysql -y &>>$LOG_FILE
VALIDATE $? "Installing mysql" 

mysql -h mysql.sivarobos.shop -u root -p$Rootpassword -e 'use cities' &>>$LOG_FILE
if [ $? -ne 0 ]
then
    echo "Loading data into mysql"
    mysql -h mysql.sivarobos.shop -uroot -p$Rootpassword < /app/db/schema.sql &>>$LOG_FILE
    mysql -h mysql.sivarobos.shop -uroot -p$Rootpassword < /app/db/app-user.sql &>>$LOG_FILE
    mysql -h mysql.sivarobos.shop -uroot -p$Rootpassword < /app/db/master-data.sql &>>$LOG_FILE
    VALIDATE $? "Loading data into mysql"
else
    echo -e "$Y Data is already loaded $N"


systemctl restart shipping &>>$LOG_FILE
VALIDATE $? "Restarting Shipping"

