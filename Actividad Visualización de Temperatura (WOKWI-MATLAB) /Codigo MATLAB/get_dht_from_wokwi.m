%% Función de lectura: get_dht_from_wokwi
% Esta función se encarga de leer la página HTML que genera el Wokwi Gateway
% y extraer los valores de humedad (%) y temperatura (°C) mostrados en pantalla.
% Es compatible tanto con etiquetas en español ("Humedad", "Temperatura")
% como en inglés ("Humidity", "Temperature").

function [hum,temp] = get_dht_from_wokwi(url)
    % Uso:
    %   [hum,temp] = get_dht_from_wokwi("http://localhost:9080")
    %
    % Parámetros:
    %   url : dirección del servidor HTTP del Wokwi Gateway (string)

    arguments
        url (1,1) string = "http://localhost:9080"
    end

    % --- Leer HTML de la URL ---
    html = webread(url);  % requiere Gateway activo

    % --- Expresiones regulares para Humedad y Temperatura ---
    tokH = regexp(html,'(Humedad|Humidity)[\s\S]*?<div class="value">([\d\.\-]+)%</div>','tokens','once');
    tokT = regexp(html,'(Temperatura|Temperature)[\s\S]*?<div class="value">([\d\.\-]+)&deg;C</div>','tokens','once');

    % --- Validación de tokens ---
    if isempty(tokH) || isempty(tokT)
        error('No pude extraer valores. ¿La página muestra Humedad/Temperatura con clase "value"?');
    end

    % --- Conversión a números ---
    hum  = str2double(tokH{2});
    temp = str2double(tokT{2});

    % --- Validación final ---
    if isnan(hum) || isnan(temp)
        error('Lectura inválida (NaN). Verificá que la página muestre números.');
    end
end
