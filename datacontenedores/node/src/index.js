const fs 				= 	require('fs');
const https 			= 	require('https');
const socketIO 			= 	require('socket.io');
const express 			= 	require('express');
const path 				= 	require('path');
const forge 			=	require('node-forge');
const app 				= 	express();
app.set('port',process.env.PORT||3000);
app.use(express.static('public'));
//Cargar la clave privada y el certificado
const privateKey 					= 	fs.readFileSync(__dirname+'/cer_development/clave-privada.key','utf8');
const certificate 					= 	fs.readFileSync(__dirname+'/cer_development/certificado-autofirmado.crt','utf8');
//const privateKey 					= 	fs.readFileSync(__dirname+'/certificado/key.pem','utf8');
//const certificate 				= 	fs.readFileSync(__dirname+'/certificado/cert.pem','utf8');
const credentials 					= 	{ key:privateKey, cert:certificate };
//Crear el servidor HTTPS
const server 						= 	https.createServer(credentials, app);



/*
app.get('/update_nuget', (req, res) => {
	console.log("__dirname -> ",__dirname);
	const filePath = path.join(__dirname,'files','wpf_vista_totem-1.0.0-full.nupkg');
	res.sendFile(filePath, (err) => {
	    if (err) {
	      console.error("Error al enviar el archivo:", err);
	      res.status(500).send('Error interno del servidor');
	    } else {
	      console.log("Archivo enviado con exito");
	    }
  	});
});
*/



app.get('/tablero',async(_req,res) => {
	console.log("	********************	");
	console.log("	*	get tablero 	*	");
	console.log("Date.now -> ",Date.now());
	console.log(process.cwd());
	console.log(__dirname);
	return res.sendFile(__dirname + "/www/index.html");
});

// Iniciar el servidor
server.listen(app.get('port'),() => {
	console.log(" 	------------------------------------------------------------------------------");
    console.log(" 	->UP SOCKET.SocketIO");
    console.log("	->",process.cwd());
 	console.log("	->",__dirname);
	console.log(" 	->El puerto que estoy configurando  ----> ", app.get('port'));
    console.log(" 	->Vesion | socket.io@4.0.0-");
    console.log(" 	------------------------------------------------------------------------------");
});

//*********************************************************************
const io 							= 	socketIO(server);
const space_instancia_test  		=   io.of('/mi_primera_instancia');
space_instancia_test.on('connection',function(socket){
    console.log("Entrando a instancia de prueba -> ",Date.now());
});

const space_tablero_ticket_resumen  =   io.of('/tablero_ticket_resumen');
space_tablero_ticket_resumen.on('connection',function(socket){
	console.log("Conexion add room_resumen_ventanillas	->	",Date.now());
    socket.join("room_resumen_ventanillas");
});

const off_totem		=	io.of('/off_totem');
off_totem.on('connection',function(socket){
	console.log("Conexion add off_totem	->	",Date.now());
    socket.join("off_totem");
    const handshakeData     =	socket.request;
	const ip  		= 	handshakeData._query['ip'];
	console.log(ip);
	io.of('/instancia_totem_wpf').to(ip).emit("app_totem_win_Apagado","1");
});


const directoryPath 				= 	'./instancias';
require(path.join(process.cwd(),'/instancias/ws_totem_gestion.js'))(io); 
require(path.join(process.cwd(),'/instancias/ws_totem_ticket_fila.js'))(io); 

