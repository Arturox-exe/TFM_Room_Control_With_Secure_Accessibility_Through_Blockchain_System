FROM python:3.9

ADD subscriber.py .

RUN pip install paho-mqtt git+https://github.com/ozgur/python-firebase

CMD ["python3", "-u", "./subscriber.py"]