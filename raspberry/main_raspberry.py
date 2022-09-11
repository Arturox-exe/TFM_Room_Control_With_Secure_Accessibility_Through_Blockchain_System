import RPi.GPIO as GPIO
from mfrc522 import SimpleMFRC522
import time
import hashlib
import psycopg2
import requests
import json
from datetime import datetime
import sys

from tkinter import *
from tkinter import ttk 

import threading

import firebase_admin
from firebase_admin import db
from firebase_admin import credentials

import matplotlib.pyplot as plt
import matplotlib.dates as mdates
from matplotlib.backends.backend_tkagg import FigureCanvasTkAgg
from pandas import DataFrame

import os

cred = credentials.Certificate("iot-tfm-firebase-adminsdk-qjn8p-77af420573.json")
default_app = firebase_admin.initialize_app(cred, {
    'databaseURL':"https://iot-tfm-default-rtdb.europe-west1.firebasedatabase.app/"
    })

url = "http://192.168.1.23:4000"

login_enpoint = url + "/login"
login_data = { "username": "user1", "orgName": "hospital1"}
registry_enpoint = url + "/channels/mychannel/chaincodes/registry"


reader = SimpleMFRC522()
room = sys.argv[1]
superuser = 1
patient = 2
visitor = 3
firabase_room = "/" + room

class App(Tk):
 
    def __init__(self):
        #Frame.__init__(self, master, *args, **kwargs)
        super().__init__()

        self.geometry("800x480")
        self.title('TFM')
        #self.resiazable(0,0)
        #self.parent = master
        self.grid()
        self.createWidgets()
        self.createThread()


    def recollect_data(self):
        ref = db.reference(firabase_room)
        last_registry = ref.order_by_child("time").limit_to_last(1).get()


        for key, value in last_registry.items():
            splited_value = str(value).split(': ')

        
        
        battery = int(splited_value[1].split(',')[0])
        name = splited_value[3].split(',')[0].split("'")[1]
        pulse = int(splited_value[4].split(',')[0])
        steps = int(splited_value[5].split(',')[0])
        surname = splited_value[6].split(',')[0].split("'")[1]
        hour = splited_value[7].split(',')[0].split("'")[1]

        

        data = {'name': name, 'surname': surname, 'battery': battery, 'pulse': pulse, 'steps': steps, 'hour': hour}
        json.dumps(data)



        last_5registry = ref.order_by_child("time").limit_to_last(10).get()

        pulses = []

        steps = []

        hours = []

        for key, value in last_5registry.items():
            
            splited_value = str(value).split("'pulse': ")[1].split(",")[0]
            pulses.append(int(splited_value))

            splited_value = str(value).split("'steps': ")[1].split(",")[0]
            steps.append(int(splited_value))

            splited_value =  str(value).split("'time': '")[1].split("'")[0]
            hours.append(datetime.strptime(splited_value, '%Y-%m-%d %H:%M:%S.%f'))
            #hours.append(splited_value)

        constants = {'hours': hours, 'pulses': pulses, 'steps': steps}
        
        return data, constants


    def opening_room(self):


        GPIO.setmode(GPIO.BOARD)
        # Set pin 11 as an output, and set servo1 as pin 11 as PWM

        GPIO.setup(11,GPIO.OUT)
        
        servo1 = GPIO.PWM(11,50) # Note 11 is pin, 50 = 50Hz pulse
        
        servo1.start(0)
        servo1.ChangeDutyCycle(7)
        
        time.sleep(5)

        servo1.ChangeDutyCycle(2)
        time.sleep(0.5)
        servo1.ChangeDutyCycle(0)

        
        servo1.stop()



    def get_user_database(self, text, hash):

        conn = psycopg2.connect("dbname=hospital-db user=postgres password=root host=192.168.1.23")

        cur = conn.cursor()

        cur.execute("select * from hospital.user where id = {}".format(text))
        

        if(cur.rowcount == 0):

            #print("The password or the tag is wrong")
            self.replaceMainText("The password or the tag is wrong")

            self.passwordDelete()
            
        

            return None
        

        row = cur.fetchone()
        idDB = row[0]
        nameDB = row[1]
        surnameDB = row[2]
        hashDB = row[3]
        roleDB = row[4]
        roomDB = row[5]
        illnessDB = row[6]

        cur.close()

        if hash != hashDB:
            #print("The password or the tag is wrong")
            self.replaceMainText("The password or the tag is wrong")

            self.passwordDelete()

            return None


        if roleDB == superuser:
            print("Hello {}".format(nameDB))
            self.replaceMainText("Hello {}, choose an option: ".format(nameDB))
            

        if roleDB == patient:
            print("Hello {}".format(nameDB))
            self.replaceMainText("Hello {}, do you want to enter?: ".format(nameDB))
            if room != roomDB:
                return "NoRoom"
            

        if roleDB == visitor:
            print("Hello {}".format(nameDB))
            self.replaceMainText("Hello {}, do you want to enter?: ".format(nameDB))
            if room != roomDB:
                return "NoRoom"
            

        return row

    def name_surname_database(self, id):

        conn = psycopg2.connect("dbname=hospital-db user=postgres password=root host=192.168.1.23")
        cur = conn.cursor()
        cur.execute("select name, surname from hospital.user where id = {}".format(id))
        #if(cur.rowcount == 0):
            #array_data = [room, date, idDB, "", ""]
        #else:
        row = cur.fetchone()
        nameDB = row[0]
        surnameDB = row[1]

        return nameDB, surnameDB

    def read_room(self, headers):
        read_endpoint = registry_enpoint + '?args=["' + room + '"]&fcn=ReadRegistry'

        return requests.get(read_endpoint, headers=headers).json()

    def historic_room(self, headers):
        read_endpoint = registry_enpoint + '?args=["' + room + '"]&fcn=GetAssetHistory'

        return requests.get(read_endpoint, headers=headers).json()

    def quarantine_room(self, headers, quarantine):
        now = datetime.now()
        date = now.strftime("%d/%m/%Y %H:%M:%S")
        array_data = [room, quarantine, date]
        data = { "fcn": "ChangeQuarantine", "args": array_data}
        requests.post(registry_enpoint, data=data, headers=headers).json()

    def open_door(self, row, headers):

        idDB = row[0]
        nameDB = row[1]
        surnameDB = row[2]
        hashDB = row[3]
        roleDB = row[4]
        roomDB = row[5]
        illnessDB = row[6]


        now = datetime.now()
        date = now.strftime("%d/%m/%Y %H:%M:%S")

        conn = psycopg2.connect("dbname=hospital-db user=postgres password=root host=192.168.1.23")
        cur = conn.cursor()
        cur.execute("select * from hospital.user where room = {} and role = {}".format("'"+room+"'", 2))
        if(cur.rowcount == 0):
            array_data = [room, date, idDB, "", ""]
        else:
            rowPatient = cur.fetchone()
            idDBPatient = rowPatient[0]
            illnessDBPatient = rowPatient[6]


            array_data = [room, date, idDB, idDBPatient, illnessDBPatient]

        cur.close()

        data = { "fcn": "CreateRegistry", "args": array_data}
        requests.post(registry_enpoint, data=data, headers=headers).json()

    def login(self):

        login_request = requests.post(login_enpoint, data=login_data).json()
        token = "Bearer " + login_request["message"]["token"]
        headers = {"Authorization": token} 

        return headers

    def super_user_option(self, row):

        headers = self.login()
        
        self.passwordDelete()
        self.buttonsSuperUser(row, headers)
        

    def patient_option(self, row):

        headers = self.login()  

        self.passwordDelete()
        self.buttonsYesNo(row, headers)


    def visitor_option(self, row):
       
        headers = self.login()
        read = self.read_room(headers)

        if read["result"] != "the registry do not exists":
            if "Yes" == read["result"]["quarantine"]:
                print("The room is on quarantine, you cannot enter")
                self.replaceMainText("The room is on quarantine, you cannot enter, put another tag ")
                self.passwordDelete()
                self.createThread()
            else:
                self.buttonsYesNoVisitor(row, headers)
                self.passwordDelete()
    
        

    def readNFC(self):

        #Hay que crear un thread cuando acabe
        
        print("Put your tag")
        try:
            id, text = reader.read()
        finally:
            GPIO.cleanup()

        self.replaceMainText("Write your password: ")

        self.passwordEntry(text, id)

        #password = input("Write your password: ")



    def buttonsSuperUser(self, row, headers):
        self.option1Button = Button(text='1-Enter room', command=lambda: self.openRoom(row, headers))
        self.option1Button.pack(anchor=CENTER)     

        self.option2Button = Button(text='2-See historic', command=lambda: self.seeHistoric(headers))
        self.option2Button.pack(anchor=CENTER)     

        self.option3Button = Button(text='3-Un/Quarantine the room', command=lambda: self.quarantine(headers))
        self.option3Button.pack(anchor=CENTER)  

        self.option4Button = Button(text='4-See patient constant', command=lambda: self.patientConstants())
        self.option4Button.pack(anchor=CENTER) 

        self.option5Button = Button(text='5-Cancel', command=lambda: self.cancelSuperUser())
        self.option5Button.pack(anchor=CENTER) 

    def buttonsYesNo(self, row, headers): 
        self.yesButton = Button(text='Yes', command=lambda: self.yes(row, headers))
        self.yesButton.pack(anchor=CENTER)     

        self.noButton = Button(text='No', command=lambda: self.no())
        self.noButton.pack(anchor=CENTER) 

    def yes(self, row, headers):
        self.opening_room()
        self.open_door(row, headers)

        self.deleteButtonsYesNo()
        self.createThread()
        self.label.configure(text="Put your tag")
    
    def no(self):
        self.deleteButtonsYesNo()
        self.createThread()
        self.label.configure(text="Put your tag")


    def deleteButtonsYesNo(self):
        self.yesButton.pack_forget()
        self.noButton.pack_forget()

    def deleteButtonsSuperUser(self):
        self.option1Button.pack_forget()
        self.option2Button.pack_forget()
        self.option3Button.pack_forget()
        self.option4Button.pack_forget()
        self.option5Button.pack_forget()

    def buttonsYesNoVisitor(self, row, headers): 
        self.yesButton = Button(text='Yes', command=lambda: self.yesVisitor(row, headers))
        self.yesButton.pack(anchor=CENTER)     

        self.noButton = Button(text='No', command=lambda: self.no())
        self.noButton.pack(anchor=CENTER)

    def yesVisitor(self, row, headers):
        self.opening_room()
        self.open_door(row, headers)

        self.deleteButtonsYesNo()
        self.createThread()
        self.label.configure(text="Put your tag")
                


    def openRoom(self, row, headers):
        read = self.read_room(headers)
            
        if(read["result"] != "the registry do not exists" and read["result"]["quarantine"] == "Yes"):
            self.deleteButtonsSuperUser()
            self.label.configure(text="The room is on a quarantine, do you want to enter?")
            self.buttonsYesNo(row, headers)

            #enter = input("The room is on a quarantine, do you want to enter? Y/N ")

        else:
            self.opening_room()
            self.open_door(row, headers)

            self.deleteButtonsSuperUser()
            self.createThread()
            self.label.configure(text="Put your tag")

       
    
    def seeHistoric(self, headers):

        self.deleteButtonsSuperUser()
        self.label.configure(text="Room historic data")

        historic = self.historic_room(headers)

        #self.historicLabel = Label(text=historic, font=("Helvetica", 11))
        #self.historicLabel.pack(anchor=CENTER)

        

        #wanted_historic = {"room": [], "date": [], "quarantine": [], "visitor": [], "patient": [], "illness": []}
        wanted_historic = []
        auxVisitor = ""
        auxPatient = ""
        auxPValue = ""
        auxVValue = ""
        
        for result in historic["result"]:
            record = result['record']
            room = record['id']
            date = record['date']
            quarantine = record['quarantine']
            visitor = record['visitor']['idVisitor']
            patient = record['patient']['idPatient']
            illness = record['patient']['illness']

            
            if patient != '':
                if auxPatient != patient:
                    auxPatient = patient
                    name, surname = self.name_surname_database(int(patient))
                    patient = name + " " + surname
                    auxPValue = patient
                else:
                    patient = auxPValue

                

            if visitor != '':
                if auxVisitor != visitor:
                    auxVisitor = visitor
                    name, surname = self.name_surname_database(int(visitor))
                    visitor = name + " " + surname
                    auxVValue = visitor
                else:
                    visitor = auxVValue
            

            wanted_historic.append({"room": room, "date": date, "quarantine": quarantine, "visitor": visitor, "patient": patient, "illness": illness})


        self.tree = ttk.Treeview(column=("c1", "c2", "c3", "c4", "c5", "c6"), show='headings', height=17)

        self.tree.column("# 1", width=50, anchor=CENTER)
        self.tree.heading("# 1", text="Room")
        self.tree.column("# 2", width=200, anchor=CENTER)
        self.tree.heading("# 2", text="Date")
        self.tree.column("# 3", width=100, anchor=CENTER)
        self.tree.heading("# 3", text="Quarantine")
        self.tree.column("# 4", width=150, anchor=CENTER)
        self.tree.heading("# 4", text="Visitor")
        self.tree.column("# 5", width=150, anchor=CENTER)
        self.tree.heading("# 5", text="Patient")
        self.tree.column("# 6", width=100, anchor=CENTER)
        self.tree.heading("# 6", text="Illness")

        for index, value in enumerate(wanted_historic):
            self.tree.insert('', 'end', text=str(index+1), values=(value['room'], value['date'], value['quarantine'], value['visitor'], value['patient'], value['illness']))

        self.tree.pack()
        
        self.cancelHistoricButton = Button(text='Cancel', command=lambda: self.cancelHistoric())
        self.cancelHistoricButton.pack(anchor=CENTER) 
    
    def cancelHistoric(self):
        self.deleteHistoric()
        self.createThread()
        self.label.configure(text="Put your tag")

    def deleteHistoric(self):
        self.tree.pack_forget()
        self.cancelHistoricButton.pack_forget()

    def quarantine(self, headers):
        self.label.configure(text="Do you want to quarantine or unquarantine")
        #quarantine = input("Write: 'Yes' to Quarantine or 'No' to Unquarantine ")
        
        self.deleteButtonsSuperUser()
        self.buttonsYesNoQuarantine(headers)

    def buttonsYesNoQuarantine(self, headers): 
        self.yesButton = Button(text='Quarantine', command=lambda: self.yesQuarantine(headers))
        self.yesButton.pack(anchor=CENTER)     

        self.noButton = Button(text='Unquarantine', command=lambda: self.noQuarantine(headers))
        self.noButton.pack(anchor=CENTER) 

    def yesQuarantine(self, headers):
        self.quarantine_room(headers, "Yes")

        self.deleteButtonsYesNo()
        self.createThread()
        self.label.configure(text="Put your tag")
    
    def noQuarantine(self, headers):
        self.quarantine_room(headers, "No")

        self.deleteButtonsYesNo()
        self.createThread()
        self.label.configure(text="Put your tag")


    def patientConstants(self):
        self.deleteButtonsSuperUser()
        self.label.configure(text="Patient contants")

        data, constants = self.recollect_data()

        self.dataLabel = Label(text="Name: {}, Surname: {}, Battery: {}%, Pulse: {}, Steps: {}, Last Registry: {}".format(data["name"], data["surname"], data["battery"], data["pulse"], data["steps"], data["hour"]), font=("Helvetica", 11))
        self.dataLabel.pack(anchor=CENTER)


        df2 = DataFrame(constants,columns=['hours','pulses', 'steps'])

        figure2 = plt.Figure(figsize=(5,3), dpi=100)
        ax2 = figure2.add_subplot(111)
        self.line2 = FigureCanvasTkAgg(figure2, self)
        self.graph = self.line2.get_tk_widget()
        self.graph.pack()


        pulsesDf = df2[['hours','pulses']].groupby('hours').sum()
        pulsesDf.plot(kind='line', legend=True, ax=ax2, color='r',marker='o', fontsize=10)

        stepsDf = df2[['hours','steps']].groupby('hours').sum()
        stepsDf.plot(kind='line', legend=True, ax=ax2, color='b',marker='o', fontsize=10)
        
        ax2.set_title('Last constants')

        
        self.cancelConstantsButton = Button(text='Cancel', command=lambda: self.cancelConstants())
        self.cancelConstantsButton.pack(anchor=SE) 

        

        
        print(data)
    

    def cancelConstants(self):
        self.deleteConstants()
        self.createThread()
        self.label.configure(text="Put your tag")

    def deleteConstants(self):
        self.dataLabel.pack_forget()
        self.graph.pack_forget()
        self.cancelConstantsButton.pack_forget()

    def cancelSuperUser(self):
        self.deleteButtonsSuperUser()
        self.createThread()
        self.label.configure(text="Put your tag")


    def passwordDelete(self):
        self.passwordBox.pack_forget()
        self.passwordButton.pack_forget()
        os.system("pkill onboard")

    def passwordEntry(self, text, id):
        self.passwordBox = Entry(self, show="*")
        self.passwordButton = Button(text='Login', command=lambda: self.getPassword(text, id))
        self.passwordBox.pack(anchor=CENTER)
        self.passwordButton.pack(anchor=CENTER)
        os.system("onboard")
        

    def getPassword(self, text, id):
        password = self.passwordBox.get()

        combined = str(id) + password
        
        hash = hashlib.sha256(combined.encode())
            
        row = self.get_user_database(text, hash.hexdigest())

        print(row)

        if row != None and row[4] == superuser:
            self.super_user_option(row)         
        elif row != None and row[4] == patient:
            self.patient_option(row)         
        elif row != None and row[4] == visitor:
            self.visitor_option(row)
        elif row == "NoRoom":
            print("You cannot access to this room")
            self.replaceMainText("You cannot access to this room, put another tag")
            self.passwordDelete()
            self.createThread()
        else:
            self.replaceMainText("The password or tag was wrong, put your tag again")       
            self.createThread()

    def createThread(self):
        self.reader_thread = threading.Thread(target=self.readNFC)
        self.reader_thread.start()

    def replaceMainText(self, text):
        #self.display.delete(0, END)
        #self.display.insert(0, text)
        self.label.configure(text=text)

    def createWidgets(self):
        #self.display = Entry(self, font=("Arial", 24), relief=RAISED, justify=CENTER, bg='darkblue', fg='red', borderwidth=0)

        self.label = Label(text="", fg="Red", font=("Helvetica", 18))
        self.label.pack(anchor=CENTER)
        #self.label.place(x=100, anchor=CENTER)
        self.label.configure(text="Put your tag")

        #self.display.insert(0, "Ingrese Tarjeta")
        #self.display.grid(row=0, column=0, columnspan=9, sticky="nwne")


app = App()
app.mainloop()

# NFC = Tk()
# NFC.title("TFM")
# NFC.resizable(True, True)
# NFC.config(cursor="pencil")
# root = Pycalc(NFC).grid()
# NFC.mainloop()