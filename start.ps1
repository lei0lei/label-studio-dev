Add-Type -AssemblyName PresentationFramework
Add-Type -AssemblyName PresentationCore
Add-Type -AssemblyName WindowsBase
Add-Type -AssemblyName System.Windows.Forms

# 1. Get Path
$lsPath = [Environment]::GetEnvironmentVariable("LABEL_STUDIO", "User")
if (-not $lsPath) { 
    $lsPath = "Environment Variable 'LABEL_STUDIO' not found!PLEASE INSTALL LABEL STUDIO FIRST."
    $mlPath = "Unknown"
} else {
    $mlPath = Join-Path (Split-Path $lsPath -Parent) "label-studio-ml-backend-dev"
}

# 2. XAML Definition
[xml]$xaml = @"
<Window xmlns='http://schemas.microsoft.com/winfx/2006/xaml/presentation'
        Title='Label Studio &amp; ML Manager' Height='650' Width='1100'
        WindowStartupLocation='CenterScreen' Background='#FF2D2D30'>
    <Grid Margin='20'>
        <Grid.RowDefinitions>
            <RowDefinition Height='Auto'/> <!-- Header -->
            <RowDefinition Height='*'/>    <!-- Two Columns Content -->
        </Grid.RowDefinitions>

        <!-- Header -->
        <StackPanel Grid.Row='0' Margin='0,0,0,15'>
            <TextBlock Text='Label Studio Multi-Server Manager' FontSize='22' FontWeight='Bold' Foreground='White'/>
            <TextBlock Text='Base Path: $lsPath' FontSize='11' Foreground='#FFAAAAAA'/>
        </StackPanel>

        <Grid Grid.Row='1'>
            <Grid.ColumnDefinitions>
                <ColumnDefinition Width='*'/>
                <ColumnDefinition Width='15'/> <!-- Spacer -->
                <ColumnDefinition Width='*'/>
            </Grid.ColumnDefinitions>

            <!-- Column 1: Label Studio Server -->
            <Grid Grid.Column='0'>
                <Grid.RowDefinitions>
                    <RowDefinition Height='Auto'/>
                    <RowDefinition Height='*'/>
                </Grid.RowDefinitions>
                <StackPanel Grid.Row='0' Margin='0,0,0,10'>
                    <TextBlock Text='Label Studio Server' FontSize='16' FontWeight='Bold' Foreground='#FF75BEFF'/>
                    <StackPanel Orientation='Horizontal' Margin='0,10,0,5'>
                        <Button Name='btnStart' Content='Start Server' Width='120' Height='35' Background='#FF007ACC' Foreground='White' BorderThickness='0'/>
                        <TextBlock Name='txtStatus' Text='Ready' VerticalAlignment='Center' Margin='15,0,0,0' Foreground='#FF4CD964' FontWeight='Bold'/>
                    </StackPanel>
                </StackPanel>
                <TextBox Name='txtLogs' Grid.Row='1' IsReadOnly='True' VerticalScrollBarVisibility='Auto' 
                         Background='#FF1E1E1E' Foreground='#FFD4D4D4' FontFamily='Consolas' FontSize='10' Padding='5'
                         TextWrapping='Wrap' AcceptsReturn='True' BorderThickness='1' BorderBrush='#FF3F3F46'/>
            </Grid>

            <!-- Column 2: ML Backend -->
            <Grid Grid.Column='2'>
                <Grid.RowDefinitions>
                    <RowDefinition Height='Auto'/>
                    <RowDefinition Height='*'/>
                </Grid.RowDefinitions>
                <StackPanel Grid.Row='0' Margin='0,0,0,10'>
                    <TextBlock Text='ML Backend (my_ml_backend)' FontSize='16' FontWeight='Bold' Foreground='#FFFF9D00'/>
                    <StackPanel Orientation='Horizontal' Margin='0,10,0,5'>
                        <Button Name='btnStartML' Content='Start ML' Width='120' Height='35' Background='#FF007ACC' Foreground='White' BorderThickness='0'/>
                        <TextBlock Name='txtStatusML' Text='Ready' VerticalAlignment='Center' Margin='15,0,0,0' Foreground='#FF4CD964' FontWeight='Bold'/>
                    </StackPanel>
                </StackPanel>
                <TextBox Name='txtLogsML' Grid.Row='1' IsReadOnly='True' VerticalScrollBarVisibility='Auto' 
                         Background='#FF1E1E1E' Foreground='#FFD4D4D4' FontFamily='Consolas' FontSize='10' Padding='5'
                         TextWrapping='Wrap' AcceptsReturn='True' BorderThickness='1' BorderBrush='#FF3F3F46'/>
            </Grid>
        </Grid>
    </Grid>
</Window>
"@

# 3. Load XAML (exact same way as deploy.ps1)
try {
    $reader = New-Object System.Xml.XmlNodeReader $xaml
    $window = [Windows.Markup.XamlReader]::Load($reader)
} catch {
    [System.Windows.MessageBox]::Show("XAML Load Error: $($_.Exception.Message)")
    exit
}

# 4. Get Controls
$btnStart = $window.FindName("btnStart")
$txtLogs = $window.FindName("txtLogs")
$txtStatus = $window.FindName("txtStatus")

$btnStartML = $window.FindName("btnStartML")
$txtLogsML = $window.FindName("txtLogsML")
$txtStatusML = $window.FindName("txtStatusML")

# 5. Background Process Logic
$sync = [hashtable]::Synchronized(@{
    Logs = New-Object System.Collections.Generic.List[string]
    IsRunning = $false
    LogsML = New-Object System.Collections.Generic.List[string]
    IsRunningML = $false
})

# --- LS Server Functions ---
function Stop-Server {
    $txtLogs.AppendText("[$(Get-Date -Format 'HH:mm:ss')] Stopping Label Studio processes...`r`n")
    $escapedPath = [regex]::Escape($lsPath)
    Get-CimInstance Win32_Process | Where-Object { 
        $_.CommandLine -match "manage.py\s+runserver" -and ($_.CommandLine -match $escapedPath -or $_.ExecutablePath -match $escapedPath)
    } | ForEach-Object { try { Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue } catch {} }
    $sync.IsRunning = $false
    $btnStart.Content = "Start Server"
    $btnStart.Background = '#FF007ACC'
    $txtStatus.Text = "Stopped"
    $txtStatus.Foreground = '#FFAAAAAA'
    $txtLogs.AppendText("[$(Get-Date -Format 'HH:mm:ss')] Server stopped.`r`n")
}

$btnStart.Add_Click({
    if ($sync.IsRunning) { Stop-Server } else {
        $sync.IsRunning = $true
        $btnStart.Content = "Stop Server"
        $btnStart.Background = '#FFCC0000'
        $txtStatus.Text = "Running"
        $txtStatus.Foreground = '#FF4CD964'
        $txtLogs.AppendText("[$(Get-Date -Format 'HH:mm:ss')] Starting LS Server...`r`n")
        Start-ServerTask
    }
})

function Start-ServerTask {
    $runspace = [RunspaceFactory]::CreateRunspace(); $runspace.Open()
    $runspace.SessionStateProxy.SetVariable("sync", $sync); $runspace.SessionStateProxy.SetVariable("lsPath", $lsPath)
    $ps = [PowerShell]::Create().AddScript({
        try {
            Set-Location $lsPath
            $vEnv = Join-Path $lsPath ".venv"
            $pythonExe = Join-Path $vEnv "Scripts\python.exe"
            
            # 显式激活环境 (模拟 activate.ps1)
            $env:VIRTUAL_ENV = $vEnv
            $env:PATH = "$(Join-Path $vEnv 'Scripts');$env:PATH"
            $env:PYTHONHOME = $null

            & $pythonExe label_studio/manage.py runserver 2>&1 | ForEach-Object {
                $line = $_.ToString() + "`r`n"
                [System.Threading.Monitor]::Enter($sync.Logs)
                try { $sync.Logs.Add($line) } finally { [System.Threading.Monitor]::Exit($sync.Logs) }
            }
        } finally { $sync.IsRunning = $false }
    })
    $ps.Runspace = $runspace; $ps.BeginInvoke()
}

# --- ML Backend Functions ---
function Stop-ML {
    $txtLogsML.AppendText("[$(Get-Date -Format 'HH:mm:ss')] Stopping ML Backend processes...`r`n")
    # Kill process based on ML path and command pattern
    $escapedMLPath = [regex]::Escape($mlPath)
    Get-CimInstance Win32_Process | Where-Object { 
        $_.CommandLine -match "label-studio-ml" -and ($_.CommandLine -match $escapedMLPath -or $_.ExecutablePath -match $escapedMLPath)
    } | ForEach-Object { try { Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue } catch {} }
    $sync.IsRunningML = $false
    $btnStartML.Content = "Start ML"
    $btnStartML.Background = '#FF007ACC'
    $txtStatusML.Text = "Stopped"
    $txtStatusML.Foreground = '#FFAAAAAA'
    $txtLogsML.AppendText("[$(Get-Date -Format 'HH:mm:ss')] ML Backend stopped.`r`n")
}

$btnStartML.Add_Click({
    if ($sync.IsRunningML) { Stop-ML } else {
        $sync.IsRunningML = $true
        $btnStartML.Content = "Stop ML"
        $btnStartML.Background = '#FFCC0000'
        $txtStatusML.Text = "Running"
        $txtStatusML.Foreground = '#FF4CD964'
        $txtLogsML.AppendText("[$(Get-Date -Format 'HH:mm:ss')] Starting ML Backend...`r`n")
        Start-MLTask
    }
})

function Start-MLTask {
    $runspace = [RunspaceFactory]::CreateRunspace(); $runspace.Open()
    $runspace.SessionStateProxy.SetVariable("sync", $sync); $runspace.SessionStateProxy.SetVariable("mlPath", $mlPath)
    $ps = [PowerShell]::Create().AddScript({
        try {
            if (-not (Test-Path $mlPath)) {
                [System.Threading.Monitor]::Enter($sync.LogsML)
                try { $sync.LogsML.Add("Error: ML Path not found at $mlPath`r`n") } finally { [System.Threading.Monitor]::Exit($sync.LogsML) }
                return
            }
            Set-Location $mlPath
            $vEnv = Join-Path $mlPath ".venv"
            $pythonExe = Join-Path $vEnv "Scripts\python.exe"
            $mlExe = Join-Path $vEnv "Scripts\label-studio-ml.exe"

            # 显式激活环境 (模拟 activate.ps1)
            $env:VIRTUAL_ENV = $vEnv
            $env:PATH = "$(Join-Path $vEnv 'Scripts');$env:PATH"
            $env:PYTHONHOME = $null

            # 直接调用 Scripts 目录下的 label-studio-ml.exe
            & $mlExe start my_ml_backend 2>&1 | ForEach-Object {
                $line = $_.ToString() + "`r`n"
                [System.Threading.Monitor]::Enter($sync.LogsML)
                try { $sync.LogsML.Add($line) } finally { [System.Threading.Monitor]::Exit($sync.LogsML) }
            }
        } finally { $sync.IsRunningML = $false }
    })
    $ps.Runspace = $runspace; $ps.BeginInvoke()
}

# 6. UI Timer
$uiTimer = New-Object System.Windows.Threading.DispatcherTimer
$uiTimer.Interval = [TimeSpan]::FromMilliseconds(200)
$uiTimer.Add_Tick({
    # Poll LS Logs
    if ($sync.Logs.Count -gt 0) {
        $logs = @(); if ([System.Threading.Monitor]::TryEnter($sync.Logs, 100)) {
            try { $logs = $sync.Logs.ToArray(); $sync.Logs.Clear() } finally { [System.Threading.Monitor]::Exit($sync.Logs) }
        }
        if ($logs.Count -gt 0) { $txtLogs.AppendText([string]::Concat($logs)); $txtLogs.ScrollToEnd() }
    }
    # Poll ML Logs
    if ($sync.LogsML.Count -gt 0) {
        $logsML = @(); if ([System.Threading.Monitor]::TryEnter($sync.LogsML, 100)) {
            try { $logsML = $sync.LogsML.ToArray(); $sync.LogsML.Clear() } finally { [System.Threading.Monitor]::Exit($sync.LogsML) }
        }
        if ($logsML.Count -gt 0) { $txtLogsML.AppendText([string]::Concat($logsML)); $txtLogsML.ScrollToEnd() }
    }
    # Auto-stop UI updates
    if (-not $sync.IsRunning -and $btnStart.Content -eq "Stop Server") { Stop-Server }
    if (-not $sync.IsRunningML -and $btnStartML.Content -eq "Stop ML") { Stop-ML }
})
$uiTimer.Start()

$window.add_Closing({ 
    Stop-Server 
    Stop-ML 
})

# 7. Show Dialog
$window.ShowDialog() | Out-Null
