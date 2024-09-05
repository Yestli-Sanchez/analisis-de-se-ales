% Define la carpeta principal que contiene las subcarpetas
mainFolder = "C:\Users\ROG\Downloads\audios\proyecto\aumento_originales";
outputFolder = "C:\Users\ROG\Downloads\audios\proyecto\aumento_originales"; % Carpeta donde se guardarán los archivos aumentados

% Lista de subcarpetas dentro de la carpeta principal
subFolders = dir(mainFolder);
subFolders = subFolders([subFolders.isdir]); % Filtra solo directorios
subFolders = subFolders(~ismember({subFolders.name}, {'.', '..'})); % Excluye '.' y '..'

% Se prepara el aumentador de audio
augmenter = audioDataAugmenter( ...
    "AugmentationMode", "sequential", ...
    'AugmentationParameterSource', 'random', ...
    "NumAugmentations", 9, ... % Generar 9 copias por archivo
    "TimeStretchProbability", 0.8, ...
    "SpeedupFactorRange", [1.3, 1.4], ...
    "PitchShiftProbability", 0, ...
    "VolumeControlProbability", 0.8, ...
    "VolumeGainRange", [-5, 5], ...
    "AddNoiseProbability", 0.5, ...
    "SNRRange", [0, 20], ...
    "TimeShiftProbability", 0.8, ...
    "TimeShiftRange", [-500e-3, 500e-3]);

% Procesa cada subcarpeta
for i = 1:length(subFolders)
    % Define la ruta de la subcarpeta actual
    currentSubFolder = fullfile(mainFolder, subFolders(i).name);
    
    % Obtiene la lista de archivos WAV en la subcarpeta
    audioFiles = dir(fullfile(currentSubFolder, '*.wav'));
    
    % Procesa cada archivo de audio en la subcarpeta
    for k = 1:length(audioFiles)
        % Lee el archivo de audio
        audioFilePath = fullfile(currentSubFolder, audioFiles(k).name);
        [audioIn, fs] = audioread(audioFilePath);
        
        % Aplica el aumentador
        data = augment(augmenter, audioIn, fs);
        
        % Guarda los audios aumentados en la misma subcarpeta
        [~, fileName, ext] = fileparts(audioFiles(k).name); % Obtiene el nombre base del archivo
        for j = 1:height(data)
            augmentation = data.Audio{j};
            outputFileName = fullfile(currentSubFolder, sprintf("%s_augmented_%d%s", fileName, j, ext));
            audiowrite(outputFileName, augmentation, fs);
        end
    end
end

disp('Audios aumentados y guardados correctamente en las subcarpetas.');
