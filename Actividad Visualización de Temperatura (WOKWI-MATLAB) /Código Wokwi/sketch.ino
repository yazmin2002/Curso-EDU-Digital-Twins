/* ESP32 HTTP IoT Server Example for Wokwi.com
   Muestra Humedad y Temperatura en la página web

   Then start the simulation, and open http://localhost:9080 in another browser tab.
*/

#include <WiFi.h>
#include <WiFiClient.h>
#include <WebServer.h>
#include <uri/UriBraces.h>
#include <DHT.h>

// DHT configuration
#define DHTPIN 15          // Pin donde se conecta el sensor
#define DHTTYPE DHT22
DHT dht(DHTPIN, DHTTYPE);

// WiFi configuration
#define WIFI_SSID "Wokwi-GUEST"
#define WIFI_PASSWORD ""
#define WIFI_CHANNEL 6

WebServer server(80);

float humidity = 0.0;
float temperature = 0.0;
unsigned long lastReadTime = 0;
const unsigned long readInterval = 1000; // 1 segundo

void sendHtml() {
  String response = R"rawliteral(
    <!DOCTYPE html><html>
      <head>
        <title>ESP32 DHT22 Monitor</title>
        <meta name="viewport" content="width=device-width, initial-scale=1">
        <meta http-equiv="refresh" content="2">
        <style>
          html { font-family: sans-serif; text-align: center; padding-top: 30px; }
          body { background-color: #f2f2f2; }
          h1 { color: #333; margin-bottom: 0.3em; }
          .cards { display: inline-grid; grid-template-columns: 1fr 1fr; gap: 16px; }
          .card { background: white; padding: 18px 24px; border-radius: 12px; box-shadow: 0 4px 12px rgba(0,0,0,0.08); }
          .label { font-size: 0.9em; color: #777; }
          .value { font-size: 2em; margin-top: 6px; }
        </style>
      </head>
      <body>
        <h1>Lecturas DHT22</h1>
        <div class="cards">
          <div class="card">
            <div class="label">Humedad</div>
            <div class="value">%HUMIDITY%%</div>
          </div>
          <div class="card">
            <div class="label">Temperatura</div>
            <div class="value">%TEMP%&deg;C</div>
          </div>
        </div>
      </body>
    </html>
  )rawliteral";

  // Reemplazar placeholders con valores reales
  response.replace("%HUMIDITY%", String(humidity, 1));
  response.replace("%TEMP%", String(temperature, 1));
  server.send(200, "text/html", response);
}

void setup() {
  Serial.begin(115200);
  dht.begin();

  WiFi.begin(WIFI_SSID, WIFI_PASSWORD, WIFI_CHANNEL);
  Serial.print("Connecting to WiFi ");
  Serial.print(WIFI_SSID);
  while (WiFi.status() != WL_CONNECTED) {
    delay(100);
    Serial.print(".");
  }
  Serial.println(" Connected!");
  Serial.print("IP address: ");
  Serial.println(WiFi.localIP());

  server.on("/", sendHtml);
  server.begin();
  Serial.println("HTTP server started");
}

void loop() {
  server.handleClient();

  // Leer humedad y temperatura cada 1 segundo
  if (millis() - lastReadTime >= readInterval) {
    lastReadTime = millis();

    float h = dht.readHumidity();
    float t = dht.readTemperature(); // °C

    if (!isnan(h) && !isnan(t)) {
      humidity = h;
      temperature = t;

      Serial.print("Humedad: ");
      Serial.print(humidity, 1);
      Serial.print(" %  |  ");

      Serial.print("Temperatura: ");
      Serial.print(temperature, 1);
      Serial.println(" °C");
    } else {
      Serial.println("¡Fallo al leer el sensor DHT!");
    }
  }
}
