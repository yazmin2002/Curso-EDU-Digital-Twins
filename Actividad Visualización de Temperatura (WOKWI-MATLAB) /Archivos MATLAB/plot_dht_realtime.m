function plot_dht_realtime(dbPath, refresh_s)
% Grafica Humedad y Temperatura en "tiempo real" leyendo de la base SQLite.
% dbPath    : ruta a la base (ej. "sensor_readings.db")
% refresh_s : intervalo de actualización en segundos

    arguments
        dbPath (1,1) string = "sensor_readings.db"
        refresh_s (1,1) double = 2
    end

    % --- Abrir base
    db = sqlite(dbPath,"connect");
    cleaner = onCleanup(@() close(db));

    % --- Crear figuras
    figure('Name','DHT22 en tiempo real');
    t_hum = animatedline('Color',[0 .6 1],'LineWidth',1.5); % azul
    t_temp = animatedline('Color',[1 .2 .2],'LineWidth',1.5); % rojo
    legend('Humedad (%)','Temperatura (°C)','Location','best');
    xlabel('Tiempo'); ylabel('Valor');
    grid on;

    % --- Bucle infinito (Ctrl+C para parar)
    last_id = 0;
    fprintf('Graficando en tiempo real (Ctrl+C para detener)...\n');
    while true
        % Traer solo los nuevos registros desde la última vez
        sql = sprintf([ ...
            "SELECT id, ts, " ...
            "CAST(humidity AS REAL) AS hum, " ...
            "CAST(temperature AS REAL) AS temp " ...
            "FROM dht_readings WHERE id > %d ORDER BY id ASC;"], last_id);
        data = fetch(db, sql);

        if ~isempty(data)
            if istable(data)
                tsRaw = string(data.ts);
                hum   = double(data.hum);
                temp  = double(data.temp);
                ids   = double(data.id);
            else
                tsRaw = string(data(:,2));
                hum   = str2double(string(data(:,3)));
                temp  = str2double(string(data(:,4)));
                ids   = cell2mat(data(:,1));
            end

            % Parsear timestamps
            try
                ts = datetime(tsRaw, 'InputFormat',"yyyy-MM-dd'T'HH:mm:ss.SSS", ...
                                       'TimeZone','America/Montevideo');
            catch
                ts = datetime(tsRaw, 'InputFormat',"yyyy-MM-dd'T'HH:mm:ss", ...
                                       'TimeZone','America/Montevideo');
            end

            % Agregar puntos al gráfico
            addpoints(t_hum, ts, hum);
            addpoints(t_temp, ts, temp);

            % Actualizar último id
            last_id = max(ids);

            % Ajustar ejes
            datetick('x','HH:MM:SS');
            xlim([min(ts) max(ts) + seconds(10)]);
            drawnow limitrate;
        end

        pause(refresh_s); % esperar antes de consultar de nuevo
    end
end
