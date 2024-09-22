#!/bin/bash

# Check if the PASSWORD environment variable is set
if [ -z "$PASSWORD" ]; then
    echo "PASSWORD environment variable not set. Using default password."
    PASSWORD="defaultpassword"
fi

# Update containeruser's password
echo "containeruser:$PASSWORD" | sudo chpasswd

