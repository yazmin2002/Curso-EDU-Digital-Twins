function [hum, temp] = get_dht_from_wokwi(baseUrl)
    % Detecta si la URL base necesita slash extra
    if endsWith(baseUrl, "/")
        url = baseUrl;
    else
        url = baseUrl + "/"; %#ok<*AGROW>
    end

    % Si tu endpoint no es la raíz, cambia "url" a url + "json" o lo que uses
    % url = url + "json";

    opts = weboptions( ...
        'Timeout', 5, ...                  % más generoso que el default
        'ContentType', 'json', ...
        'UseSystemProxy', false);          % evita proxys del SO

    maxRetries = 3;
    lastErr = [];
    for k = 1:maxRetries
        try
            data = webread(url, opts);
            % Adapta estas claves a tu JSON/HTML:
            % Ejemplo si devuelves {"humidity": 57.2, "temperature": 24.8}
            if isstruct(data) && isfield(data,'humidity') && isfield(data,'temperature')
                hum  = double(data.humidity);
                temp = double(data.temperature);
                return;
            end

            % Si servís HTML plano, podrías parsear con regexp:
            % txt = webread(url, weboptions('Timeout',5,'UseSystemProxy',false,'ContentType','text'));
            % hum = str2double(regexp(txt,'Humedad[^0-9]*([0-9]+(\.[0-9]+)?)','tokens','once'){1});
            % temp = str2double(regexp(txt,'Temperatura[^0-9]*([0-9]+(\.[0-9]+)?)','tokens','once'){1});
            error('FormatoDeRespuesta:Invalido', 'La respuesta no contiene campos esperados.');
        catch ME
            lastErr = ME;
            pause(1.0 * k); % backoff lineal
        end
    end
    % Si llegamos acá, agotamos reintentos
    rethrow(lastErr);
end
