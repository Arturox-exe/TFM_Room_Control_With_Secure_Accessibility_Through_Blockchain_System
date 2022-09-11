import sys
import time
import argparse
from datetime import datetime
from base import MiBand2
from constants import ALERT_TYPES
import json
import psycopg2
import random

from paho.mqtt import client as mqtt_client


MAC = "F3:4D:EE:F2:9C:C4"
band = MiBand2(MAC, debug=True)
band.setSecurityLevel(level="medium")
band.authenticate()

room = sys.argv[1]
firabase_room = "/" + room


conn = psycopg2.connect("dbname=hospital-db user=postgres password=root host=192.168.1.23")
cur = conn.cursor()
cur.execute("select * from hospital.user where room = {} and role = {}".format("'"+room+"'", 2))
    

if(cur.rowcount == 0):
    print("There is no patient on that room")

row = cur.fetchone()
idDB = row[0]
nameDB = row[1]
surnameDB = row[2]
hashDB = row[3]
roleDB = row[4]
roomDB = row[5]
illnessDB = row[6]



broker = '192.168.1.23'
port = 1883
topic = "hospital/patient/" + str(idDB)

client_id = f'python-mqtt-{random.randint(0, 1000)}'
username = 'aherrera'
password = 'password'


def connect_mqtt():
    def on_connect(client_mqtt, userdata, flags, rc):
        if rc == 0:
            print("INFO: Connected publisher to MQTT Broker!")
        else:
            print("INFO: Failed publisher to connect, return code %d\n", rc)

    client_mqtt = mqtt_client.Client(client_id)
    client_mqtt.username_pw_set(username, password)
    client_mqtt.on_connect = on_connect
    client_mqtt.connect(broker, port)
    return client_mqtt

    

client_mqtt = connect_mqtt()
client_mqtt.loop_start()

while(1):
    try:
        now = datetime.now()

        band_battery = band.get_battery_info()
        band_steps = band.get_steps()
        band_heart = band.get_heart_rate_one_time()
         

        battery_level = band_battery["level"]
        steps = band_steps["steps"]
        heart = band_heart
        print(idDB, nameDB, surnameDB, battery_level, steps, heart, now)

        data= {
        'id':idDB,
        'name':nameDB,
        'surname':surnameDB,
        'battery_level':battery_level,
        'steps':steps,
        'pulse':heart,
        'time':now,
        'room': roomDB
        }

    except:
        print("Error connection with band")

    data_out = json.dumps(data, indent=4, sort_keys=True, default=str)

    client_mqtt.publish(topic, data_out, 1)

    

    time.sleep(10)


band.disconnect()
