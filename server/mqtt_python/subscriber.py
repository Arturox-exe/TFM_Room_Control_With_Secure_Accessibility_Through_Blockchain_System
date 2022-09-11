import random
import json
from firebase import firebase

firebase = firebase.FirebaseApplication("https://iot-tfm-default-rtdb.europe-west1.firebasedatabase.app/", None)

from paho.mqtt import client as mqtt_client

broker = 'tfmserver.ddns.net'
port = 1883
topic = "hospital/patient/#"
client_id = f'python-mqtt-{random.randint(0, 1000)}'
username = 'aherrera'
password = 'password'


def connect_mqtt() -> mqtt_client:
    def on_connect(client, userdata, flags, rc):
        if rc == 0:
            print("Connected to MQTT Broker!")
        else:
            print("Failed to connect, return code %d\n", rc)

    client = mqtt_client.Client(client_id)
    client.username_pw_set(username, password)
    client.on_connect = on_connect
    client.connect(broker, port)
    return client


def subscribe(client: mqtt_client):
    def on_message(client, userdata, msg):
        print(f"Received `{msg.payload.decode()}` from `{msg.topic}` topic")

        
        m_in=json.loads(msg.payload.decode())
        room = m_in["room"]
        m_in.pop("room")
        resultado=firebase.post('/'+room, m_in)

    client.subscribe(topic)
    client.on_message = on_message


def run():
    client = connect_mqtt()
    subscribe(client)
    client.loop_forever()


if __name__ == '__main__':
    run()