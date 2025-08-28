function db = open_or_init_db(dbPath)
% Abre (o crea) una base SQLite y garantiza la tabla dht_readings.

    arguments
        dbPath (1,1) string = "sensor_readings.db"
    end

    db = sqlite(dbPath,"create");  % crea si no existe

    % Crear tabla si no existe
    sql = [
        "CREATE TABLE IF NOT EXISTS dht_readings (" + ...
        "id INTEGER PRIMARY KEY AUTOINCREMENT," + ...
        "ts TEXT NOT NULL," + ...              % ISO8601 con zona
        "humidity REAL NOT NULL," + ...
        "temperature REAL NOT NULL" + ...
        ");"
    ];
    exec(db, sql);
end
