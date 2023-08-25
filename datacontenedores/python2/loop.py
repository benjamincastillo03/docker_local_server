import time
import sqlite3
from datetime import datetime
from flask import Flask, request, jsonify
import requests
from requests.packages.urllib3.exceptions import InsecureRequestWarning
requests.packages.urllib3.disable_warnings(InsecureRequestWarning)
import threading
import logging
import os
import socketio
# Configura el logging
logging.basicConfig(level=logging.INFO, 
                    format='%(asctime)s - %(levelname)s - %(message)s')
app = Flask(__name__)

def day_of_week_in_spanish(day_of_week):
    _now = datetime.now()
    _today = _now.strftime("%d-%m-%Y")

    days_in_spanish = [
    ' and (lunes="1" or date_espeficico = "'+_today+'" )  ', 
    ' and (martes="1"  or date_espeficico = "'+_today+'" )  ', 
    ' and (miercoles="1"  or date_espeficico = "'+_today+'" )  ', 
    ' and (jueves="1"  or date_espeficico = "'+_today+'" )  ', 
    ' and (viernes="1"  or date_espeficico = "'+_today+'" )  ', 
    ' and (sabado="1"  or date_espeficico = "'+_today+'" )  ', 
    ' and (domingo="1"  or date_espeficico = "'+_today+'" )  ', 
    ]
    return days_in_spanish[day_of_week.weekday()]

def ini_conexion():
    conn = None;
    try:
        conn = sqlite3.connect('../datacontenedores/python/bd/alarmas.db')
        return conn
    except Error as e:
        print(e)
    return conn


def busqueda_alarmas(conn):
    _now = datetime.now()
    _today = _now.strftime("%d-%m-%Y")
    _hora_minuto = _now.strftime("%H:%M")
    _dia_semana = day_of_week_in_spanish(_now)
    _ind_estado = '1'
    cur = conn.cursor()
    _sql = '''  SELECT
                    ind_tipoalarma  AS ind_tipoalarma,
                    mac             AS mac,
                    ip              AS ip,
                    date_crea       AS date_crea,
                    hora            AS hora,
                    date_espeficico AS date_espeficico 
                FROM 
                    alarma_up 
                WHERE 
                    ind_estado = ?
                    and 
                    hora = ?
            ''' + _dia_semana

    cur.execute(_sql,(_ind_estado,_hora_minuto))
    rows = cur.fetchall()
    #logging.info("  ****** BUSQUEDA ***** ")
    #logging.info("  *   _today          :   "+_today)
    #logging.info("  *   _hora_minuto    :   "+_hora_minuto)
    #logging.info("  *   _dia_semana     :   "+_dia_semana)
    #logging.info("  *   _sql            :   "+_sql)
    #logging.info("  *   _today          :   "+_today)
    return rows

class inicio_hora:
    def __init__(self):
        self.inicio_reloj = True
        self.aux = 0
    def do_something(self):
        self.aux = self.aux + 1
        current_path = os.getcwd()
        db_path = '../datacontenedores/python/bd/alarmas.db'
        if os.path.exists(db_path):
            _conn = ini_conexion()
            _row = busqueda_alarmas(_conn)
            _conn.close()
            if len(_row)>0:
                for f in _row:
                    logging.info(f)
                    v_tipo_alarma = f[0]
                    v_mac = f[1]
                    v_ip = f[2]
                    if v_tipo_alarma == '1' or v_tipo_alarma == '2':
                        try:
                            response = requests.get('https://10.5.183.210/ssan_tot_admintotem/test?ip='+v_ip+'&mac='+v_mac,verify=False)
                            logging.info("  SE ENVIO SENAL PRENDIDO -> "+response.text)
                        except Exception as e:
                            logging.error(e)
                    else:
                        try:
                            cliente = SocketClient('https://node_js:3000?ip='+v_ip,v_ip)
                            cliente.start()
                            cliente.stop()
                            logging.info("  ->  SE ENVIO SENAL APAGADO <- ")
                        except Exception as e:
                            logging.error(e)

                    logging.info("v_tipo_alarma :   "+v_tipo_alarma)
                    logging.info("v_mac         :   "+v_mac)
                    logging.info("v_ip          :   "+v_ip)

            else:
                logging.info("s/e")
        else:
            logging.info("El archivo no existe")

        logging.info(' - PASADA : '+datetime.now().strftime("%d-%m-%Y %H:%M:%S"))

    def run(self):
        current_path = os.getcwd()
        logging.info("La ruta actual es : " + current_path)
        self.aux = 0
        while self.inicio_reloj:
            self.do_something()
            time.sleep(25)

class SocketClient:
    def __init__(self,url,v_ip):

        logging.info("__init__")
        
        self.sio = socketio.Client(ssl_verify=False)
        self.url = url
        self.v_ip = v_ip

        @self.sio.event
        def connect():
            logging.info("  Conexión establecida    ")

        @self.sio.event
        def disconnect():
            logging.info("  Desconectado del servidor   ")
    
    def start(self):
        self.sio.connect(self.url,transports='websocket',namespaces=['/off_totem'])
    def stop(self):
        self.sio.disconnect()    


clock = inicio_hora()
def run_clock():
    try:
        clock.run()
    except:
        clock.inicio_reloj = False
        logging.exception("Ocurrió un error")


t = threading.Thread(target=run_clock)
if __name__ == '__main__':
    logging.info(' - INICIO CLOCK  : '+datetime.now().strftime("%d-%m-%Y %H:%M:%S"))
    # Inicia el reloj en un hilo separado
    t.start()
    t.join()
    app.run(host='0.0.0.0',port=8001)