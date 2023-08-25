FROM node:19

WORKDIR /tmp
	RUN apt-get update && apt-get -y upgrade && apt-get -y dist-upgrade && apt-get install -y alien libaio1
	RUN wget https://yum.oracle.com/repo/OracleLinux/OL7/oracle/instantclient/x86_64/getPackage/oracle-instantclient19.3-basiclite-19.3.0.0.0-1.x86_64.rpm
	RUN alien -i --scripts oracle-instantclient*.rpm
	RUN rm -f oracle-instantclient19.3*.rpm && apt-get -y autoremove && apt-get -y clean

RUN npm install -g nodemon
RUN mkdir -p /home/app
WORKDIR /home/app
EXPOSE 3000

CMD ["npm", "run", "dev"]