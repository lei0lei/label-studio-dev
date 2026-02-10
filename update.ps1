Add-Type -AssemblyName PresentationFramework
Add-Type -AssemblyName PresentationCore
Add-Type -AssemblyName WindowsBase
Add-Type -AssemblyName System.Windows.Forms

# 1. Get Path
$lsEnvPath = [Environment]::GetEnvironmentVariable("LABEL_STUDIO", "User")
if (-not $lsEnvPath) { 
    $parentPath = Split-Path $PWD.Path -Parent
} else {
    $parentPath = Split-Path $lsEnvPath -Parent
}

$repo1Path = Join-Path $parentPath "label-studio-dev"
$repo2Path = Join-Path $parentPath "label-studio-ml-backend-dev"

$repo1Remote = "https://github.com/lei0lei/label-studio-dev.git"
$repo2Remote = "https://github.com/lei0lei/label-studio-ml-backend-dev.git"

# 2. XAML Definition
[xml]$xaml = @"
<Window xmlns='http://schemas.microsoft.com/winfx/2006/xaml/presentation'
        Title='Label Studio Git Update Manager' Height='650' Width='1100'
        WindowStartupLocation='CenterScreen' Background='#FF2D2D30'>
    <Grid Margin='20'>
        <Grid.RowDefinitions>
            <RowDefinition Height='Auto'/> <!-- Header -->
            <RowDefinition Height='*'/>    <!-- Two Columns Content -->
        </Grid.RowDefinitions>

        <!-- Header -->
        <StackPanel Grid.Row='0' Margin='0,0,0,15'>
            <TextBlock Text='Label Studio Repository Synchronization' FontSize='22' FontWeight='Bold' Foreground='White'/>
            <TextBlock Text='Parent Path: $parentPath' FontSize='11' Foreground='#FFAAAAAA'/>
        </StackPanel>

        <Grid Grid.Row='1'>
            <Grid.ColumnDefinitions>
                <ColumnDefinition Width='*'/>
                <ColumnDefinition Width='15'/> <!-- Spacer -->
                <ColumnDefinition Width='*'/>
            </Grid.ColumnDefinitions>

            <!-- Column 1: Label Studio Dev -->
            <Grid Grid.Column='0'>
                <Grid.RowDefinitions>
                    <RowDefinition Height='Auto'/>
                    <RowDefinition Height='*'/>
                </Grid.RowDefinitions>
                <StackPanel Grid.Row='0' Margin='0,0,0,10'>
                    <TextBlock Text='label-studio-dev' FontSize='16' FontWeight='Bold' Foreground='#FF75BEFF'/>
                    <StackPanel Orientation='Horizontal' Margin='0,10,0,5'>
                        <Button Name='btnCheck1' Content='Check Status' Width='120' Height='35' Background='#FF007ACC' Foreground='White' BorderThickness='0' Margin='0,0,10,0'/>
                        <Button Name='btnSync1' Content='Sync Now' Width='120' Height='35' Background='#FF4CD964' Foreground='White' BorderThickness='0'/>
                        <TextBlock Name='txtStatus1' Text='Idle' VerticalAlignment='Center' Margin='15,0,0,0' Foreground='#FFAAAAAA' FontWeight='Bold'/>
                    </StackPanel>
                </StackPanel>
                <TextBox Name='txtLogs1' Grid.Row='1' IsReadOnly='True' VerticalScrollBarVisibility='Auto' 
                         Background='#FF1E1E1E' Foreground='#FFD4D4D4' FontFamily='Consolas' FontSize='10' Padding='5'
                         TextWrapping='Wrap' AcceptsReturn='True' BorderThickness='1' BorderBrush='#FF3F3F46'/>
            </Grid>

            <!-- Column 2: ML Backend Dev -->
            <Grid Grid.Column='2'>
                <Grid.RowDefinitions>
                    <RowDefinition Height='Auto'/>
                    <RowDefinition Height='*'/>
                </Grid.RowDefinitions>
                <StackPanel Grid.Row='0' Margin='0,0,0,10'>
                    <TextBlock Text='label-studio-ml-backend-dev' FontSize='16' FontWeight='Bold' Foreground='#FFFF9D00'/>
                    <StackPanel Orientation='Horizontal' Margin='0,10,0,5'>
                        <Button Name='btnCheck2' Content='Check Status' Width='120' Height='35' Background='#FF007ACC' Foreground='White' BorderThickness='0' Margin='0,0,10,0'/>
                        <Button Name='btnSync2' Content='Sync Now' Width='120' Height='35' Background='#FF4CD964' Foreground='White' BorderThickness='0'/>
                        <TextBlock Name='txtStatus2' Text='Idle' VerticalAlignment='Center' Margin='15,0,0,0' Foreground='#FFAAAAAA' FontWeight='Bold'/>
                    </StackPanel>
                </StackPanel>
                <TextBox Name='txtLogs2' Grid.Row='1' IsReadOnly='True' VerticalScrollBarVisibility='Auto' 
                         Background='#FF1E1E1E' Foreground='#FFD4D4D4' FontFamily='Consolas' FontSize='10' Padding='5'
                         TextWrapping='Wrap' AcceptsReturn='True' BorderThickness='1' BorderBrush='#FF3F3F46'/>
            </Grid>
        </Grid>
    </Grid>
</Window>
"@

# 3. Load XAML
try {
    $reader = New-Object System.Xml.XmlNodeReader $xaml
    $window = [Windows.Markup.XamlReader]::Load($reader)
} catch {
    [System.Windows.MessageBox]::Show("XAML Load Error: $($_.Exception.Message)")
    exit
}

# 4. Get Controls
$btnCheck1 = $window.FindName("btnCheck1")
$btnSync1 = $window.FindName("btnSync1")
$txtStatus1 = $window.FindName("txtStatus1")
$txtLogs1 = $window.FindName("txtLogs1")

$btnCheck2 = $window.FindName("btnCheck2")
$btnSync2 = $window.FindName("btnSync2")
$txtStatus2 = $window.FindName("txtStatus2")
$txtLogs2 = $window.FindName("txtLogs2")

# 5. Background Process Logic (Shared with start.ps1 style)
$sync = [hashtable]::Synchronized(@{
    Logs1 = New-Object System.Collections.Generic.List[string]
    Logs2 = New-Object System.Collections.Generic.List[string]
    IsBusy1 = $false
    IsBusy2 = $false
})

function Update-UIStatus {
    param($repoNum, $status, $color)
    $control = if ($repoNum -eq 1) { $txtStatus1 } else { $txtStatus2 }
    $control.Dispatcher.Invoke({
        $control.Text = $status
        $control.Foreground = (New-Object System.Windows.Media.BrushConverter).ConvertFromString($color)
    })
}

function Run-GitTask {
    param($repoNum, $path, $action)
    $isBusyStr = "IsBusy$repoNum"
    $logsStr = "Logs$repoNum"
    
    if ($sync.$isBusyStr) { return }
    $sync.$isBusyStr = $true
    
    Update-UIStatus $repoNum "Working..." "#FFFFD700"

    $runspace = [RunspaceFactory]::CreateRunspace()
    $runspace.Open()
    $runspace.SessionStateProxy.SetVariable("repoNum", $repoNum)
    $runspace.SessionStateProxy.SetVariable("sync", $sync)
    $runspace.SessionStateProxy.SetVariable("path", $path)
    $runspace.SessionStateProxy.SetVariable("action", $action)
    $runspace.SessionStateProxy.SetVariable("logsKey", $logsStr)
    $runspace.SessionStateProxy.SetVariable("isBusyKey", $isBusyStr)

    $ps = [PowerShell]::Create().AddScript({
        function Write-Log($msg) {
            $line = "[$(Get-Date -Format 'HH:mm:ss')] $msg`r`n"
            [System.Threading.Monitor]::Enter($sync.$logsKey)
            try { $sync.$logsKey.Add($line) } finally { [System.Threading.Monitor]::Exit($sync.$logsKey) }
        }

        try {
            if (-not (Test-Path $path)) {
                Write-Log "Error: Path not found at $path"
                return
            }
            Set-Location $path
            
            if ($action -eq "Check") {
                Write-Log "Checking status for $(Split-Path $path -Leaf)..."
                git fetch origin 2>&1 | ForEach-Object { Write-Log $_.ToString() }
                $localDev = git rev-parse dev
                $remoteDev = git rev-parse origin/dev
                if ($localDev -eq $remoteDev) {
                    Write-Log "Success: dev branch is UP TO DATE."
                } else {
                    Write-Log "Warning: dev branch is BEHIND remote."
                }
            } elseif ($action -eq "Sync") {
                Write-Log "Starting synchronization for $(Split-Path $path -Leaf)..."

                # Ensure remote URL
                $targetRemote = if ($repoNum -eq 1) { "https://github.com/lei0lei/label-studio-dev.git" } else { "https://github.com/lei0lei/label-studio-ml-backend-dev.git" }
                Write-Log "Ensuring origin is set to $targetRemote"
                git remote set-url origin $targetRemote 2>&1

                # Fetch all
                Write-Log "Fetching all branches from origin..."
                git fetch --all 2>&1 | ForEach-Object { Write-Log $_.ToString() }
                
                # Identify local branches and sync those with upstream
                $localBranches = git for-each-ref --format='%(refname:short) %(upstream:short)' refs/heads/
                foreach ($line in $localBranches) {
                    $parts = $line -split ' '
                    $local = $parts[0]
                    $upstream = $parts[1]
                    if ($upstream) {
                        Write-Log "Updating branch: $local (tracking $upstream)"
                        git checkout $local 2>&1 | ForEach-Object { Write-Log $_.ToString() }
                        # Use pull to merge remote changes
                        git pull 2>&1 | ForEach-Object { Write-Log $_.ToString() }
                    }
                }
                
                # Final checkout to dev as requested
                $hasDev = git branch --list dev
                if ($hasDev) {
                    Write-Log "Finalizing: Switching to dev branch..."
                    git checkout dev 2>&1 | ForEach-Object { Write-Log $_.ToString() }
                } else {
                    Write-Log "Warning: dev branch not found, staying on current branch."
                }
                Write-Log "Synchronization complete."
            }
        } catch {
            Write-Log "Exception: $($_.Exception.Message)"
        } finally {
            $sync.$isBusyKey = $false
        }
    })
    $ps.Runspace = $runspace
    $ps.BeginInvoke()
}

# Button Events
$btnCheck1.Add_Click({ Run-GitTask 1 $repo1Path "Check" })
$btnSync1.Add_Click({ Run-GitTask 1 $repo1Path "Sync" })

$btnCheck2.Add_Click({ Run-GitTask 2 $repo2Path "Check" })
$btnSync2.Add_Click({ Run-GitTask 2 $repo2Path "Sync" })

# 6. UI Timer (Same polling mechanism as start.ps1)
$uiTimer = New-Object System.Windows.Threading.DispatcherTimer
$uiTimer.Interval = [TimeSpan]::FromMilliseconds(200)
$uiTimer.Add_Tick({
    # Poll Repo 1 Logs
    if ($sync.Logs1.Count -gt 0) {
        $logs = @(); if ([System.Threading.Monitor]::TryEnter($sync.Logs1, 100)) {
            try { $logs = $sync.Logs1.ToArray(); $sync.Logs1.Clear() } finally { [System.Threading.Monitor]::Exit($sync.Logs1) }
        }
        if ($logs.Count -gt 0) { $txtLogs1.AppendText([string]::Concat($logs)); $txtLogs1.ScrollToEnd() }
    }
    # Poll Repo 2 Logs
    if ($sync.Logs2.Count -gt 0) {
        $logs = @(); if ([System.Threading.Monitor]::TryEnter($sync.Logs2, 100)) {
            try { $logs = $sync.Logs2.ToArray(); $sync.Logs2.Clear() } finally { [System.Threading.Monitor]::Exit($sync.Logs2) }
        }
        if ($logs.Count -gt 0) { $txtLogs2.AppendText([string]::Concat($logs)); $txtLogs2.ScrollToEnd() }
    }

    # Update Status Text based on Busy state
    if (-not $sync.IsBusy1 -and $txtStatus1.Text -eq "Working...") {
        $txtStatus1.Text = "Finished"
        $txtStatus1.Foreground = '#FF4CD964'
    }
    if (-not $sync.IsBusy2 -and $txtStatus2.Text -eq "Working...") {
        $txtStatus2.Text = "Finished"
        $txtStatus2.Foreground = '#FF4CD964'
    }
})
$uiTimer.Start()

# 7. Show Dialog
$window.ShowDialog() | Out-Null
