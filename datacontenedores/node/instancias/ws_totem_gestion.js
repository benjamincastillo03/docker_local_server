module.exports = function(io){
    const space_totems_control                =   io.of('/instancia_ventanilla_esissan');
    let arr_listas_dispositivos               =   [];
    const oracledb                            =   require('oracledb');
    //console.log("   oracledb.versionString ->  ",oracledb.versionString);
    //export ORACLE_HOME="/home/app/instantclient_12_2/";
    space_totems_control.on('connection',function(socket){
        console.log("--------------------------------------------");
        console.log("cliente ingresando a room_all_cliente");
        console.log("* INSTANCIA DE VENTANILLAS     ->",Date.now());
        const handshakeData                   =   socket.request;
        const v_unique                        =   handshakeData._query['unique'];
        const v_empresa                       =   handshakeData._query['empresa'];
        const v_id_uid                        =   handshakeData._query['ID_UID'];
        console.log("ID_UID                         ->  ",v_id_uid);
        console.log("v_empresa                      ->  ",v_empresa);
        console.log("unique                         ->  ",v_unique);
        //console.log(oracledb.versionString);
        console.log("---------------------------------------------");
        console.log("---------------------------------------------");
        console.log("---------------------------------------------");
        socket.join("room_all_cliente");
        socket.join(v_id_uid);
        socket.on('totem_farmacia:comunicacion_totem_ping_pong',(data)=>{
            console.log("-----------------------------------------------------------------------");
            console.log("control remoto                 ->  ",data);
            io.of('/instancia_totem_wpf').to(data.txt_room).emit("totem_escuchando_ping",data.v_id_uid);
        });
        
        socket.join(v_id_uid,(error) => {
            if(error){ console.error(error); } else { 
                console.log("Entrada a room individual    -> ",v_id_uid);
            }
        });

        socket.join("room_gestion_all_totem",(error) => {
            if(error){ console.error(error); } else {    console.log("Entrada a room global        -> ","room_gestion_all_totem");}
        });
        
        socket.on('gestion_filas_farmacia:notifica_cambio',(_info_get)=>{
            console.log("***********************************************************");
            console.log("  NOTIFICA CAMBIOS DE TICKET A DEMAS VENTANILLAS  ->   ",_info_get);
            socket.broadcast.to("room_gestion_all_totem").emit("gestion_filas_farmacia:cambio_avisado_actualziar",_info_get);
            console.log("  RESUMEN DE TABLE                                 ->  ",_info_get);
            io.of('/tablero_ticket_resumen').to("room_resumen_ventanillas").emit("actualizacion_tablero_resumen",_info_get);
        });

        socket.on('totem_farmacia:impresion_ticket',(data)=>{
            console.log("--------------------------------------------------");
            console.log("print desde la esissan al totem  -> ",data);
            let txt_rooom  = data.arr_room.join(",");
            io.of('/instancia_totem_wpf').to(txt_rooom).emit("imprimir_ticket_totem",data.txt_impr);
        });

        //socket.join(v_ip_totem);
        socket.on('totem_farmacia:anuncia_nuevo_paciente',(get_totem_mac)=>{
            console.log("   getNuevoTicket  ->  ",get_totem_mac);
            //getNuevoTicket(socket,JSON.parse(get_totem_mac));
        });

        socket.on('totem_farmacia:anuncio_de_audio_texto',(data)=>{
            io.of('/instancia_totem_wpf').to(data.txt_room).emit("app_totem_defaul_api_voz",data.v_txt_audio);
        });

        socket.on('totem_farmacia:cambio_pagina',(data)=>{
            io.of('/instancia_totem_wpf').to(data.txt_room).emit("app_totem_cambio_pagina_get",data.v_ind_pagina);
        });

        socket.on('totem_farmacia:opciones_generales_windows',(data)=>{
            console.log("data :",data);
            if (data._opcion_windows == "0"){
                io.of('/instancia_totem_wpf').to(data.txt_room).emit("app_totem_full_scream_get","1");
            }
            if (data._opcion_windows == "1"){
                io.of('/instancia_totem_wpf').to(data.txt_room).emit("app_totem_win_Minimize_get","1");   
            }
            //no subido
            if (data._opcion_windows == "3"){
                io.of('/instancia_totem_wpf').to(data.txt_room).emit("app_totem_win_Apagado","1");   
            }
        });

        socket.on('totem_farmacia:llamada_ticketxventanilla',(data)=>{
            let arr_room = [];
            if(data.arr_totem_call.length > 0){
                data.arr_totem_call.forEach(function(valor,indice,array) {
                    arr_room.push(valor);
                });
            }
            console.log("llamada_ticketxventanilla");
            console.log(arr_room);
            console.log(arr_room.join(","));
            io.of('/instancia_totem_wpf').to(arr_room).emit("escucha_llamado_ticket",JSON.stringify(data));   
        });

        socket.on('disconnect',()=>{
            console.log("   desconexion -> instancia_ventanilla_esissan -> ",Date.now());
            socket.disconnect();
        });

        async function ini_bd(){
            let connection;
            try {
                connection = await oracledb.getConnection({
                    user: "admin",
                    password: "ssprueba.210",
                    connectString: "oracle:1521/XEPDB1"
                });
                console.log("   ----------------------------    ");    
                console.log("   Conectado con éxito a Oracle ");
            } catch (err) {
                console.error("error 1 ->  ",err);
                } finally {
                    if (connection) {
                    try {
                        await connection.close();
                    } catch (err) {
                        console.error("error 2 ->  ",err);
                    }
                }
            }
        }

    });
}  