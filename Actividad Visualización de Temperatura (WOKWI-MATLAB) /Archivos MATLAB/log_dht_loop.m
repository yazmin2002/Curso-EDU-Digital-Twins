function log_dht_loop(varargin)
% Lee de http://localhost:9080 cada "period_s" y guarda en SQLite.
% Uso básico:
%   log_dht_loop
% Parámetros opcionales (par nombre-valor):
%   "URL", "http://localhost:9080"
%   "DB",  "sensor_readings.db"
%   "period_s", 2
%   "duration_s", Inf    % o un número p.ej. 600 para 10 minutos

    p = inputParser;
    addParameter(p,"URL","http://localhost:9080",@(s)ischar(s) || isstring(s));
    addParameter(p,"DB","sensor_readings.db",@(s)ischar(s) || isstring(s));
    addParameter(p,"period_s",2,@(x)isnumeric(x) && x>0);
    addParameter(p,"duration_s",Inf,@(x)isnumeric(x) && x>0);
    parse(p,varargin{:});

    url        = string(p.Results.URL);
    dbPath     = string(p.Results.DB);
    period_s   = p.Results.period_s;
    duration_s = p.Results.duration_s;

    % Abrir BD
    db = open_or_init_db(dbPath);
    cleaner = onCleanup(@() close(db));

    tz = "America/Montevideo";  % tu zona
    t0 = tic;

    fprintf('Iniciando log. URL=%s | DB=%s | cada %.1fs | duración %s.\n',...
        url, dbPath, period_s, ternary(isinf(duration_s),"∞",sprintf('%.0fs',duration_s)));

    N = 0;
        N = 0;
    while toc(t0) < duration_s
        % 1) LECTURA HTTP
        try
            [h, t] = get_dht_from_wokwi(url);
        catch ME
            warning('Fallo de LECTURA HTTP: %s', ME.message);
            pause(period_s);
            continue; % saltar a la próxima iteración si no hay datos
        end

        % 2) TIMESTAMP + INSERT
        try
            ts = datetime('now','TimeZone',tz);
            ts_iso = char(datestr(ts,'yyyy-mm-ddTHH:MM:SS.FFF'));  %#ok<DATST>

            exec(db, sprintf("INSERT INTO dht_readings (ts,humidity,temperature) VALUES ('%s', %f, %f);", ts_iso, h, t));

            N = N + 1;
            fprintf('[%s] Hum: %.1f %% | Temp: %.1f °C\n', ts_iso, h, t);
        catch ME
            warning('Fallo de INSERT en SQLite: %s', ME.message);
        end

        pause(period_s);
    end


    fprintf('Finalizado. %d muestras almacenadas.\n', N);
end

function out = ternary(cond,a,b)
    if cond, out=a; else, out=b; end
end
