function T = plot_dht_history(dbPath)
% Lee toda la tabla y grafica Humedad y Temperatura vs tiempo.
% Devuelve un timetable con los datos.

    arguments
        dbPath (1,1) string = "sensor_readings.db"
    end

    % Abrir DB
    db = sqlite(dbPath,"connect");
    cleaner = onCleanup(@() close(db));

    % --- Consulta SQL en un SOLO string + CAST a REAL
    sql = [
        "SELECT ts, "
        "CAST(humidity AS REAL) AS humidity, "
        "CAST(temperature AS REAL) AS temperature "
        "FROM dht_readings ORDER BY id ASC;"
    ];
    sql = strjoin(sql, "");                  % <- clave: un único string
    data = fetch(db, sql);

    if isempty(data)
        warning('No hay datos en la tabla dht_readings.');
        T = timetable();
        return;
    end

    % --- Normalizar a tabla y extraer columnas
    if istable(data)
        tsRaw = string(data.ts);
        hum   = double(data.humidity);
        temp  = double(data.temperature);
    else
        % Si viniera como celda
        tsRaw = string(data(:,1));
        hum   = str2double(string(data(:,2)));
        temp  = str2double(string(data(:,3)));
    end

    % --- Parsear timestamps (formato que usabas originalmente)
    % Si tu 'ts' no tiene milisegundos, cambiá a "yyyy-MM-dd'T'HH:mm:ss"
    ts = datetime(tsRaw, ...
        'InputFormat',"yyyy-MM-dd'T'HH:mm:ss.SSS", ...
        'TimeZone','America/Montevideo');

    % --- Crear timetable y graficar
    T = timetable(ts, hum, temp, 'VariableNames', {'Humidity','Temperature'});

    figure;          % Humedad
    plot(T.ts, T.Humidity, 'LineWidth', 1.5);
    xlabel('Tiempo'); ylabel('Humedad (%)'); title('Humedad vs Tiempo'); grid on;

    figure;          % Temperatura
    plot(T.ts, T.Temperature, 'LineWidth', 1.5);
    xlabel('Tiempo'); ylabel('Temperatura (°C)'); title('Temperatura vs Tiempo'); grid on;
end
