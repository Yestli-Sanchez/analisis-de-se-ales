classdef VoiceRecognitionApp < matlab.apps.AppBase

    properties (Access = public)
        UIFigure                  matlab.ui.Figure  % Ventana principal de la aplicación
        TitleLabel                matlab.ui.control.Label  % Etiqueta del título
        InstructionsLabel         matlab.ui.control.Label  % Etiqueta de instrucciones
        RecordButton              matlab.ui.control.Button  % Botón para grabar audio
        ClassifyButton            matlab.ui.control.Button  % Botón para clasificar el audio grabado
        ResultLabel               matlab.ui.control.Label  % Etiqueta para mostrar el resultado de la clasificación
    end
    
    properties (Access = private)
        RecordedAudio  % Variable para almacenar el audio grabado
        SampleRate  % Tasa de muestreo del audio grabado
        audioIn  % Arreglo para almacenar los datos del audio
        fs = 8000;  % Frecuencia de muestreo ajustada a 8000 Hz
        nBits = 16;  % Resolución del audio en bits
        nChannels = 1;  % Número de canales (mono)
        duration = 5;  % Duración de la grabación en segundos
        energyThreshold = 0.08;  % Umbral de energía para detección de voz
        zcrThreshold = 0.15;  % Umbral de tasa de cruces por cero (ZCR)
        trainedClassifier  % Clasificador entrenado cargado desde un archivo
        M  % Media de las características del modelo
        S  % Desviación estándar de las características del modelo
    end
    
    methods (Access = private)
        
        % Función para cargar el modelo entrenado desde un archivo
        function loadModel(app)
            if isempty(app.trainedClassifier)
                try
                    load("C:\Users\yestl\OneDrive\Escritorio\MATLAB\proyecto\archivosmat\archivos1.mat", 'trainedClassifier', 'M', 'S');
                    app.trainedClassifier = trainedClassifier;  % Cargar clasificador
                    app.M = M;  % Cargar media
                    app.S = S;  % Cargar desviación estándar
                    disp('Modelo cargado exitosamente.');
                catch
                    app.ResultLabel.Text = 'Error al cargar el modelo.';
                    disp('Error al cargar el archivo del modelo.');
                end
            end
        end

        % Función que se ejecuta al presionar el botón de grabar
        function RecordButtonPushed(app, event)
            app.ResultLabel.Text = '';  % Limpiar el resultado anterior
            app.RecordedAudio = audiorecorder(app.fs, app.nBits, app.nChannels);  % Crear objeto de grabación
            disp('Grabando ...');
            recordblocking(app.RecordedAudio, app.duration);  % Grabar durante la duración especificada
            disp('Fin de la grabación.');
            app.audioIn = getaudiodata(app.RecordedAudio);  % Obtener los datos de audio
            sound(app.audioIn, app.fs);  % Reproducir el audio grabado
            disp('Reproduciendo el audio grabado.');
        end

        % Función que se ejecuta al presionar el botón de clasificar
        function ClassifyButtonPushed(app, event)
            if isempty(app.audioIn)
                app.ResultLabel.Text = 'Error: No se ha grabado ningún audio.';
                disp('Error: No se ha grabado ningún audio.');
                return;
            end

            % Parámetros para la extracción de características
            windowLength = round(0.03 * app.fs);  % Longitud de ventana en muestras
            overlapLength = round(0.025 * app.fs);  % Longitud de solapamiento

            % Crear el extractor de características
            afe = audioFeatureExtractor('SampleRate', app.fs, ...
                'Window', hamming(windowLength, "periodic"), ...
                'OverlapLength', overlapLength, ...
                'zerocrossrate', true, 'shortTimeEnergy', true, ...
                'pitch', true, 'mfcc', true);
            
            % Extraer las características del audio grabado
            inputFeatures = extract(afe, app.audioIn);
            featureMap = info(afe);  % Obtener el mapa de características
            
            % Usar solo la primera parte del audio grabado
            keepLen = round(length(app.audioIn) / 3);  % Mantener la primera parte del audio
            app.audioIn = app.audioIn(1:keepLen);

            % Determinar si hay voz y si es con tono
            isSpeech = inputFeatures(:, featureMap.shortTimeEnergy) > app.energyThreshold;
            isVoiced = inputFeatures(:, featureMap.zerocrossrate) > app.zcrThreshold;

            % Filtrar las características basadas en si es voz con tono
            voicedSpeech = isSpeech & isVoiced;
            inputFeatures(~voicedSpeech, :) = [];
            inputFeatures(:, [featureMap.zerocrossrate, featureMap.shortTimeEnergy]) = [];

            % Clasificar el audio si las dimensiones son correctas
            if size(inputFeatures, 2) == size(app.M, 2) && size(inputFeatures, 2) == size(app.S, 2)
                inputFeatures = (inputFeatures - app.M) ./ app.S;  % Normalizar las características
                predictedLabels = predict(app.trainedClassifier, inputFeatures);  % Predecir la clase
                finalLabel = mode(predictedLabels);  % Obtener la clase más frecuente
                app.ResultLabel.Text = ['Voz de ', char(finalLabel)];  % Mostrar el resultado
            else
                app.ResultLabel.Text = 'Error: Las dimensiones no coinciden.';
            end
        end
    end

    methods (Access = private)
        % Crear la interfaz de usuario
        function createComponents(app)
            app.UIFigure = uifigure('Visible', 'off');  % Crear la ventana de la aplicación
            app.UIFigure.Position = [100 100 400 300];
            app.UIFigure.Name = 'Voice Recognition';
            app.UIFigure.Color = [1 1 1];

            app.TitleLabel = uilabel(app.UIFigure);  % Crear la etiqueta del título
            app.TitleLabel.HorizontalAlignment = 'center';
            app.TitleLabel.FontSize = 20;
            app.TitleLabel.FontWeight = 'bold';
            app.TitleLabel.Position = [50 240 300 40];
            app.TitleLabel.Text = 'Reconocimiento de Voz';

            app.InstructionsLabel = uilabel(app.UIFigure);  % Crear la etiqueta de instrucciones
            app.InstructionsLabel.HorizontalAlignment = 'center';
            app.InstructionsLabel.FontSize = 14;
            app.InstructionsLabel.FontAngle = 'italic';
            app.InstructionsLabel.Position = [50 200 300 40];
            app.InstructionsLabel.Text = 'Al pulsar el botón de grabar, di "Oye Jarvis"';

            app.RecordButton = uibutton(app.UIFigure, 'push');  % Crear el botón de grabar
            app.RecordButton.ButtonPushedFcn = createCallbackFcn(app, @RecordButtonPushed, true);
            app.RecordButton.Position = [70 120 90 70];
            app.RecordButton.Text = '';  % Sin texto, solo icono
            app.RecordButton.Icon = 'C:\Users\yestl\OneDrive\Escritorio\MATLAB\proyecto\Microfono.png';  % Icono del micrófono

            app.ClassifyButton = uibutton(app.UIFigure, 'push');  % Crear el botón de clasificar
            app.ClassifyButton.ButtonPushedFcn = createCallbackFcn(app, @ClassifyButtonPushed, true);
            app.ClassifyButton.Position = [250 120 90 70];
            app.ClassifyButton.Text = '';  % Sin texto, solo icono
            app.ClassifyButton.Icon = 'C:\Users\yestl\OneDrive\Escritorio\MATLAB\proyecto\Clasificar.png';  % Icono para clasificar

            app.ResultLabel = uilabel(app.UIFigure);  % Crear la etiqueta para mostrar el resultado
            app.ResultLabel.HorizontalAlignment = 'center';
            app.ResultLabel.FontSize = 14;
            app.ResultLabel.Position = [100 50 200 40];
            app.ResultLabel.Text = '';

            app.UIFigure.Visible = 'on';  % Hacer visible la ventana de la aplicación
        end
    end

    methods (Access = public)
        % Constructor de la aplicación
        function app = VoiceRecognitionApp
            createComponents(app);  % Crear la interfaz
            loadModel(app);  % Cargar el modelo entrenado
        end
    end
end
