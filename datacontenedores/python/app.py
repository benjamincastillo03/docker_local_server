import cx_Oracle
import schedule
import time
import sqlite3
import requests
import json
import asyncio
import threading

from requests.packages.urllib3.exceptions import InsecureRequestWarning
requests.packages.urllib3.disable_warnings(InsecureRequestWarning)

from json import JSONDecodeError
from wakeonlan import send_magic_packet
from flask import Flask, request, jsonify
from datetime import datetime
from sqlite3 import Error
from celery import Celery

app = Flask(__name__)

def create_connection():
    conn = None;
    try:
        conn = sqlite3.connect('../datacontenedores/python/bd/alarmas.db')
        return conn
    except Error as e:
        print(e)
    return conn

def create_table(conn):
    try:
        sql_create_table = """ CREATE TABLE IF NOT EXISTS alarma_up (
                                id INTEGER PRIMARY KEY,
                                id_uid TEXT,
                                date_crea TEXT NOT NULL,
                                ind_tipoalarma TEXT NOT NULL,
                                hora TEXT NOT NULL,
                                mac TEXT NOT NULL,
                                lunes TEXT,
                                martes TEXT,
                                miercoles TEXT,
                                jueves TEXT,
                                viernes TEXT,
                                sabado TEXT,
                                domingo TEXT,
                                date_espeficico TEXT,
                                ind_estado TEXT NOT NULL,
                                ip TEXT
                                ); """
        conn.execute(sql_create_table)
    except Error as e:
        print(e)

def insert_time(conn, time, mac_value, ID_UID):
    try:
        sql_insert_time = ''' INSERT INTO times(time, mac_value, ID_UID) VALUES(?,?,?) '''
        conn.execute(sql_insert_time, (time, mac_value, ID_UID))
        conn.commit()
    except Error as e:
        print(e)

def select_all_times(conn,_mac):
    ind_estado = '1'
    cur = conn.cursor()
    cur.execute(''' SELECT * FROM alarma_up WHERE mac = ? AND ind_estado = ? ''', (_mac, ind_estado))
    rows = cur.fetchall()
    return rows


@app.route('/ini_alarma',methods=['GET'])
def ini():
    mac_value = request.args.get('mac','null')  # Recupera el valor del parámetro 'mac', devuelve null si no está presente
    ID_UID = request.args.get('ID_UID','null')  # Recupera el valor del parámetro 'ID_UID', devuelve null si no está presente
    current_time = datetime.now().strftime("%d-%m-%Y %H:%M:%S")
    conn = create_connection()
    with conn:
        create_table(conn)
        insert_time(conn,current_time,mac_value,ID_UID)
    return 'Hoy es: {}'.format(current_time)

@app.route('/inicio_alarma_totems', methods=['GET'])
def get_all_times():
    _mac = request.args.get('mac','null')
    #print("_mac -> "+_mac)
    conn = create_connection()
    with conn:
        rows = select_all_times(conn,_mac)
    return jsonify(rows)

@app.route('/insert_alarma_semanal', methods=['GET'])
def insert_alarma_semanal():
    conn = create_connection()
    with conn:
        create_table(conn)
        c = conn.cursor()
    #Insertar un registro en la tabla de get
    _id_uid = request.args.get('id_uid','null')
    _sysdate = datetime.now().strftime("%d-%m-%Y %H:%M:%S")
    _tipoalarma = request.args.get('tipoalarma','null')
    _hora = request.args.get('hora','null') 
    _mac =  request.args.get('mac','null')
    _lunes = request.args.get('lunes','null')
    _martes = request.args.get('martes','null')
    _miercoles = request.args.get('miercoles','null')
    _jueves = request.args.get('jueves','null')
    _viernes = request.args.get('viernes','null')
    _sabado = request.args.get('sabado','null')
    _domingo = request.args.get('domingo','null')
    _fecha_espcifica = request.args.get('fecha_especifica','null')
    _ip = request.args.get('ip','null')
    c.execute('''
        INSERT INTO alarma_up(id_uid,date_crea,ind_tipoalarma,hora,mac,lunes,martes,miercoles,jueves,viernes,sabado,domingo,date_espeficico,ind_estado,ip)
        VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)
    ''', (_id_uid,_sysdate,_tipoalarma,_hora,_mac,_lunes,_martes,_miercoles,_jueves,_viernes,_sabado,_domingo,_fecha_espcifica,'1',_ip))
    conn.commit()
    #c.close()
    rows = select_all_times(conn,_mac)
    return jsonify(rows)

@app.route('/delete_alarma',methods=['GET'])
def fn_delete_alarma():
    _id = request.args.get('id_','null')
    conn = create_connection()
    with conn:
        create_table(conn)
        cur = conn.cursor()
        cur.execute('''UPDATE alarma_up SET ind_estado = ? WHERE id = ?''', ('0', _id))
        conn.commit()
        #rows = {true}
        conn.close()
        return jsonify({'true'})

@app.route('/test_waketolan',methods=['GET'])
def test_waketolan():
    #_mac = request.args.get('mac','null')
    _mac = '00:E0:4C:68:39:30';
    print('wake to lann')
    print(_mac)
    try:
        send_magic_packet(_mac)
        return jsonify({'Se ha enviado el paquete Magic Packet para encender el equipo':_mac})        
    except Exception as e:
        return jsonify(f"Error: {e}",_mac)

@app.route('/api_responde',methods=['GET'])
def api_responde():
    response = requests.get('https://10.5.183.210/ssan_tot_admintotem/test',verify=False)
    print(response.text)
    #data = response.json()
    return jsonify({'true'})

def wake_on_lan():
    response = requests.get('https://10.5.183.210/ssan_tot_admintotem/test',verify=False)
    print(response.text)
    return jsonify({'true'})

def inicia_bd():
    print('inicia_bd')
    #conn = create_connection()
    #with conn:
        #create_table(conn)

if __name__ == '__main__':
    print('app.py       -> '+datetime.now().strftime("%d-%m-%Y %H:%M:%S"))
    t = threading.Thread(target=inicia_bd)
    t.start()
    app.run(host='0.0.0.0',port=8000)
