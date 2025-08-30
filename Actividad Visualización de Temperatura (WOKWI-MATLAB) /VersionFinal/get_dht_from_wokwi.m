function [hum,temp] = get_dht_from_wokwi(url)
% Lee la página HTML del ESP32 (Wokwi IoT Gateway) y extrae Humedad/Temperatura.
% Uso: [hum,temp] = get_dht_from_wokwi("http://localhost:9080")

    arguments
        url (1,1) string = "http://localhost:9080"
    end

    html = webread(url);  % requiere gateway activo

    % Español o inglés
    tokH = regexp(html,'(Humedad|Humidity)[\s\S]*?<div class="value">([\d\.\-]+)%</div>','tokens','once');
    tokT = regexp(html,'(Temperatura|Temperature)[\s\S]*?<div class="value">([\d\.\-]+)&deg;C</div>','tokens','once');

    if isempty(tokH) || isempty(tokT)
        error('No pude extraer valores. ¿La página muestra Humedad/Temperatura con clase "value"?');
    end

    hum  = str2double(tokH{2});
    temp = str2double(tokT{2});

    if isnan(hum) || isnan(temp)
        error('Lectura inválida (NaN). Verificá que la página muestre números.');
    end
end
