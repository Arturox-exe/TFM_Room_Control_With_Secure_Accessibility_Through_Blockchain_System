#!/usr/bin/env python

import RPi.GPIO as GPIO
from mfrc522 import SimpleMFRC522
import time
import hashlib

reader = SimpleMFRC522()
while(1):
    try:
        print("Put the tag")
        id, text = reader.read()
        password = input("Write the password: ")
        print(id)
        print(text)

        combined = str(id) + password
        
        hash = hashlib.sha256(combined.encode())
            
        hashdigest = hash.hexdigest()

        print(hashdigest)
        
        time.sleep(1)
    finally:
        GPIO.cleanup()