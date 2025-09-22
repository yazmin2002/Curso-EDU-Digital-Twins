% Guarda como: run_dht_live.m
% Requiere: get_dht_from_wokwi(url) en el path.
% Ejemplo:
%   run_dht_live("http://localhost:9080", 0.5, minutes(10))

function run_dht_live(url, period_s, window_len)
    %-------------------- Parámetros por defecto ---------------------------
    if nargin < 1 || strlength(url)==0, url = "http://localhost:9080"; end
    if nargin < 2 || isempty(period_s), period_s = 1.0;                end
    if nargin < 3 || isempty(window_len), window_len = minutes(5);     end
    if ~isduration(window_len)
        error("window_len debe ser 'duration' (ej: minutes(5))");
    end

    tz = 'America/Montevideo';

    %-------------------- Figura y ejes -----------------------------------
    fig = figure('Name','DHT22 - Live','NumberTitle','off');
    tlo = tiledlayout(fig,2,1,'TileSpacing','compact','Padding','compact');

    ax1 = nexttile(tlo,1);
    grid(ax1,'on'); ylabel(ax1,'Humedad (%)');
    ylim(ax1,[0 100]);

    ax2 = nexttile(tlo,2);
    grid(ax2,'on'); ylabel(ax2,'Temperatura (°C)'); xlabel(ax2,'Hora');
    ylim(ax2,[-40 80]);

    sg = sgtitle(tlo, 'DHT22 Live');
    
    % Botón STOP
    btn = uicontrol('Style','togglebutton','String','Stop','Units','normalized', ...
                    'Position',[0.92 0.94 0.06 0.05],'FontWeight','bold','BackgroundColor',[1 0.8 0.8]);

    %-------------------- Buffers -----------------------------------------
    ts   = NaT(0,1);  ts.TimeZone = tz;
    hums = zeros(0,1);
    tmps = zeros(0,1);

    fprintf('Live iniciado. URL=%s | periodo=%.3fs | ventana=%s\n', url, period_s, char(window_len));
    fprintf('Cerrar la figura o presionar "Stop" para finalizar.\n');

    %-------------------- Bucle principal ---------------------------------
    lastTick = tic;
    while isvalid(fig) && ishandle(btn) && (get(btn,'Value') == 0)
        nowTs = datetime('now','TimeZone',tz);

        % Lectura
        try
            [h, t] = get_dht_from_wokwi(url);  % h: %, t: °C
            if ~isscalar(h) || ~isscalar(t), error('Valores no escalares'); end
        catch ME
            warning('Lectura falló: %s', ME.message);
            h = NaN; t = NaN;
        end

        % Filtrar por rangos físicos (fuera de rango -> NaN)
        if ~(isfinite(h) && h>=0 && h<=100), h = NaN; end
        if ~(isfinite(t) && t>=-40 && t<=80), t = NaN; end

        % Append
        ts(end+1,1)   = nowTs;        %#ok<AGROW>
        hums(end+1,1) = h;            %#ok<AGROW>
        tmps(end+1,1) = t;            %#ok<AGROW>

        % Ventana deslizante por TIEMPO
        tMin = nowTs - window_len;
        idx  = ts >= tMin;
        ts   = ts(idx);
        hums = hums(idx);
        tmps = tmps(idx);

        %---------------- Graficar de nuevo ----------------
        cla(ax1);
        plot(ax1, ts, hums, '-o','LineWidth',1.2);
        ylabel(ax1,'Humedad (%)'); ylim(ax1,[0 100]);
        xtickformat(ax1,'HH:mm:ss');  % funciona porque el eje es datetime

        cla(ax2);
        plot(ax2, ts, tmps, '-o','LineWidth',1.2);
        ylabel(ax2,'Temperatura (°C)'); xlabel(ax2,'Hora'); ylim(ax2,[-40 80]);
        xtickformat(ax2,'HH:mm:ss');

        % Ajustar ejes X
        if ~isempty(ts) && any(~isnat(ts))
            xStart = min(ts);
            xEnd   = max(ts) + seconds(max(period_s, 0.5));
            if xEnd > xStart
                xlim(ax1, [xStart, xEnd]);
                xlim(ax2, [xStart, xEnd]);
            end
        end

        % Título con última lectura válida
        hNow = hums(end); tNow = tmps(end);
        if ~isnan(hNow) && ~isnan(tNow)
            sg.String = sprintf('DHT22 Live  |  %s  |  Hum: %.1f%%  Temp: %.1f°C', ...
                                datestr(nowTs,'HH:MM:SS'), hNow, tNow);
        else
            sg.String = sprintf('DHT22 Live  |  %s  |  última lectura inválida', datestr(nowTs,'HH:MM:SS'));
        end

        drawnow;

        % Dormir hasta completar "period_s"
        dt = toc(lastTick);
        pause(max(0, period_s - dt));
        lastTick = tic;
    end

    if ishandle(btn) && get(btn,'Value')==1
        disp('Stop solicitado por el usuario.');
    else
        disp('Figura cerrada. Fin del live.');
    end
end
