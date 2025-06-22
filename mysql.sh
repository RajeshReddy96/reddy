#!/bin/bash

LOGS_FOLDER="/var/log/expense"
SCRIPT_NAME=$(echo $0 | cut -d "." -f1)
TIMESTAMP=$(date +%Y-%m-%d-%H-%S)
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
        echo -e "$R Please run this script with root priviliges $N" | tee -a $LOG_FILE 
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

dnf install mysql-server -y &>>$LOG_FILE

VALIDATE $? " Installing MYSQL Server"

systemctl enable mysqld &>>$LOG_FILE
VALIDATE $? "Enabled MYSQL Server"

systemctl start mysqld &>>$LOG_FILE
VALIDATE $? "started mysql server"

mysql -h mysql.rrajesh.online -u root -pExpenseApp@1 -e 'show databases;' &>>$LOG_FILE
if [ $?-ne 0 ]
then 
    echo "MYSQL root password is not setup, settting now" &>>$LOG_FILE
    mysql_secure_installation --set-root-pass ExpenseApp@1 
    VALIDATE $? "Setting UP root password"
else
    echo -e "MYSQL root pasword is already setup..$Y SKIPPING $N" | tee -a $LOG_FILE
fi