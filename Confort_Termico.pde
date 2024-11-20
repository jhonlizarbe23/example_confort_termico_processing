import processing.serial.*;
import controlP5.*;

Serial serialPortConfigurated;
ControlP5 cp5;

String receivedData = "";
boolean isLogging = false;
PrintWriter output;
boolean isFoundPorts = false;
String[] portsFound = {};
ArrayList<Serial> openSerials = new ArrayList<>();
int counterDraw = 1;
boolean isPortConfigurated = false;
int displayNumber = 0;

PFont fontLarge, fontSmall, fontMedium;

boolean recording = false; // Estado del grabador

// Valores por defecto
String temperature = "0";
String humidity= "0";
String pressure = "0";
String co2 = "0";

String statusTemperature = "OK";
String statusHumidity= "OK";
String statusPressure = "OK";
String statusCo2 = "OK";

void setup() {
  size(380, 600);
   background(255);
  fontLarge = createFont("CalculatorFont.ttf", 60); // Fuente grande para los números
  fontSmall = createFont("Avignon Pro Medium", 20); // Fuente pequeña para los símbolos
  fontMedium = createFont("Avignon Pro Medium", 25); 
  
  cp5 = new ControlP5(this);
  
  // Validar puertos
  while(!isFoundPorts){
    checkingPorts();
  }
  
  // Abriendo puertos disponibles
  openingPortsToListen();
}

void draw() {
 
  float sectionHeight = height / 5.0; // Divide la pantalla en 5 partes iguales

  // Sección 1: Temperatura
  drawTemperatura(sectionHeight);
 
  // Sección 2: Humedad
  drawHumedad(sectionHeight);

  // Sección 3: Presión
  drawPresion(sectionHeight);

  // Sección 4: CO2
  drawCo2(sectionHeight);
 
  // Sección 5: Botón de grabación
  drawButtonRecording(sectionHeight);
  
  
   if(!isPortConfigurated){
    configurePortToListen();
  }
  
  if(isPortConfigurated){
    String datoRecibido = showDataReceived(serialPortConfigurated);
    if(datoRecibido != null){
      String[] data = split(receivedData, '.');
      if(data != null && data.length > 2){
       String status = data[0];
        String typeValue = data[1];
        String value = data[2];
        
        switch(typeValue) {
          case "Temperatura":
            temperature = value;
            statusTemperature = status;
            break;
          case "Humedad":
            humidity = value;
            statusHumidity = status;
            break;
          case "Presion":
            pressure = value;
            statusPressure = status;
            break;
          case "CO2":
            co2 = value;
            statusCo2 = status;
            break;
          default:             // Default executes if the case names
            println("None");   // don't match the switch parameter
            break;
        }
               
      }
    }
  }
  
}

void drawTemperatura(float sectionHeight){
    fill(#424242); // Color para la sección de temperatura
    stroke(255);
    rect(0, 0, width, sectionHeight);
    fill(statusTemperature.equals("OK") ? #76FF03:#C62828);
    textAlign(LEFT, CENTER);
    textFont(fontSmall);
    text("Temperatura", 20, sectionHeight / 2);
    textAlign(RIGHT, CENTER);
    textFont(fontLarge);
    text(temperature, width - 100, sectionHeight / 2);
    textFont(fontMedium);
    text("°C",  width - 40, sectionHeight / 2);

}

void drawHumedad(float sectionHeight){
    fill(#424242); // Color para la sección de humedad
    rect(0, sectionHeight, width, sectionHeight);
    fill(statusHumidity.equals("OK") ? #76FF03:#C62828);
    textAlign(LEFT, CENTER);
    textFont(fontSmall);
    text("Humedad", 20, sectionHeight * 1.5);
    textAlign(RIGHT, CENTER);
    textFont(fontLarge);
    text(humidity, width - 100, sectionHeight * 1.5);
    textFont(fontMedium);
    text(" %", width - 40, sectionHeight * 1.5);

}

void drawPresion(float sectionHeight){
  fill(#424242); // Color para la sección de presión
  rect(0, sectionHeight * 2, width, sectionHeight);
  fill(statusPressure.equals("OK") ? #76FF03:#C62828);
  textAlign(LEFT, CENTER);
  textFont(fontSmall);
  text("Presión", 20, sectionHeight * 2.5);
  textAlign(RIGHT, CENTER);
  textFont(fontLarge);
  text(pressure, width - 100, sectionHeight * 2.5);
  textFont(fontMedium);
  text("mb", width - 30, sectionHeight * 2.5);
}

void drawCo2(float sectionHeight){
  fill(#424242); // Color para la sección de CO2
  rect(0, sectionHeight * 3, width, sectionHeight);
  fill(statusCo2.equals("OK") ? #76FF03:#C62828);
  textAlign(LEFT, CENTER);
  textFont(fontSmall);
  text("Nivel CO2", 20, sectionHeight * 3.5);
  textAlign(RIGHT, CENTER);
  textFont(fontLarge);
  text(co2, width - 100, sectionHeight * 3.5);
  textFont(fontMedium);
  text("ppm", width - 20, sectionHeight * 3.5);
}

void drawButtonRecording(float sectionHeight){
  fill(#424242); // Color para la sección de grabación
  
  rect(0, sectionHeight * 4, width, sectionHeight);
  
  // Dibuja el botón redondo
  stroke(#C62828);
  fill(recording ? #F44336 : #FF5252); // Rojo si está grabando, gris si no
  stroke(255);
  ellipse(width -85 , sectionHeight * 4.5, 50, 50);
  
  
  fill(#76FF03);
  textSize(16);
  textAlign(LEFT, CENTER);
  textFont(fontSmall);
  text(recording ? "Registrando..." : "Registrar datos", 20, sectionHeight * 4.5);
}

// Detecta si se hace clic en el botón de grabación
void mousePressed() {
  float sectionHeight = height / 5.0;
  float botonX = width -85;
  float botonY = sectionHeight * 4.5;
  float botonRadio = 25; // Radio del botón
  
  // Verifica si el clic ocurrió dentro del botón
  if (dist(mouseX, mouseY, botonX, botonY) < botonRadio) {
    recording = !recording; // Alterna el estado de grabación
  }
  
  if(isPortConfigurated){
    isLogging = recording;
    if (isLogging) {
      output = createWriter("data_log_example.txt");
    } else {
      output.flush();
      output.close();
    }
  }else{
    println("No hay un puerto configurado para poder almacenar datos.");
  }
}

void checkingPorts(){
  println("");
  println("BUSCANDO PUERTOS...");
  if(Serial.list() != null && Serial.list().length > 0){
    isFoundPorts = true;
    println("Puertos encontrados:");
    printArray(Serial.list());
    portsFound = Serial.list();
    
  } else {
     println("No se encontraron puertos.");
  }
  
}


void openingPortsToListen(){
  println("");
  println("ABRIENDO PUERTOS...");
  if(openSerials.size() < portsFound.length){
   for(int i=0; i<=portsFound.length-1; i++){
       try{
          println("Abriendo puerto: "+portsFound[i]);
          Serial portSerialData = new Serial(this, portsFound[i], 9600);
          openSerials.add(portSerialData);
          println(">> Success"); 
       }catch (RuntimeException ex){
         println(">> Ocurrió un error: "+ex.getMessage()); 
       }
    }
  }
}

void configurePortToListen(){
  for(int i=0;i<=openSerials.size()-1;i++){
    if(openSerials.get(i).available() > 0){
      serialPortConfigurated = openSerials.get(i);
      isPortConfigurated = true;
       println(">> Success port configurated!");
       println("");
       println("OBTENIENDO DATOS...");
    }
  }
}

String showDataReceived(Serial serialPort){
  if (serialPort.available() > 0) {
    receivedData = serialPort.readStringUntil('\n');
    if (receivedData != null) {
      receivedData = trim(receivedData);
      if (isLogging) {
        output.println(receivedData);
      }
      return receivedData;
    }
  }
  
  return null;
}
