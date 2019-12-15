classdef app_exported < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        DSBModulationUIFigure  matlab.ui.Figure
        PlayerPanel            matlab.ui.container.Panel
        BrowseButton           matlab.ui.control.Button
        VolumeSliderLabel      matlab.ui.control.Label
        VolumeSlider           matlab.ui.control.Slider
        PlayButton             matlab.ui.control.Button
        PauseButton            matlab.ui.control.Button
        StopButton             matlab.ui.control.Button
        FileLabel              matlab.ui.control.Label
        directoryLabel         matlab.ui.control.Label
        Label_currentTime      matlab.ui.control.Label
        ofLabel                matlab.ui.control.Label
        Label_totalTime        matlab.ui.control.Label
        SNRdbButtonGroup       matlab.ui.container.ButtonGroup
        Button                 matlab.ui.control.RadioButton
        Button_2               matlab.ui.control.RadioButton
        Button_3               matlab.ui.control.RadioButton
        ModeButtonGroup        matlab.ui.container.ButtonGroup
        OriginalButton         matlab.ui.control.RadioButton
        FilteredButton         matlab.ui.control.RadioButton
        DemodulatedButton      matlab.ui.control.RadioButton
        ModulatedButton        matlab.ui.control.RadioButton
        ErrorsButtonGroup      matlab.ui.container.ButtonGroup
        NoErrorButton          matlab.ui.control.RadioButton
        PhaseErrorButton       matlab.ui.control.RadioButton
        FrequencyErrorButton   matlab.ui.control.RadioButton
        UIAxes                 matlab.ui.control.UIAxes
        UIAxes_2               matlab.ui.control.UIAxes
    end

    
    properties
        % global array for time plots and sound waves
        waveform1; waveform2; waveform3; waveform4; waveform5; waveform6; waveform7; waveform8; 
        % global array for sounds' sampling frequencies
        frequency1; frequency2; frequency3; frequency4; frequency5; frequency6; frequency7; frequency8; 
        % global array for frequency plots
        spectrum1; spectrum2; spectrum3; spectrum4; spectrum5; spectrum6; spectrum7; spectrum8; 
        
        currentAudio;     % global variable for sound signal
        currentAudioFreq; % global variable for its sampling freq
        currentTimePlot;  % global variable for current time plot
        currentFreqPlot;  % global variable for current freq plot
    end
    
    methods (Access = public)
        
        function time = formatTime(~, seconds)
            minutes = floor(seconds / 60);
            seconds = seconds - minutes * 60;
            time = minutes + ":" + seconds;
        end
        
        function setTotalTime(app, size, Fs)
            global seconds;
            seconds = ceil(size / Fs);
            app.Label_totalTime.Text = formatTime(app, seconds);
            app.Label_currentTime.Text = "0:00";
        end
        
        function setCurrentTime(app)
            global playing;
            global seconds;
            global pausedAt;
            for i = 0 : seconds
                if(playing)
                    app.Label_currentTime.Text = formatTime(app, i);
                    pausedAt = i;
                    pause(1);
                end
            end
            if(pausedAt == seconds)
                app.Label_currentTime.Text = "0:00";
            end
        end
        
        function resumeCurrentTime(app)
            global playing;
            global seconds;
            global pausedAt;
            for i = pausedAt : seconds
                if(playing)
                    app.Label_currentTime.Text = formatTime(app, i);
                    pause(1);
                    temp = i;
                end
            end
            pausedAt = temp;
            if(pausedAt == seconds)
                app.Label_currentTime.Text = "0:00";
            end
        end
    
        function refreshPlot(app)
            vectorLength = length(app.currentTimePlot);
            Fs = app.currentAudioFreq;
            time = linspace(0, vectorLength/Fs, vectorLength).';
            plot(app.UIAxes, time, app.currentTimePlot);
            vectorLength = length(app.currentFreqPlot);
            dF = Fs / vectorLength;
            freq = -Fs/2:dF:Fs/2-dF;
            plot(app.UIAxes_2, freq, abs(app.currentFreqPlot)/vectorLength);
        end
 
    end
    

    % Callbacks that handle component events
    methods (Access = private)

        % Code that executes after component creation
        function startupFcn(app)
            
        end

        % Button pushed function: BrowseButton
        function BrowseButtonPushed(app, event)
            
            global playing;
            global paused;
            % reset media player
            playing = false;
            paused = false;
            
            % read input file
            [file, input, fs] = readFile();
            if(file == 0)
                return
            end
            app.directoryLabel.Text = file;
            % add original input to program data
            app.waveform1 = input;
            app.frequency1 = fs;
            app.spectrum1 = fftshift(fft(input));
            % set current audio and plot
            app.currentAudio = app.waveform1;
            app.currentAudioFreq = app.frequency1;
            app.currentTimePlot= app.waveform1;
            app.currentFreqPlot = app.spectrum1;
            refreshPlot(app);
            
            % reset mode
            app.OriginalButton.Value = true;
            app.FilteredButton.Value = false;
            app.DemodulatedButton.Value = false;
            % reset noise magnitude
            app.Button.Value = false;
            app.Button_2.Value = false;
            app.Button_3.Value = true;
            % reset error
            app.NoErrorButton.Value = true;
            app.FrequencyErrorButton.Value = false;
            app.PhaseErrorButton.Value = false;
            % enable editing
            app.OriginalButton.Enable = 'on';
            app.FilteredButton.Enable = 'on';
            app.ModulatedButton.Enable = 'on';
            app.DemodulatedButton.Enable = 'on';
            
            % filter the input
            [messageSpectrum, message] = filterSignal(input, fs);
            % add filtered message to program data
            app.waveform2 = message;
            app.frequency2 = fs;
            app.spectrum2 = messageSpectrum;
            
            % modulate the message
            fc = 100000;
            [modulatedMessage, carrierFs] = modulate(message, fs, fc);
            % add modulated message to program data
            app.waveform3 = modulatedMessage;
            app.frequency3 = carrierFs;
            app.spectrum3 = fftshift(fft(modulatedMessage));
            
            % demodulate the message: 0 dB sound to noise ratio - no error
            snr = 0;
            phase = 0;
            fc = 100000;
            [demodulatedSignalSpectrum , demodulatedSignal] = demodulate(modulatedMessage, carrierFs, fs, fc, phase, snr);
            % add result to program data
            app.waveform4 = demodulatedSignal;
            app.frequency4 = fs;
            app.spectrum4 = demodulatedSignalSpectrum;
            
            % demodulate the message: 10 dB sound to noise ratio - no error
            snr = 10;
            phase = 0;
            fc = 100000;
            [demodulatedSignalSpectrum , demodulatedSignal] = demodulate(modulatedMessage, carrierFs, fs, fc, phase, snr);
            % add result to program data
            app.waveform5 = demodulatedSignal;
            app.frequency5 = fs;
            app.spectrum5 = demodulatedSignalSpectrum;
            
            % demodulate the message: 30 dB sound to noise ratio - no error
            snr = 30;
            phase = 0;
            fc = 100000;
            [demodulatedSignalSpectrum , demodulatedSignal] = demodulate(modulatedMessage, carrierFs, fs, fc, phase, snr);
            % add result to program data
            app.waveform6 = demodulatedSignal;
            app.frequency6 = fs;
            app.spectrum6 = demodulatedSignalSpectrum;
            
            % demodulate the message: 10 dB noise - frequency error
            snr = 10;
            phase = 0;
            fc = 100100;
            [demodulatedSignalSpectrum , demodulatedSignal] = demodulate(modulatedMessage, carrierFs, fs, fc, phase, snr);
            % add result to program data
            app.waveform7 = demodulatedSignal;
            app.frequency7 = fs;
            app.spectrum7 = demodulatedSignalSpectrum;
            
            % demodulate the message: 10 dB noise - phase error
            snr = 10;
            phase = 20;
            fc = 100000;
            [demodulatedSignalSpectrum , demodulatedSignal] = demodulate(modulatedMessage, carrierFs, fs, fc, phase, snr);
            % add result to program data
            app.waveform8 = demodulatedSignal;
            app.frequency8 = fs;
            app.spectrum8 = demodulatedSignalSpectrum;
        end

        % Button pushed function: PlayButton
        function PlayButtonPushed(app, event)
            global player;
            global paused;
            global playing;
            y = app.currentAudio;
            Fs = app.currentAudioFreq;
            if paused
                playing = true;
                resume(player);
                resumeCurrentTime(app);
            end
            if ~playing
                player = audioplayer(y, Fs);
                playing = true;
                play(player);
                setTotalTime(app, length(y), Fs)
                setCurrentTime(app);
            end
        end

        % Button pushed function: PauseButton
        function PauseButtonPushed(app, event)
            global player;
            global paused;
            global playing;
            if playing
                playing = false;
                pause(player);
                paused = true;
            end
        end

        % Button pushed function: StopButton
        function StopButtonPushed(app, event)
            global player;
            global playing;
            global paused;
            global pausedAt;
            playing = false;
            paused = false;
            stop(player);
            app.Label_currentTime.Text = "0:00";
            pausedAt = 0;
        end

        % Selection changed function: ModeButtonGroup
        function ModeButtonGroupSelectionChanged(app, event)
            selectedButton = app.ModeButtonGroup.SelectedObject;
            if(selectedButton.Text == "Demodulated")
                % set current audio and plot
                app.currentAudio = app.waveform6;
                app.currentAudioFreq = app.frequency6;
                app.currentTimePlot = app.waveform6;
                app.currentFreqPlot = app.spectrum6;
                % enable demodulation button groups
                app.Button.Enable = 'on';
                app.Button_2.Enable = 'on';
                app.Button_3.Enable = 'on';
                app.NoErrorButton.Enable = 'on';
                app.PhaseErrorButton.Enable = 'on';
                app.FrequencyErrorButton.Enable = 'on';
                % reset noise magnitude
                app.Button.Value = false;
                app.Button_2.Value = false;
                app.Button_3.Value = true;
                % reset error
                app.NoErrorButton.Value = true;
                app.FrequencyErrorButton.Value = false;
                app.PhaseErrorButton.Value = false;
                app.PlayButton.Enable = 'on';
            else
                if(selectedButton.Text == "Original")
                    app.currentAudio = app.waveform1;
                    app.currentAudioFreq = app.frequency1;
                    app.currentTimePlot = app.waveform1;
                    app.currentFreqPlot = app.spectrum1;
                    app.PlayButton.Enable = 'on';
                elseif(selectedButton.Text == "Filtered")
                    app.currentAudio = app.waveform2;
                    app.currentAudioFreq = app.frequency2;
                    app.currentTimePlot = app.waveform2;
                    app.currentFreqPlot = app.spectrum2;
                    app.PlayButton.Enable = 'on';
                else
                    app.currentAudio = app.waveform3;
                    app.currentAudioFreq = app.frequency3;
                    app.currentTimePlot = app.waveform3;
                    app.currentFreqPlot = app.spectrum3;
                    app.PlayButton.Enable = 'off';
                end
                app.Button.Enable = 'off';
                app.Button_2.Enable = 'off';
                app.Button_3.Enable = 'off';
                app.NoErrorButton.Enable = 'off';
                app.PhaseErrorButton.Enable = 'off';
                app.FrequencyErrorButton.Enable = 'off';
            end
            refreshPlot(app);
        end

        % Selection changed function: ErrorsButtonGroup
        function ErrorsButtonGroupSelectionChanged(app, event)
            selectedButton = app.ErrorsButtonGroup.SelectedObject;
            snrSelectedButton = app.SNRdbButtonGroup.SelectedObject;
            if(selectedButton.Text == "No Error")
                app.Button.Enable = 'off';
                app.Button_2.Enable = 'on';
                app.Button_3.Enable = 'off';
                app.Button.Value = false;
                app.Button_2.Value = true;
                app.Button_3.Value = false;
                switch snrSelectedButton.Text
                    case "0"
                        app.currentAudio = app.waveform4;
                        app.currentAudioFreq = app.frequency4;
                        app.currentTimePlot = app.waveform4;
                        app.currentFreqPlot = app.spectrum4;
                    case "10"
                        app.currentAudio = app.waveform5;
                        app.currentAudioFreq = app.frequency5;
                        app.currentTimePlot = app.waveform5;
                        app.currentFreqPlot = app.spectrum5;
                    case "30"
                        app.currentAudio = app.waveform6;
                        app.currentAudioFreq = app.frequency6;
                        app.currentTimePlot = app.waveform6;
                        app.currentFreqPlot = app.spectrum6;
                end
            else
                app.Button.Enable = 'off';
                app.Button_2.Enable = 'on';
                app.Button_3.Enable = 'off';
                app.Button.Value = false;
                app.Button_2.Value = true;
                app.Button_3.Value = false;
                if (selectedButton.Text == "Phase Error")
                    app.currentAudio = app.waveform7;
                    app.currentAudioFreq = app.frequency7;
                    app.currentTimePlot = app.waveform7;
                    app.currentFreqPlot = app.spectrum7;
                else
                    app.currentAudio = app.waveform8;
                    app.currentAudioFreq = app.frequency8;
                    app.currentTimePlot = app.waveform8;
                    app.currentFreqPlot = app.spectrum8;
                end
            end
            refreshPlot(app);
        end

        % Selection changed function: SNRdbButtonGroup
        function SNRdbButtonGroupSelectionChanged(app, event)
            snrSelectedButton = app.SNRdbButtonGroup.SelectedObject;
            switch snrSelectedButton.Text
                case "0"
                    app.currentAudio = app.waveform4;
                    app.currentAudioFreq = app.frequency4;
                    app.currentTimePlot = app.waveform4;
                    app.currentFreqPlot = app.spectrum4;
                case "10"
                    app.currentAudio = app.waveform5;
                    app.currentAudioFreq = app.frequency5;
                    app.currentTimePlot = app.waveform5;
                    app.currentFreqPlot = app.spectrum5;
                case "30"
                    app.currentAudio = app.waveform6;
                    app.currentAudioFreq = app.frequency6;
                    app.currentTimePlot = app.waveform6;
                    app.currentFreqPlot = app.spectrum6;
            end
            refreshPlot(app);
        end
    end

    % Component initialization
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app)

            % Create DSBModulationUIFigure and hide until all components are created
            app.DSBModulationUIFigure = uifigure('Visible', 'off');
            app.DSBModulationUIFigure.Position = [650 100 938 726];
            app.DSBModulationUIFigure.Name = 'DSB Modulation';

            % Create PlayerPanel
            app.PlayerPanel = uipanel(app.DSBModulationUIFigure);
            app.PlayerPanel.Title = 'Player';
            app.PlayerPanel.Position = [28 551 883 160];

            % Create BrowseButton
            app.BrowseButton = uibutton(app.PlayerPanel, 'push');
            app.BrowseButton.ButtonPushedFcn = createCallbackFcn(app, @BrowseButtonPushed, true);
            app.BrowseButton.Icon = 'icons8-search-26.png';
            app.BrowseButton.Position = [326 108 100 22];
            app.BrowseButton.Text = 'Browse';

            % Create VolumeSliderLabel
            app.VolumeSliderLabel = uilabel(app.PlayerPanel);
            app.VolumeSliderLabel.HorizontalAlignment = 'right';
            app.VolumeSliderLabel.Position = [270 40 45 22];
            app.VolumeSliderLabel.Text = 'Volume';

            % Create VolumeSlider
            app.VolumeSlider = uislider(app.PlayerPanel);
            app.VolumeSlider.Position = [336 49 79 3];
            app.VolumeSlider.Value = 50;

            % Create PlayButton
            app.PlayButton = uibutton(app.PlayerPanel, 'push');
            app.PlayButton.ButtonPushedFcn = createCallbackFcn(app, @PlayButtonPushed, true);
            app.PlayButton.Icon = 'icons8-play-24.png';
            app.PlayButton.Position = [13 29 63 22];
            app.PlayButton.Text = 'Play';

            % Create PauseButton
            app.PauseButton = uibutton(app.PlayerPanel, 'push');
            app.PauseButton.ButtonPushedFcn = createCallbackFcn(app, @PauseButtonPushed, true);
            app.PauseButton.Icon = 'icons8-pause-24.png';
            app.PauseButton.Position = [101 29 63 22];
            app.PauseButton.Text = 'Pause';

            % Create StopButton
            app.StopButton = uibutton(app.PlayerPanel, 'push');
            app.StopButton.ButtonPushedFcn = createCallbackFcn(app, @StopButtonPushed, true);
            app.StopButton.Icon = 'icons8-stop-26.png';
            app.StopButton.Position = [187 29 63 22];
            app.StopButton.Text = 'Stop';

            % Create FileLabel
            app.FileLabel = uilabel(app.PlayerPanel);
            app.FileLabel.Position = [13 108 27 22];
            app.FileLabel.Text = 'File:';

            % Create directoryLabel
            app.directoryLabel = uilabel(app.PlayerPanel);
            app.directoryLabel.HorizontalAlignment = 'center';
            app.directoryLabel.Position = [47 108 203 22];
            app.directoryLabel.Text = 'Load file first';

            % Create Label_currentTime
            app.Label_currentTime = uilabel(app.PlayerPanel);
            app.Label_currentTime.Position = [77 69 28 22];
            app.Label_currentTime.Text = '--:--';

            % Create ofLabel
            app.ofLabel = uilabel(app.PlayerPanel);
            app.ofLabel.Position = [127 69 19 22];
            app.ofLabel.Text = 'of';

            % Create Label_totalTime
            app.Label_totalTime = uilabel(app.PlayerPanel);
            app.Label_totalTime.Position = [160 69 28 22];
            app.Label_totalTime.Text = '--:--';

            % Create SNRdbButtonGroup
            app.SNRdbButtonGroup = uibuttongroup(app.PlayerPanel);
            app.SNRdbButtonGroup.SelectionChangedFcn = createCallbackFcn(app, @SNRdbButtonGroupSelectionChanged, true);
            app.SNRdbButtonGroup.Title = 'SNR (db)';
            app.SNRdbButtonGroup.Position = [605 14 123 111];

            % Create Button
            app.Button = uiradiobutton(app.SNRdbButtonGroup);
            app.Button.Enable = 'off';
            app.Button.Text = '0';
            app.Button.Position = [11 65 58 22];
            app.Button.Value = true;

            % Create Button_2
            app.Button_2 = uiradiobutton(app.SNRdbButtonGroup);
            app.Button_2.Enable = 'off';
            app.Button_2.Text = '10';
            app.Button_2.Position = [11 43 65 22];

            % Create Button_3
            app.Button_3 = uiradiobutton(app.SNRdbButtonGroup);
            app.Button_3.Enable = 'off';
            app.Button_3.Text = '30';
            app.Button_3.Position = [11 21 65 22];

            % Create ModeButtonGroup
            app.ModeButtonGroup = uibuttongroup(app.PlayerPanel);
            app.ModeButtonGroup.SelectionChangedFcn = createCallbackFcn(app, @ModeButtonGroupSelectionChanged, true);
            app.ModeButtonGroup.Title = 'Mode';
            app.ModeButtonGroup.Position = [458 14 123 111];

            % Create OriginalButton
            app.OriginalButton = uiradiobutton(app.ModeButtonGroup);
            app.OriginalButton.Enable = 'off';
            app.OriginalButton.Text = 'Original';
            app.OriginalButton.Position = [11 65 63 22];
            app.OriginalButton.Value = true;

            % Create FilteredButton
            app.FilteredButton = uiradiobutton(app.ModeButtonGroup);
            app.FilteredButton.Enable = 'off';
            app.FilteredButton.Text = 'Filtered';
            app.FilteredButton.Position = [11 43 65 22];

            % Create DemodulatedButton
            app.DemodulatedButton = uiradiobutton(app.ModeButtonGroup);
            app.DemodulatedButton.Enable = 'off';
            app.DemodulatedButton.Text = 'Demodulated';
            app.DemodulatedButton.Position = [11 0 93 22];

            % Create ModulatedButton
            app.ModulatedButton = uiradiobutton(app.ModeButtonGroup);
            app.ModulatedButton.Enable = 'off';
            app.ModulatedButton.Text = 'Modulated';
            app.ModulatedButton.Position = [11 21 78 22];

            % Create ErrorsButtonGroup
            app.ErrorsButtonGroup = uibuttongroup(app.PlayerPanel);
            app.ErrorsButtonGroup.SelectionChangedFcn = createCallbackFcn(app, @ErrorsButtonGroupSelectionChanged, true);
            app.ErrorsButtonGroup.Title = 'Errors';
            app.ErrorsButtonGroup.Position = [750 14 123 111];

            % Create NoErrorButton
            app.NoErrorButton = uiradiobutton(app.ErrorsButtonGroup);
            app.NoErrorButton.Enable = 'off';
            app.NoErrorButton.Text = 'No Error';
            app.NoErrorButton.Position = [11 65 67 22];
            app.NoErrorButton.Value = true;

            % Create PhaseErrorButton
            app.PhaseErrorButton = uiradiobutton(app.ErrorsButtonGroup);
            app.PhaseErrorButton.Enable = 'off';
            app.PhaseErrorButton.Text = 'Phase Error';
            app.PhaseErrorButton.Position = [11 43 86 22];

            % Create FrequencyErrorButton
            app.FrequencyErrorButton = uiradiobutton(app.ErrorsButtonGroup);
            app.FrequencyErrorButton.Enable = 'off';
            app.FrequencyErrorButton.Text = 'Frequency Error';
            app.FrequencyErrorButton.Position = [11 21 109 22];

            % Create UIAxes
            app.UIAxes = uiaxes(app.DSBModulationUIFigure);
            title(app.UIAxes, 'Signal in Time domain')
            xlabel(app.UIAxes, 'Time')
            ylabel(app.UIAxes, 'Magnitude')
            app.UIAxes.PlotBoxAspectRatio = [3.6195652173913 1 1];
            app.UIAxes.XGrid = 'on';
            app.UIAxes.XMinorGrid = 'on';
            app.UIAxes.YGrid = 'on';
            app.UIAxes.YMinorGrid = 'on';
            app.UIAxes.Position = [28 278 883 240];

            % Create UIAxes_2
            app.UIAxes_2 = uiaxes(app.DSBModulationUIFigure);
            title(app.UIAxes_2, 'Signal in Frequency domain')
            xlabel(app.UIAxes_2, 'Frequency')
            ylabel(app.UIAxes_2, 'Magnitude')
            app.UIAxes_2.PlotBoxAspectRatio = [3.6195652173913 1 1];
            app.UIAxes_2.XGrid = 'on';
            app.UIAxes_2.XMinorGrid = 'on';
            app.UIAxes_2.YGrid = 'on';
            app.UIAxes_2.YMinorGrid = 'on';
            app.UIAxes_2.Position = [20 24 891 240];

            % Show the figure after all components are created
            app.DSBModulationUIFigure.Visible = 'on';
        end
    end

    % App creation and deletion
    methods (Access = public)

        % Construct app
        function app = app_exported

            % Create UIFigure and components
            createComponents(app)

            % Register the app with App Designer
            registerApp(app, app.DSBModulationUIFigure)

            % Execute the startup function
            runStartupFcn(app, @startupFcn)

            if nargout == 0
                clear app
            end
        end

        % Code that executes before app deletion
        function delete(app)

            % Delete UIFigure when app is deleted
            delete(app.DSBModulationUIFigure)
        end
    end
end