Add-Type -AssemblyName PresentationFramework
Add-Type -AssemblyName PresentationCore
Add-Type -AssemblyName WindowsBase
Add-Type -AssemblyName System.Windows.Forms

[xml]$xaml = @"
<Window xmlns='http://schemas.microsoft.com/winfx/2006/xaml/presentation'
        Title='Label Studio Installer' Height='500' Width='600'
        WindowStartupLocation='CenterScreen' Background='#FF2D2D30' ResizeMode='NoResize'>
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
                    <RowDefinition Height='*'/>
                </Grid.RowDefinitions>
                <ProgressBar Name='progressInstall' Grid.Row='0' Height='25' Margin='0,0,0,10'/>
                <CheckBox Name='chkMLBackend' Grid.Row='1' Content='Install Label Studio ML Backend' Foreground='White' Margin='0,0,0,10'/>
                <Button Name='btnStartInstall' Grid.Row='2' Content='Start Installation' Height='35' Margin='0,0,0,10' FontSize='14' FontWeight='Bold'/>
                <TextBox Name='txtLogs' Grid.Row='3' Background='#FF1E1E1E' Foreground='#FFD4D4D4' 
                         IsReadOnly='True' VerticalScrollBarVisibility='Auto' TextWrapping='Wrap' FontFamily='Consolas' FontSize='11'/>
            </Grid>

            <!-- Step 4: Complete -->
            <StackPanel Name='page4' Visibility='Collapsed'>
                <TextBlock Foreground='White' FontSize='18' FontWeight='Bold' HorizontalAlignment='Center' Margin='0,50,0,10'>
                    Installation Complete!
                </TextBlock>
                <TextBlock Foreground='White' HorizontalAlignment='Center'>
                    Label Studio has been successfully installed.
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
$progressInstall = $window.FindName("progressInstall")
$txtLogs = $window.FindName("txtLogs")

# Initialize Path
$txtPath.Text = $env:USERPROFILE

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

    # List all Python versions found in PATH
    try {
        $pyPaths = where.exe python 2>$null
        $allPyVers = @()
        foreach ($path in $pyPaths) {
            $ver = & $path --version 2>&1
            $allPyVers += "$ver ($path)"
        }
        if ($allPyVers.Count -gt 0) {
            $lblAllPython.Text = "Found Python(s):`n" + ($allPyVers -join "`n")
        }
    } catch {}

    # Check Python (3.10+)
    try {
        $pyFullVer = python --version 2>&1
        if ($LASTEXITCODE -eq 0) {
            $pyVerMatch = [regex]::Match($pyFullVer, "(\d+\.\d+\.\d+)")
            if ($pyVerMatch.Success) {
                $pyVer = [version]$pyVerMatch.Groups[1].Value
                if ($pyVer -ge [version]"3.10") {
                    $chkPython.Content = "Python: Found ($pyFullVer)"
                    $chkPython.IsChecked = $true
                    $pythonOk = $true
                } else {
                    $chkPython.Content = "Python: Too old ($pyFullVer). Need 3.10+"
                }
            }
        } else {
            $chkPython.Content = "Python: Not found"
        }
    } catch {
        $chkPython.Content = "Python: Not found"
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
            $nodeVerMatch = [regex]::Match($nodeFullVer, "(\d+\.\d+\.\d+)")
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

function Write-Log {
    param($msg)
    $timestamp = Get-Date -Format "HH:mm:ss"
    $txtLogs.AppendText("[$timestamp] $msg`r`n")
    $txtLogs.ScrollToEnd()
}

function Start-Installation {
    $btnStartInstall.IsEnabled = $false
    $chkMLBackend.IsEnabled = $false
    $btnNext.IsEnabled = $false
    $btnBack.IsEnabled = $false
    
    # Correct final installation path
    $basePath = $txtPath.Text.Trim()
    $installPath = Join-Path $basePath "label-studio"
    $withML = $chkMLBackend.IsChecked
    
    Write-Log "Starting installation..."
    Write-Log "Target path: $installPath"
    if ($withML) { Write-Log "Option: Include Label Studio ML Backend" }
    
    $steps = @(
        "Checking directory existence...",
        "Creating directory: $installPath",
        "Cloning Label Studio repository...",
        "Setting up virtual environment...",
        "Installing dependencies (this may take a while)...",
        "Configuring database...",
        "Finalizing installation..."
    )
    
    if ($withML) {
        $steps += "Installing ML Backend..."
    }
    
    $progressInstall.Minimum = 0
    $progressInstall.Maximum = $steps.Count
    $progressInstall.Value = 0
    
    for ($i = 0; $i -lt $steps.Count; $i++) {
        $currentStep = $steps[$i]
        Write-Log $currentStep
        
        # Simulate work
        Start-Sleep -Seconds 1
        
        # Force UI update (Simple way for PowerShell scripts)
        $progressInstall.Value = $i + 1
        [System.Windows.Forms.Application]::DoEvents()
    }
    
    Write-Log "Installation finished successfully!"
    $btnNext.IsEnabled = $true
    $btnNext.Content = "Next"
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

$btnStartInstall.Add_Click({
    Start-Installation
})

$window.ShowDialog()
