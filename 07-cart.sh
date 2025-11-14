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

dnf module disable nodejs -y
VALIDATE $? "Disabling nodejs"

dnf module enable nodejs:20 -y
VALIDATE $? "Enabling nodejs"

dnf install nodejs -y
VALIDATE $? "Installing nodejs"

id roboshop &>>$LOG_FILE
if [ $? -eq 0 ]
then
    echo -e "$Y Roboshop user already exists $N"
else
    echo -e "$Y Creating Roboshop user $N"
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop
    VALIDATE $? "Creating roboshop system user"
fi

mkdir -p /app &>>$LOG_FILE
VALIDATE $? "Creating app directory"

curl -L -o /tmp/cart.zip https://roboshop-artifacts.s3.amazonaws.com/cart-v3.zip &>>$LOG_FILE
VALIDATE $? "Downloading cart"

rm -rf /app/*
cd /app 
unzip /tmp/cart.zip &>>$LOG_FILE
VALIDATE $? "Extracting cart"

npm install &>>$LOG_FILE
VALIDATE $? "Installing dependencies"

cp $SCRIPT_PATH/cart.service /etc/systemd/system/cart.service
VALIDATE $? "Coying .service file to setup systemd service"

systemctl daemon-reload &>>$LOG_FILE
VALIDATE $? "Daemon reload nodejs"

systemctl enable cart &>>$LOG_FILE
VALIDATE $? "Enabling cart"

systemctl start cart &>>$LOG_FILE
VALIDATE $? "Starting cart"