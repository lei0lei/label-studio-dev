Add-Type -AssemblyName PresentationFramework
Add-Type -AssemblyName PresentationCore
Add-Type -AssemblyName WindowsBase
Add-Type -AssemblyName System.Windows.Forms

[xml]$xaml = @"
<Window xmlns='http://schemas.microsoft.com/winfx/2006/xaml/presentation'
        Title='Label Studio Installer' Height='600' Width='800'
        WindowStartupLocation='CenterScreen' Background='#FF2D2D30' ResizeMode='CanResizeWithGrip'>
    <Grid Margin='20'>
        <Grid.RowDefinitions>
            <RowDefinition Height='Auto'/> <!-- Step Title -->
            <RowDefinition Height='*'/>    <!-- Page Content -->
            <RowDefinition Height='Auto'/> <!-- Buttons -->
        </Grid.RowDefinitions>

        <TextBlock Name='txtStep' Grid.Row='0' FontSize='20' FontWeight='Bold' Foreground='White' Margin='0,0,0,20'/>

        <!-- content area -->
        <Grid Grid.Row='1'>
            <!-- Step 0: Welcome -->
            <StackPanel Name='page0' Visibility='Visible'>
                <TextBlock Foreground='White' FontSize='14' TextWrapping='Wrap'>
                    Welcome to Label Studio Installer.`n`nThis wizard will guide you through the installation process of Label Studio.
                </TextBlock>
            </StackPanel>

            <!-- Step 1: Environment Check -->
            <StackPanel Name='page1' Visibility='Collapsed'>
                <TextBlock Foreground='White' FontSize='14' Margin='0,0,0,10'>Checking system environment...</TextBlock>
                <CheckBox Name='chkPython' Content='Python 3.10+' Foreground='White' IsEnabled='False' Margin='10,2,0,2'/>
                <TextBlock Name='lblAllPython' Foreground='#FFAAAAAA' FontSize='10' FontStyle='Italic' Margin='35,0,0,5' TextWrapping='Wrap'/>
                <CheckBox Name='chkGit' Content='Git' Foreground='White' IsEnabled='False' Margin='10,2,0,2'/>
                <CheckBox Name='chkNode' Content='Node.js v21+' Foreground='White' IsEnabled='False' Margin='10,2,0,2'/>
                <TextBlock Name='txtEnvStatus' Foreground='#FFFF6666' FontSize='12' Margin='0,20,0,0' FontWeight='Bold' TextWrapping='Wrap'/>
            </StackPanel>

            <!-- Step 2: Select Directory -->
            <StackPanel Name='page2' Visibility='Collapsed'>
                <TextBlock Foreground='White' FontSize='14' Margin='0,0,0,10'>Select installation directory:</TextBlock>
                <Grid Margin='0,0,0,10'>
                    <Grid.ColumnDefinitions>
                        <ColumnDefinition Width='*'/>
                        <ColumnDefinition Width='Auto'/>
                    </Grid.ColumnDefinitions>
                    <TextBox Name='txtPath' Grid.Column='0' Height='25' VerticalContentAlignment='Center'/>
                    <Button Name='btnBrowse' Grid.Column='1' Content='Browse...' Width='80' Margin='5,0,0,0'/>
                </Grid>
                <TextBlock Name='txtPathPreview' Foreground='#FFAAAAAA' FontSize='11' Margin='5,0,0,10' TextWrapping='Wrap'/>
                <TextBlock Name='txtPathWarning' Foreground='#FFFF6666' FontSize='12' FontWeight='Bold' Margin='5,0,0,10' Visibility='Collapsed' TextWrapping='Wrap'/>
            </StackPanel>

            <!-- Step 3: Installing -->
            <Grid Name='page3' Visibility='Collapsed'>
                <Grid.RowDefinitions>
                    <RowDefinition Height='Auto'/>
                    <RowDefinition Height='Auto'/>
                    <RowDefinition Height='Auto'/>
                    <RowDefinition Height='Auto'/>
                    <RowDefinition Height='*'/>
                </Grid.RowDefinitions>
                <ProgressBar Name='progressInstall' Grid.Row='0' Height='25' Margin='0,0,0,10'/>
                <CheckBox Name='chkMLBackend' Grid.Row='1' Content='Install Label Studio ML Backend' Foreground='White' Margin='0,0,0,10'/>
                <Button Name='btnStartInstall' Grid.Row='2' Content='Start Installation' Height='35' Margin='0,0,0,10' FontSize='14' FontWeight='Bold'/>
                <TextBlock Name='txtInstallStatus' Grid.Row='3' Foreground='#FF75BEFF' FontSize='14' FontWeight='Bold' Margin='0,0,0,10' Visibility='Collapsed'/>
                <TextBox Name='txtLogs' Grid.Row='4' Background='#FF1E1E1E' Foreground='#FFD4D4D4' 
                         IsReadOnly='True' VerticalScrollBarVisibility='Auto' TextWrapping='Wrap' FontFamily='Consolas' FontSize='11'/>
            </Grid>

            <!-- Step 4: Complete -->
            <StackPanel Name='page4' Visibility='Collapsed'>
                <TextBlock Foreground='White' FontSize='18' FontWeight='Bold' HorizontalAlignment='Center' Margin='0,50,0,10'>
                    Installation Complete!
                </TextBlock>
                <TextBlock Foreground='White' HorizontalAlignment='Center' Margin='0,0,0,30'>
                    Label Studio has been successfully installed.
                </TextBlock>
                <Button Name='btnOpenFolder' Content='Open Installation Folder' Width='200' Height='35' HorizontalAlignment='Center'/>
                <TextBlock Foreground='#FFAAAAAA' FontSize='11' HorizontalAlignment='Center' Margin='0,20,0,0'>
                    You can start the server by running `poetry run python label_studio/manage.py runserver` in the label-studio-dev directory.
                </TextBlock>
            </StackPanel>
        </Grid>

        <!-- Button Area -->
        <StackPanel Grid.Row='2' Orientation='Horizontal' HorizontalAlignment='Right' Margin='0,20,0,0'>
            <Button Name='btnBack' Content='Back' Width='100' Height='30' Margin='0,0,10,0'/>
            <Button Name='btnNext' Content='Next' Width='100' Height='30'/>
        </StackPanel>
    </Grid>
</Window>
"@

# Load XAML
$reader = (New-Object System.Xml.XmlNodeReader $xaml)
$window = [Windows.Markup.XamlReader]::Load($reader)

# Get Controls
$txtStep = $window.FindName("txtStep")
$pages = @(
    $window.FindName("page0"),
    $window.FindName("page1"),
    $window.FindName("page2"),
    $window.FindName("page3"),
    $window.FindName("page4")
)
$btnBack = $window.FindName("btnBack")
$btnNext = $window.FindName("btnNext")

# Step 1 Controls
$chkPython = $window.FindName("chkPython")
$lblAllPython = $window.FindName("lblAllPython")
$chkGit = $window.FindName("chkGit")
$chkNode = $window.FindName("chkNode")
$txtEnvStatus = $window.FindName("txtEnvStatus")

# Other controls for later use
$txtPath = $window.FindName("txtPath")
$btnBrowse = $window.FindName("btnBrowse")
$txtPathPreview = $window.FindName("txtPathPreview")
$txtPathWarning = $window.FindName("txtPathWarning")
$chkMLBackend = $window.FindName("chkMLBackend")
$btnStartInstall = $window.FindName("btnStartInstall")
$txtInstallStatus = $window.FindName("txtInstallStatus")
$btnOpenFolder = $window.FindName("btnOpenFolder")
$progressInstall = $window.FindName("progressInstall")
$progressInstall.Maximum = 10
$txtLogs = $window.FindName("txtLogs")

# Initialize Path
$txtPath.Text = $env:USERPROFILE

# --- Configuration ---
$REPO_LABEL_STUDIO = "https://github.com/lei0lei/label-studio-dev.git" # Replace with your fork
$REPO_ML_BACKEND = "https://github.com/lei0lei/label-studio-ml-backend-dev.git" # Replace with your fork

# --- Functions ---

function Check-Environment {
    $btnNext.IsEnabled = $false
    $txtEnvStatus.Text = ""
    $lblAllPython.Text = ""
    
    $pythonOk = $false
    $gitOk = $false
    $nodeOk = $false

    # Reset Checkboxes
    $chkPython.IsChecked = $false
    $chkGit.IsChecked = $false
    $chkNode.IsChecked = $false

    # Check Python (3.10+) - Search all available pythons in PATH
    try {
        $pyPaths = where.exe python 2>$null
        $allPyVers = @()
        foreach ($path in $pyPaths) {
            $verOutput = & $path --version 2>&1
            $verStr = "$verOutput".Trim()
            $allPyVers += "$verStr ($path)"
            
            # If we haven't found a compliant python yet, check this one
            if (-not $pythonOk) {
                # Flexible regex for 2 or 3 version components
                $pyVerMatch = [regex]::Match($verStr, "(\d+\.\d+(?:\.\d+)?)")
                if ($pyVerMatch.Success) {
                    $vStr = $pyVerMatch.Groups[1].Value
                    $pyVer = [version]$vStr
                    if ($pyVer -ge [version]"3.10") {
                        $chkPython.Content = "Python: Found ($verStr)"
                        $chkPython.IsChecked = $true
                        $pythonOk = $true
                        $sync.PythonPath = $path # Lock this path for installation
                    }
                }
            }
        }
        if ($allPyVers.Count -gt 0) {
            $lblAllPython.Text = "Found Python(s):`n" + ($allPyVers -join "`n")
        }
        
        if (-not $pythonOk) {
            if ($allPyVers.Count -gt 0) {
                $chkPython.Content = "Python: Versions found are too old. Need 3.10+"
            } else {
                $chkPython.Content = "Python: Not found"
            }
        }
    } catch {
        $chkPython.Content = "Python: Error checking versions"
    }

    # Check Git
    try {
        $gitVer = git --version 2>&1
        if ($LASTEXITCODE -eq 0) {
            $chkGit.Content = "Git: Found ($gitVer)"
            $chkGit.IsChecked = $true
            $gitOk = $true
        } else {
            $chkGit.Content = "Git: Not found"
        }
    } catch {
        $chkGit.Content = "Git: Not found"
    }

    # Check Node (v21+)
    try {
        $nodeFullVer = node --version 2>&1
        if ($LASTEXITCODE -eq 0) {
            # Flexible regex for node versions
            $nodeVerMatch = [regex]::Match($nodeFullVer, "(\d+\.\d+(?:\.\d+)?)")
            if ($nodeVerMatch.Success) {
                $nodeVer = [version]$nodeVerMatch.Groups[1].Value
                if ($nodeVer.Major -ge 21) {
                    $chkNode.Content = "Node.js: Found ($nodeFullVer)"
                    $chkNode.IsChecked = $true
                    $nodeOk = $true
                } else {
                    $chkNode.Content = "Node.js: Too old ($nodeFullVer). Need v21+"
                }
            }
        } else {
            $chkNode.Content = "Node.js: Not found"
        }
    } catch {
        $chkNode.Content = "Node.js: Not found"
    }

    if ($pythonOk -and $gitOk -and $nodeOk) {
        $btnNext.IsEnabled = $true
    } else {
        $txtEnvStatus.Text = "Please install required environments (Python 3.10+, Node v21+, Git) to continue."
    }
}

# Create a synchronized hashtable for thread-safe UI updates
$sync = [hashtable]::Synchronized(@{
    Logs = [System.Collections.Generic.List[string]]::new()
    Progress = 0
    Finished = $false
    IsRunning = $false
    Error = $null
    # Config values
    RepoLS = $REPO_LABEL_STUDIO
    RepoML = $REPO_ML_BACKEND
    PythonPath = "python"
    InstallPath = ""
    LsDir = ""
    WithML = $false
})

# UI Update Timer (Ticks every 100ms)
$uiTimer = New-Object System.Windows.Threading.DispatcherTimer
$uiTimer.Interval = [TimeSpan]::FromMilliseconds(100)
$uiTimer.Add_Tick({
    # Pull logs from sync object - optimized for performance
    if ($sync.Logs.Count -gt 0) {
        $logArray = $sync.Logs.ToArray()
        $sync.Logs.Clear()

        # Clean ANSI escape codes (e.g., color codes like [31m)
        $cleanedLogs = foreach ($line in $logArray) {
            # Regex to match ANSI escape sequences
            $line -replace "\x1b\[[0-9;]*[mKJK]", "" -replace "\x1b\(B", ""
        }
        
        # Batch append to prevent UI flicker/lag
        $txtLogs.AppendText([string]::Concat($cleanedLogs))
        
        # Limit to 200 lines to keep UI responsive
        if ($txtLogs.LineCount -gt 200) {
            $idx = $txtLogs.GetCharacterIndexFromLineIndex($txtLogs.LineCount - 200)
            if ($idx -gt 0) {
                $txtLogs.Select(0, $idx)
                $txtLogs.SelectedText = ""
            }
        }
        $txtLogs.ScrollToEnd()
    }
    
    # Update Progress
    $progressInstall.Value = $sync.Progress
    
    # Check if finished
    if ($sync.Finished) {
        $uiTimer.Stop()
        $txtInstallStatus.Text = "Installation Complete! Click 'Next' to continue."
        $txtInstallStatus.Visibility = 'Visible'
        $btnNext.IsEnabled = $true
    }
})

function Write-Log {
    param($msg)
    $timestamp = Get-Date -Format "HH:mm:ss"
    $txtLogs.AppendText("[$timestamp] $msg`r`n")
    
    # Limit to 200 lines to keep UI responsive
    if ($txtLogs.LineCount -gt 200) {
        $idx = $txtLogs.GetCharacterIndexFromLineIndex($txtLogs.LineCount - 200)
        if ($idx -gt 0) {
            $txtLogs.Select(0, $idx)
            $txtLogs.SelectedText = ""
        }
    }
    $txtLogs.ScrollToEnd()
}

# Variable to track the background job
$script:PowerShellInstance = $null

function Start-Installation {
    $btnStartInstall.IsEnabled = $false
    $chkMLBackend.IsEnabled = $false
    $btnNext.IsEnabled = $false
    $btnBack.IsEnabled = $false
    
    $sync.Logs.Clear()
    $sync.Progress = 0
    $sync.IsRunning = $true
    $sync.Finished = $false

    $txtInstallStatus.Visibility = 'Collapsed'
    $txtInstallStatus.Text = ""
    
    # Pass configuration to background
    $sync.RepoLS = $REPO_LABEL_STUDIO
    $sync.RepoML = $REPO_ML_BACKEND
    $sync.WithML = $chkMLBackend.IsChecked
    $sync.InstallPath = Join-Path $txtPath.Text.Trim() "label-studio"
    $sync.LsDir = Join-Path $sync.InstallPath "label-studio-dev"
    $sync.MlDir = Join-Path $sync.InstallPath "label-studio-ml-backend-dev"
    
    Write-Log "Installation started in background..."
    $uiTimer.Start()

    # Create background Runspace
    $rs = [runspacefactory]::CreateRunspace()
    $rs.ApartmentState = "STA"
    $rs.Open()
    $rs.SessionStateProxy.SetVariable("sync", $sync)
    
    $psInstance = [powershell]::Create().AddScript({
        function Log {
            param($msg, $clean = $false)
            if ($clean) { $sync.Logs.Add($msg) }
            else {
                $ts = Get-Date -Format "HH:mm:ss"
                $sync.Logs.Add("[$ts] $msg`r`n")
            }
        }

        function Exec {
            param($cmd, $argStr, $dir)
            
            $executable = $cmd
            $arguments = $argStr

            # 仅针对 npm, yarn 使用 cmd.exe /c 转发，解决 Windows 下批处理文件识别问题
            # 其余命令（如 python, git, poetry）直接运行
            if ($cmd -match "^(npm|yarn)$") {
                $executable = "cmd.exe"
                $arguments = "/c $cmd $argStr"
            }

            $pi = New-Object System.Diagnostics.ProcessStartInfo -Property @{
                FileName = $executable
                Arguments = $arguments
                WorkingDirectory = $dir
                RedirectStandardOutput = $true
                RedirectStandardError = $true
                UseShellExecute = $false
                CreateNoWindow = $true
                StandardOutputEncoding = [System.Text.Encoding]::UTF8
                StandardErrorEncoding = [System.Text.Encoding]::UTF8
            }
            
            # 环境变量增强
            $pi.EnvironmentVariables["GIT_TERMINAL_PROMPT"] = "0"
            $pi.EnvironmentVariables["GIT_ASKPASS"] = "echo"
            $pi.EnvironmentVariables["SSH_ASKPASS"] = "echo"
            $pi.EnvironmentVariables["TERM"] = "xterm"
            
            $p = New-Object System.Diagnostics.Process
            $p.StartInfo = $pi
            
            $outputHandler = {
                if ($EventArgs.Data) { $sync.Logs.Add($EventArgs.Data + "`r`n") }
            }
            
            Register-ObjectEvent -InputObject $p -EventName "OutputDataReceived" -Action $outputHandler | Out-Null
            Register-ObjectEvent -InputObject $p -EventName "ErrorDataReceived" -Action $outputHandler | Out-Null
            
            try {
                if (!$p.Start()) { 
                    Log "Failed to start process: $cmd"
                    return -1 
                }
                $p.BeginOutputReadLine()
                $p.BeginErrorReadLine()
                
                while (!$p.HasExited) {
                    [System.Threading.Thread]::Sleep(100)
                }
            } catch {
                Log "Process Start Error: $($_.Exception.Message) (Command: $cmd)"
                return -2
            } finally {
                Get-Event | Where-Object { $_.SourceEventArgs -eq $p } | Remove-Event -ErrorAction SilentlyContinue
            }
            
            return $p.ExitCode
        }

        try {
            # 1. Directory
            $sync.Progress = 1
            if (!(Test-Path $sync.InstallPath)) { New-Item -Path $sync.InstallPath -ItemType Directory | Out-Null }
            
            # 2. Clone LS
            $sync.Progress = 2
            if (Test-Path $sync.LsDir) {
                Log "Target directory already exists: $($sync.LsDir). Skipping clone."
            } else {
                Log "Cloning Label Studio (Full Repository)..."
                $res = Exec "git" "clone --progress $($sync.RepoLS) label-studio-dev" $sync.InstallPath
                if ($res -ne 0) { throw "Git clone LS failed with code $res" }
            }
            
            Log "Switching to dev branch..."
            Exec "git" "checkout dev" $sync.LsDir

            # 3. Clone & Setup ML
            if ($sync.WithML) {
                $sync.Progress = 3
                if (Test-Path $sync.MlDir) {
                    Log "ML Backend directory already exists: $($sync.MlDir). Skipping clone."
                } else {
                    Log "Cloning ML Backend (Full Repository)..."
                    $resML = Exec "git" "clone --progress $($sync.RepoML) label-studio-ml-backend-dev" $sync.InstallPath
                    if ($resML -ne 0) { throw "Git clone ML failed with code $resML" }
                }
                
                Log "Switching to dev branch in ML Backend..."
                Exec "git" "checkout dev" $sync.MlDir
            }

            # 4. Poetry
            $sync.Progress = 4
            Log "Installing/Updating Poetry..."
            Exec $sync.PythonPath "-m pip install poetry" ""

            # 5. LS Setup
            $sync.Progress = 5
            Log "Configuring Poetry to use in-project virtual environment..."
            Exec $sync.PythonPath "-m poetry config virtualenvs.in-project true" $sync.LsDir

            Log "Running poetry install (this part is slow, will create .venv)..."
            $resInstall = Exec $sync.PythonPath "-m poetry install" $sync.LsDir
            
            # If install fails because of lock file mismatch (bypass slow poetry lock)
            if ($resInstall -ne 0) {
                Log "Poetry install/lock mismatch detected. Switching to FAST MODE (pip install)..."
                # Use pip to satisfy dependencies directly from pyproject.toml, ignoring the lock file
                # First ensure pip is in the venv (usually is)
                $venvPip = Join-Path $sync.LsDir ".venv\Scripts\pip.exe"
                if (Test-Path $venvPip) {
                    $resInstall = Exec $venvPip "install -e ." $sync.LsDir
                } else {
                    Log "Virtual environment not found, trying pip via python..."
                    $resInstall = Exec $sync.PythonPath "-m pip install -e ." $sync.LsDir
                }
            }
            
            if ($resInstall -ne 0) { throw "Installation failed (tried both Poetry and Pip)" }
            
            # 6. Django (Run within the activated .venv environment)
            $sync.Progress = 7
            $venvPython = Join-Path $sync.LsDir ".venv\Scripts\python.exe"
            
            if (!(Test-Path $venvPython)) {
                Log "Warning: Activated .venv python not found. Falling back to poetry run..."
                $pyCmd = $sync.PythonPath
                $pyArgsMigrate = "-m poetry run python label_studio/manage.py migrate"
                $pyArgsCollect = "-m poetry run python label_studio/manage.py collectstatic --noinput"
            } else {
                Log "Activating environment (using $venvPython)..."
                $pyCmd = $venvPython
                $pyArgsMigrate = "label_studio/manage.py migrate"
                $pyArgsCollect = "label_studio/manage.py collectstatic --noinput"
            }

            Log "Running migrations..."
            $resMigrate = Exec $pyCmd $pyArgsMigrate $sync.LsDir
            if ($resMigrate -ne 0) { throw "Migrate failed with code $resMigrate" }

            # 6.1 Collectstatic
            $sync.Progress = 8
            Log "Collecting static files..."
            $resCollect = Exec $pyCmd $pyArgsCollect $sync.LsDir
            if ($resCollect -ne 0) { throw "Collectstatic failed with code $resCollect" }

            # 7. Frontend
            $sync.Progress = 9
            $webDir = Join-Path $sync.LsDir "web"
            if (Test-Path $webDir) {
                Log "Building Frontend (npm install)..."
                $resNpmInstall = Exec "npm" "install --legacy-peer-deps" $webDir
                if ($resNpmInstall -ne 0) { throw "npm install failed with code $resNpmInstall" }

                Log "Ensuring yarn is available (installing globally)..."
                $resYarn = Exec "npm" "install -g yarn" $webDir
                if ($resYarn -ne 0) { throw "Global yarn install failed with code $resYarn" }

                Log "Building Frontend (npm run build)..."
                $resBuild = Exec "npm" "run build" $webDir
                if ($resBuild -ne 0) { throw "npm run build failed with code $resBuild" }
            }

            # 7.5 Setup ML Environment (Post-LS Installation)
            if ($sync.WithML) {
                Log "Starting ML Backend environment setup..."
                
                if (!(Test-Path $sync.MlDir)) {
                    Log "Warning: ML Backend directory not found, skipping setup."
                } else {
                    Log "Creating virtual environment for ML Backend..."
                    $resVenv = Exec $sync.PythonPath "-m venv .venv" $sync.MlDir
                    if ($resVenv -ne 0) { throw "ML venv creation failed" }

                    $mlPip = Join-Path $sync.MlDir ".venv\Scripts\pip.exe"
                    Log "Installing Label Studio SDK in ML environment..."
                    $resSdk = Exec $mlPip "install git+https://github.com/HumanSignal/label-studio-sdk.git@master" $sync.MlDir
                    if ($resSdk -ne 0) { throw "ML SDK install failed" }

                    Log "Installing ML Backend dependencies in editable mode..."
                    $resMlDep = Exec $mlPip "install -e ." $sync.MlDir
                    if ($resMlDep -ne 0) { throw "ML dependencies install failed" }
                }
            }

            # 8. Environment Variable
            Log "Setting LABEL_STUDIO environment variable..."
            try {
                [Environment]::SetEnvironmentVariable("LABEL_STUDIO", $sync.LsDir, "User")
                Log "LABEL_STUDIO set to $($sync.LsDir)"
            } catch {
                Log "Warning: Failed to set environment variable. You may need to set LABEL_STUDIO manually to: $($sync.LsDir)"
            }

            $sync.Progress = 10
            Log "Installation Finished Successfully!"
            $sync.Finished = $true
        } catch {
            Log "STOPPED: $_"
        } finally {
            $sync.IsRunning = $false
        }
    })
    $psInstance.Runspace = $rs
    $script:PowerShellInstance = $psInstance
    $null = $psInstance.BeginInvoke()
}

# Step definitions
$script:step = 0
$totalSteps = 4

function Update-PathValidation {
    $basePath = $txtPath.Text.Trim()
    
    if ([string]::IsNullOrWhiteSpace($basePath)) {
        $txtPathPreview.Text = ""
        $txtPathWarning.Visibility = 'Visible'
        $txtPathWarning.Text = "Path cannot be empty."
        $btnNext.IsEnabled = $false
        return
    }

    # Final installation path
    $finalPath = Join-Path $basePath "label-studio"
    $txtPathPreview.Text = "Installation will be at: $finalPath"

    # Check for non-ASCII characters
    if ($finalPath -match "[^\x00-\x7F]") {
        $txtPathWarning.Visibility = 'Visible'
        $txtPathWarning.Text = "Warning: Path contains non-English characters. This may cause installation failure."
        $btnNext.IsEnabled = $false
    } else {
        $txtPathWarning.Visibility = 'Collapsed'
        $btnNext.IsEnabled = $true
    }
}

function ShowStep {
    param($s)

    # Toggle visibility
    for ($i = 0; $i -lt $pages.Count; $i++) {
        if ($i -eq $s) {
            $pages[$i].Visibility = 'Visible'
        } else {
            $pages[$i].Visibility = 'Collapsed'
        }
    }

    $btnBack.IsEnabled = $s -gt 0
    
    switch ($s) {
        0 {
            $txtStep.Text = "Welcome"
            $btnNext.Content = "Next"
        }
        1 {
            $txtStep.Text = "Environment Check"
            $btnNext.Content = "Next"
            Check-Environment
        }
        2 {
            $txtStep.Text = "Settings"
            $btnNext.Content = "Next"
            Update-PathValidation
        }
        3 {
            $txtStep.Text = "Installation"
            $btnNext.Content = "Next"
            $btnNext.IsEnabled = $false # Disable Next until install starts/completes if desired
        }
        4 {
            $txtStep.Text = "Complete"
            $btnNext.Content = "Finish"
            $btnNext.IsEnabled = $true
            $btnBack.IsEnabled = $false
        }
    }
}

ShowStep $script:step

# Next Button Event
$btnNext.Add_Click({
    if ($script:step -lt $totalSteps) {
        $script:step++
        ShowStep $script:step
    } else {
        $window.Close()
    }
})

# Back Button Event
$btnBack.Add_Click({
    if ($script:step -gt 0) {
        $script:step--
        ShowStep $script:step
    }
})

# Path text change event
$txtPath.Add_TextChanged({
    Update-PathValidation
})

# Browse Button logic (Simple Folder Browser)
$btnBrowse.Add_Click({
    $dialog = New-Object System.Windows.Forms.FolderBrowserDialog
    $dialog.SelectedPath = $txtPath.Text
    if ($dialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        $txtPath.Text = $dialog.SelectedPath
        Update-PathValidation
    }
})

$btnOpenFolder.Add_Click({
    $installPath = Join-Path $txtPath.Text.Trim() "label-studio"
    if (Test-Path $installPath) {
        explorer.exe $installPath
    }
})

$btnStartInstall.Add_Click({
    Start-Installation
})

$window.Add_Closing({
    if ($script:CurrentProcess -and !$script:CurrentProcess.HasExited) {
        try {
            $script:CurrentProcess.Kill()
        } catch {}
    }
})

$window.ShowDialog()
