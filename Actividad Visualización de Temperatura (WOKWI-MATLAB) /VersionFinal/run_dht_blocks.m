% Guarda como: run_dht_blocks.m
% Requiere: get_dht_from_wokwi(url) en el path.

function run_dht_blocks(url, period_s, block_size)
    if nargin < 1 || strlength(url)==0,      url = "http://localhost:9080"; end
    if nargin < 2 || isempty(period_s),      period_s = 2;                   end
    if nargin < 3 || isempty(block_size),    block_size = 10;                end

    % --- Figura y estilo ---
    fig = figure('Name','DHT22 - bloques de 10 lecturas');
    tiledlayout(fig,2,1);

    bloque = 0;
    fprintf('Iniciado. URL=%s | período=%.1fs | bloque=%d muestras\n', url, period_s, block_size);
    fprintf('Cortar con Ctrl+C.\n');

    while isvalid(fig)  % corre hasta cerrar la figura o Ctrl+C
        bloque = bloque + 1;

        % 1) Preasignar vectores para este bloque
        hum = nan(block_size,1);
        temp = nan(block_size,1);
        tz = 'America/Montevideo';
        ts = NaT(block_size,1);                 % crea NaT...
        ts.TimeZone = tz;                       % ...y le seteás la zona

        % 2) Llenar vectores con 10 lecturas
        for k = 1:block_size
            try
                [hum(k), temp(k)] = get_dht_from_wokwi(url);
            catch ME
                warning('Lectura %d falló: %s', k, ME.message);
                % deja NaN en hum/temp si falla
            end
            ts(k) = datetime('now','TimeZone',tz);
            pause(period_s);
        end

        % 3) Graficar solo este bloque (sobrescribe visual)
        clf(fig); tiledlayout(fig,2,1);

        % Humedad
        ax1 = nexttile;
        plot(ax1, ts, hum, '-o','LineWidth',1.2);
        grid(ax1,'on'); ylabel(ax1,'Humedad (%)');
        title(ax1, sprintf('Bloque %d - Humedad (últimas %d lecturas)', bloque, block_size));
        xtickformat(ax1,'HH:mm:ss');
        % margen pequeño al final del eje X
        xlim(ax1, [ts(1) ts(end) + seconds(period_s)]);

        % Temperatura
        ax2 = nexttile;
        plot(ax2, ts, temp, '-o','LineWidth',1.2);
        grid(ax2,'on'); ylabel(ax2,'Temperatura (°C)'); xlabel(ax2,'Hora');
        title(ax2, sprintf('Bloque %d - Temperatura (últimas %d lecturas)', bloque, block_size));
        xtickformat(ax2,'HH:mm:ss');
        xlim(ax2, [ts(1) ts(end) + seconds(period_s)]);

        drawnow;  % actualiza la figura
    end
end
