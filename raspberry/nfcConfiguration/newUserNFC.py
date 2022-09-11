import RPi.GPIO as GPIO
from mfrc522 import SimpleMFRC522
reader = SimpleMFRC522()
import time
import hashlib
import psycopg2
try:
    conn = psycopg2.connect("dbname=hospital-db user=postgres password=root host=192.168.1.23")

    cur = conn.cursor()

    
    
    print("Put the tag")
    id, text = reader.read()

    username = input("Write the name: ")
    surname = input("Write the surname: ")
    password = input("Write the password: ")
    combined = str(id) + password
    hash = hashlib.sha256(combined.encode())
    hashdigest = hash.hexdigest()
    strRole = input("Write the role 1-Doctor, 2-Patient, 3-Visitor: ")
    role = int(strRole)
    if(role == 2 or role == 3):
        room = input("Write the room: ")
        if(role == 2):
            illness = input("Write the illness: ")
              
    print("------------------------------------")
    
    if role == 1:
        cur.execute("insert INTO hospital.user (name, surname, hash, role)VALUES(%s, %s, %s, %s) RETURNING id", (username, surname, hashdigest, role))
    elif role == 2:
        cur.execute("insert INTO hospital.user (name, surname, hash, role, room, illness)VALUES(%s, %s, %s, %s, %s, %s) RETURNING id", (username, surname, hashdigest, role, room, illness))
    elif role == 3:
        cur.execute("insert INTO hospital.user (name, surname, hash, role, room)VALUES(%s, %s, %s, %s, %s) RETURNING id", (username, surname, hashdigest, role, room))

    conn.commit()
    print("New user created in database")
    
    user_id = cur.fetchone()[0]

    print("Now place your tag to write")
    reader.write(str(user_id))
  
    print("Written with user id: ",user_id)

    conn.close()
    

finally:
    GPIO.cleanup()