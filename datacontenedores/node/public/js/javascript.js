$(document).ready(function() {
  let datestamp = Date.now();
  //console.log("datestamp  -> " ,datestamp);
  //document.getElementById("txt").innerHTML = datestamp;
  //console.log("pathname -> ",window.location.pathname);
  document.addEventListener('keydown', function(event) {
    if (event.key === "F9") {  js_borramemoria();  }
  });

  localStorage.getItem("last_numero_v1")  ===  null ? '':  $(".txt_ventinalla_1").html(localStorage.getItem("last_numero_v1"));
  localStorage.getItem("last_numero_v2")  ===  null ? '':  $(".txt_ventinalla_2").html(localStorage.getItem("last_numero_v2"));
  localStorage.getItem("last_numero_v3")  ===  null ? '':  $(".txt_ventinalla_3").html(localStorage.getItem("last_numero_v3"));
  localStorage.getItem("last_numero_v4")  ===  null ? '':  $(".txt_ventinalla_4").html(localStorage.getItem("last_numero_v4"));
  localStorage.getItem("last_numero_v5")  ===  null ? '':  $(".txt_ventinalla_5").html(localStorage.getItem("last_numero_v5"));

  load_ws();
  load_f11();

  if ('speechSynthesis' in window) {
    /*
    var texto = "Hola, ¿cómo estás?";
    var utterance = new SpeechSynthesisUtterance(texto);
    utterance.lang = 'es-ES';
    utterance.rate = 1.5;
    speechSynthesis.speak(utterance);
    console.log(texto);
    */
  }
});

function load_f11(){
  console.log("load_f11");
}

function load_ws(){
  //let v_ip_socket = "https://10.69.76.39:3000/tablero_ticket_resumen";
  let v_ip_socket = "https://10.68.159.13:3000/tablero_ticket_resumen";
  console.log("v_ip_socket  ->  ",v_ip_socket);
  const obj_socket = io(v_ip_socket,{
    reconnection:true, 
    reconnectionDelay:50000,
    transports:["websocket"],
    secure:false
  });
  console.log(obj_socket);
  obj_socket.on('connect',()=>{
    console.log("--------------------------------------------");
    console.log("obj_socket    -> ",obj_socket);
    //showNotification('top','center','Conexi&oacute;n con instancia de fila de farmacia',2,'fa fa-plug');
    ws_escuchando_actualizacion(obj_socket);
  });
  obj_socket.on('connect_error',(error)=>{
    console.log("  error -> ",error);
    //obj_socket.disconnect();
  });
  obj_socket.io.on("reconnect", (attempt) => {
   console.log("  error -> ",error);
  });
}

function ws_escuchando_actualizacion(obj_socket){
  obj_socket.on('actualizacion_tablero_resumen',function(data){
    console.log(" ------------------------------------------------------  ");
    console.log("   Actualziacion  ->  "+Date.now(),"  <- ->  ",data);
    $('#boton-pantalla-completa').click();
    let ind_ventanilla  = data.ind_ventanilla;
    let txt_subnumero   = data.txt_subnumero;
    console.log("---------------------------------------");
    console.log("ind_ventanilla   ->  ",ind_ventanilla);
    console.log("txt_subnumero    ->  ",txt_subnumero);


    switch (ind_ventanilla) {
      case "1":
          $(".txt_ventinalla_1").html(txt_subnumero);
          localStorage.setItem("last_numero_v1",txt_subnumero);
          load_parpadea(".txt_ventinalla_1");
        break;
      case "2":
          $(".txt_ventinalla_2").html(txt_subnumero);
          localStorage.setItem("last_numero_v2",txt_subnumero);
          load_parpadea(".txt_ventinalla_2");
        break;
      case "3":
          $(".txt_ventinalla_3").html(txt_subnumero);
          localStorage.setItem("last_numero_v3",txt_subnumero);
          load_parpadea(".txt_ventinalla_3");
        break;
      case "4":
          $(".txt_ventinalla_4").html(txt_subnumero);
          localStorage.setItem("last_numero_v4",txt_subnumero);
          load_parpadea(".txt_ventinalla_4");
        break;
      case "5":
          $(".txt_ventinalla_5").html(txt_subnumero);
          localStorage.setItem("last_numero_v5",txt_subnumero);
          load_parpadea(".txt_ventinalla_5");
        break;
      default:
        break;
    }
  });
}


function load_parpadea(txt_class){
  $(txt_class).addClass("parpadea");
  setTimeout(function() {
    $(txt_class).removeClass("parpadea");
  }, 5000);
}

function js_borramemoria(){
  console.log("js_borramemoria");
  localStorage.setItem("last_numero_v1","");
  localStorage.setItem("last_numero_v2","");
  localStorage.setItem("last_numero_v3","");
  localStorage.setItem("last_numero_v4","");
  localStorage.setItem("last_numero_v5","");
  $(".txt_ventinalla_1,.txt_ventinalla_2,.txt_ventinalla_3,.txt_ventinalla_4,.txt_ventinalla_5").html('');
}
