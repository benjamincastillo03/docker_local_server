module.exports = function(io){
    const space_nuevo_ticket                        =   io.of('/instancia_totem_wpf');
    const oracledb                                  =   require('oracledb');

    space_nuevo_ticket.on('connection',function(socket){
        
        const handshakeData                         =   socket.request;
        const v_totem                               =   handshakeData._query['totem'];
        const v_ip_totem                            =   handshakeData._query['ip_totem'];
        const v_mac_totem                           =   handshakeData._query['mac_totem'];
        
        console.log("___________________________________________________________");
        console.log("* INSTANCIA DE TOTEMS EN WPF   =>  ",Date.now());
        console.log("___________________________________________________________");
        console.log("   v_totem                     =>  ",v_totem,"             ");
        console.log("   v_ip_totem                  =>  ",v_ip_totem,"          ");
        console.log("   v_mac_totem                 =>  ",v_mac_totem,"         ");
        console.log("   oracledb                    =>  ",oracledb);
        console.log("___________________________________________________________");

        socket.join(v_ip_totem,(error) => {
            if(error){ console.error(error); } else { 
                console.log("Entrada a totem a room -> ",v_ip_totem);
            }
        });

        socket.on('respuesta_pong_esissan',data=> {
            const _result   =   JSON.parse(data);
            console.log("   --------------------------------------------    ");
            console.log("   instancia_totem_wpf ->  instancia_ventanilla_esissan ->  ",_result);
            io.of('/instancia_ventanilla_esissan').to(_result._id_cliente).emit("respuesta_del_totem_esissan",data);
        });

        socket.on('app_totem_default_callpaciente',(get_totem_mac)=>{
            console.log("----------------------------------------------------");
            const v_json_out            = JSON.parse(get_totem_mac);
            console.log("string      => ",get_totem_mac);
            console.log("v_json_out  => ",v_json_out);
            socket.to(v_json_out._id_mac).emit('app_totem_defaul_api_voz',get_totem_mac); 
        });

        socket.on('app_totem_full_scream_set',(get_totem_mac)=>{
            console.log("----------------------------------------------------");
            console.log("fapp_totem_full_scream_set      => ",get_totem_mac);
            socket.to(get_totem_mac).emit('app_totem_full_scream_get',{}); 
        });

        socket.on('app_totem_win_Minimize_set',(get_totem_mac)=>{
            console.log("----------------------------------------------------");
            console.log("app_totem_win_Minimize_set      => ",get_totem_mac);
            socket.to(get_totem_mac).emit('app_totem_win_Minimize_get',{}); 
        });

        socket.on('app_totem_cambio_pagina_set',(get_totem_mac)=>{
            console.log("----------------------------------------------------");
            const v_json_out            = JSON.parse(get_totem_mac);
            console.log("app_totem_cambio_pagina_set      => ",get_totem_mac);
            socket.to(v_json_out._id_mac).emit('app_totem_cambio_pagina_get',get_totem_mac); 
        });
        socket.on('anunciNuevoTicket',data=> {
            const _result = JSON.parse(data);
            console.log("   anunciNuevoTicket   -> ",_result);
            socket.emit("imprimir_ticket_totem",_result.txt_subnumero);
            io.of('/instancia_ventanilla_esissan').emit('totem_farmacia:anuncia_nuevo_paciente_admin',_result.ind_propidad);
        });
        socket.on('emite_nuevo_ticket',data=> {
            const _result = JSON.parse(data);
            console.log("   emite_nuevo_ticket  ",_result);
            getNuevoTicket(socket,_result);
        });

        async function getNuevoTicket(socket,arr_json){
            let arr_datos_ticket    =   [];
            try {
                const connection    =   await oracledb.getConnection({
                                            user: "admin",
                                            password: "ssprueba.210",
                                            connectString: "oracle:1521/XEPDB1"
                                        });
                console.log("-----------------------------------------------");
                console.log("   conexion a la base de datos exitosa         ");
                console.log("-----------------------------------------------");
                
                connection.execute('BEGIN ADMIN.HOSP_GESTION_TOTEMS.NUEVO_TICKET_FARMACIA(:VAL_ID_EVENTO,:C_LISTADO_FILAS); END;',{
                        VAL_ID_EVENTO       :   arr_json._id_priopiedad,
                        C_LISTADO_FILAS     :   { dir: oracledb.BIND_OUT, type: oracledb.CURSOR }
                    },  function(err,result){
                        //async
                        if (err){
                            doRelease(connection);
                            return [];
                        }
                        //return result.outBinds;
                        //const cursor = result.outBinds.C_LISTADO_FILAS;
                        //const data = await cursor.getRows();
                        //console.log("rows  cursor cursor  ->  ",cursor,"    ");
                        //await cursor.close();
                        //porque sale asi =D
                        result.outBinds.C_LISTADO_FILAS.getRows(10,(err,rows) => {
                            const result_ticket ={
                                'ind_propidad'  :   rows[0][0],
                                'num_unico'     :   rows[0][1],
                                'txt_subnumero' :   rows[0][2],
                                'fecha_print'   :   rows[0][3],
                            };
                            salida_ticket(socket,result_ticket,arr_json);
                        });
                        doRelease(connection);
                        return arr_datos_ticket;
                    }
                );
            } catch (err) {
                console.error(" ",err);
                return [];
            } finally  {
                console.log("finally");
            }
        }
        socket.on('disconnect',()=>{
            console.log("   desconexion -> instancia_totem_wpf -> ",Date.now());
            socket.disconnect();
        });

    });

    function salida_ticket(socket,ticket,arr_json){
        console.log("----------------------------------------------------------");
        console.log("   Se creo el ticket  ->  ",ticket,"      <-              ");
        console.log("----------------------------------------------------------");
        socket.emit("imprimir_ticket_totem",ticket.txt_subnumero);
        io.of('/instancia_ventanilla_esissan').emit('totem_farmacia:anuncia_nuevo_paciente_admin',ticket.ind_propidad);
    }

    function doRelease(connection) {
        connection.close(function(err) {
            if (err) {  console.error(err.message);  }
        });
    }
}  