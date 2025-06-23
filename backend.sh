#!/bin/bash

LOGS_FOLDER="/var/log/expense"
SCRIPT_NAME=$(echo $0 | cut -d "." -f1)
TIMESTAMP=$(date +%Y-%m-%d-%H-%M-%S)
LOG_FILE=$LOGS_FOLDER/$SCRIPT_NAME-$TIMESTAMP.log
mkdir -p $LOGS_FOLDER

USERID=$(id -u)
R="\e[31m"
G="\e[32m"
N="\e[0m"
Y="\e[33m"

CHECK_ROOT(){
    if [ $USERID -ne 0 ]
    then 
        echo -e "$R Please run this script with root privileges $N" | tee -a $LOG_FILE 
        exit 1
    fi
}

VALIDATE(){
    if [ $1 -ne 0 ]   # $1 is checked: if it is not 0, the function logs the step as FAILED and exits the script.(status code)
    then 
        echo -e "$2 is ...$R FAILED $N" | tee -a $LOG_FILE 
        exit 1
    else
        echo -e "$2 is...$G SUCCESS $N" | tee -a $LOG_FILE # $2 is displayed in the message to show which step was SUCCESS or FAILED.
    fi
}

echo "Script started at: $(date)" | tee -a $LOG_FILE

CHECK_ROOT

dnf module disable nodejs -y &>>$LOG_FILE
VALIDATE $? "Disable default nodejs"

dnf module enable nodejs:20 -y &>>$LOG_FILE
VALIDATE $? "Enable nodejs:20"

dnf install nodejs -y &>>$LOG_FILE
VALIDATE $? "Install nodejs"

id expense &>>$LOG_FILE
if [ $? -ne 0 ]
then    
    echo -e "expense user is not exist... $G creating $N"
useradd expense &>>$LOG_FILE
VALIDATE $? "Creating expense user"
else
    echo -e "expense user already exists... $Y SKIPPING... $N"
fi

mkdir -p /app
VALIDATE $? "Creating /app folder"

curl -o /tmp/backend.zip https://expense-builds.s3.us-east-1.amazonaws.com/expense-backend-v2.zip &>>$LOG_FILE
VALIDATE $? "Downloading backend application code"

cd /app
rm -rf /app/* # remove the existing code
unzip /tmp/backend.zip &>>$LOG_FILE
VALIDATE $? "extracting application code"


npm install &>>$LOG_FILE
cp /home/ec2-user/reddy/backend.service /etc/systemd/system/backend.service

#load the data before running backend

dnf install mysql -y &>>$LOG_FILE
VALIDATE $? "Installing MYSQL Client"

mysql -h mysql.rrajesh.online -uroot -pExpenseApp@1 < /app/schema/backend.sql &>>$LOG_FILE
VALIDATE $? "Schema loading"

systemctl daemon-reload &>>$LOG_FILE
VALIDATE $? "daemon reload"

systemctl enable backend &>>$LOG_FILE
VALIDATE $? "enableed backed"

systemctl restart backend &>>$LOG_FILE
VALIDATE $? "restarted backed"

#netstat -lntp
#systemctl status backed
#ps -ef | grep mysqld , backend, in backend search with grep node
#connection check from backed to  mysql -> telnet mysql.rrajesh.online 3306 
#less access.log 

#frontend logs -> /var/log/nginx
#backend logs -> /var/log/messages
# in backend -> sudo tail -f /var/log/messages
#crontab used for scheduling command is sudo tail -f /var/log/cron (manual ga cheyakunda linux sever lo autimatic ga a pani deleion aor anything chestunndi)
#df -hT -> desk usage xfs is important
# df -hT | grep xfs | awk -F " " '{print $2F}'
# df -hT | grep xfs | awk -F " " '{print $6F}' | cut -d "%" -f1
 