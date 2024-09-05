function grabadorDeAudio()
    % Crear la interfaz gráfica para controlar la grabación
    f = figure('Name', 'Grabador de Audio', 'Position', [300, 300, 300, 150]);

    % Crear el objeto audiorecorder
    recObj = audiorecorder;

    % Crear botón para iniciar la grabación
    startButton = uicontrol('Style', 'pushbutton', 'String', 'Iniciar Grabación', ...
        'Position', [100, 80, 100, 30], ...
        'Callback', @(src, event) startRecording(recObj));

    % Crear texto para mostrar el tiempo transcurrido
    timeLabel = uicontrol('Style', 'text', 'Position', [100, 50, 100, 20], 'String', '0 segundos');

    % Función para iniciar la grabación
    function startRecording(recObj)
        % Iniciar grabación
        disp('Grabando ...');
        record(recObj);

        % Actualizar el tiempo transcurrido
        for t = 1:2  
            pause(1); % Esperar 1 segundo
            set(timeLabel, 'String', [num2str(t), ' segundos']);
            drawnow; % Actualizar la interfaz gráfica
        end

        % Detener la grabación después de 5 segundos
        stop(recObj);
        disp('Fin de la grabación.');

        % Obtener el arreglo de la grabación
        myRecording = getaudiodata(recObj);

        % Solicitar nombre para el archivo
        nombreArchivo = inputdlg('Ingrese el nombre del archivo de audio:', 'Nombre del Archivo');

        if isempty(nombreArchivo)
            disp('Nombre de archivo no proporcionado, cancelando guardado.');
            return;
        end

        % Crear la ruta completa
        rutaGuardado = fullfile('C:\Users\ROG\Downloads\audios\proyecto\fredy', [nombreArchivo{1}, '.wav']);

        % Guardar el archivo en la ruta especificada
        audiowrite(rutaGuardado, myRecording, recObj.SampleRate);

        % Reproducir el audio grabado
        sound(myRecording, recObj.SampleRate);

        % Plotear el audio grabado
        figure;
        plot(myRecording);
        title(['Señal de Audio: ', nombreArchivo{1}]);
        xlabel('Muestras');
        ylabel('Amplitud');

        % Mostrar mensaje de finalización
        disp(['Audio guardado como: ', rutaGuardado]);
    end
end