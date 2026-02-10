Add-Type -AssemblyName PresentationFramework
Add-Type -AssemblyName System.Windows.Forms

# 1. 获取路径
$lsPath = [Environment]::GetEnvironmentVariable("LABEL_STUDIO", "User")
if (-not $lsPath) { $lsPath = $PSScriptRoot }
$parentPath = Split-Path $lsPath -Parent
$mlPath = Join-Path $parentPath "label-studio-ml-backend-dev"

# 远程仓库 URL
$remoteLS = "https://github.com/lei0lei/label-studio-dev.git"
$remoteML = "https://github.com/lei0lei/label-studio-ml-backend-dev.git"

# 2. XAML 界面
[xml]$xaml = @"
<Window xmlns='http://schemas.microsoft.com/winfx/2006/xaml/presentation'
        Title='Label Studio 更新管理器' Height='400' Width='600'
        WindowStartupLocation='CenterScreen' Background='#FF2D2D30'>
    <Grid Margin='20'>
        <Grid.RowDefinitions>
            <RowDefinition Height='Auto'/>
            <RowDefinition Height='*'/>
            <RowDefinition Height='Auto'/>
        </Grid.RowDefinitions>

        <TextBlock Grid.Row='0' Text='代码仓库同步状态' FontSize='20' Foreground='White' Margin='0,0,0,20' FontWeight='Bold'/>

        <StackPanel Grid.Row='1'>
            <!-- Label Studio Core -->
            <Border BorderBrush='#FF3F3F46' BorderThickness='1' Padding='15' Margin='0,0,0,15' Background='#FF333337'>
                <Grid>
                    <Grid.ColumnDefinitions>
                        <ColumnDefinition Width='*'/>
                        <ColumnDefinition Width='Auto'/>
                    </Grid.ColumnDefinitions>
                    <StackPanel>
                        <TextBlock Text='Label Studio (Core)' Foreground='#FF75BEFF' FontWeight='Bold' FontSize='14'/>
                        <TextBlock Name='txtStatusLS' Text='正在检查状态...' Foreground='#FFAAAAAA' FontSize='12' Margin='0,5,0,0'/>
                    </StackPanel>
                    <Button Name='btnUpdateLS' Grid.Column='1' Content='立刻更新' Width='100' Height='30' Visibility='Collapsed' Background='#FF007ACC' Foreground='White' BorderThickness='0'/>
                </Grid>
            </Border>

            <!-- ML Backend -->
            <Border BorderBrush='#FF3F3F46' BorderThickness='1' Padding='15' Background='#FF333337'>
                <Grid>
                    <Grid.ColumnDefinitions>
                        <ColumnDefinition Width='*'/>
                        <ColumnDefinition Width='Auto'/>
                    </Grid.ColumnDefinitions>
                    <StackPanel>
                        <TextBlock Text='ML Backend' Foreground='#FFFF9D00' FontWeight='Bold' FontSize='14'/>
                        <TextBlock Name='txtStatusML' Text='正在检查状态...' Foreground='#FFAAAAAA' FontSize='12' Margin='0,5,0,0'/>
                    </StackPanel>
                    <Button Name='btnUpdateML' Grid.Column='1' Content='立刻更新' Width='100' Height='30' Visibility='Collapsed' Background='#FF007ACC' Foreground='White' BorderThickness='0'/>
                </Grid>
            </Border>
        </StackPanel>

        <TextBlock Name='txtInfo' Grid.Row='2' Text='提示: 更新前请确保本地没有未提交的修改' Foreground='#FFCC6666' FontSize='11' HorizontalAlignment='Center'/>
    </Grid>
</Window>
"@

$reader = New-Object System.Xml.XmlNodeReader $xaml
$window = [Windows.Markup.XamlReader]::Load($reader)

# 获取控件
$txtStatusLS = $window.FindName("txtStatusLS")
$btnUpdateLS = $window.FindName("btnUpdateLS")
$txtStatusML = $window.FindName("txtStatusML")
$btnUpdateML = $window.FindName("btnUpdateML")

# --- 逻辑函数 ---

function Get-GitStatus {
    param($path, $remoteUrl, $statusLabel, $updateButton)
    
    if (-not (Test-Path (Join-Path $path ".git"))) {
        $statusLabel.Text = "错误: 未找到 Git 仓库"
        $statusLabel.Foreground = "#FFFF4D4D"
        return
    }

    $statusLabel.Text = "正在从 GitHub 获取更新..."
    $statusLabel.Foreground = "#FFAAAAAA"

    $j = Start-Job -ScriptBlock {
        param($p, $url)
        try {
            Set-Location $p
            $branch = git branch --show-current
            # 强制从指定 URL 获取当前分支的更新
            git fetch $url $branch -q
            $count = (git rev-list --count HEAD..FETCH_HEAD)
            return $count
        } catch { return -1 }
    } -ArgumentList $path, $remoteUrl
    
    $count = $j | Wait-Job | Receive-Job
    Remove-Job $j

    if ($count -eq 0) {
        $statusLabel.Text = "已是最新版本"
        $statusLabel.Foreground = "#FF4CD964"
        $updateButton.Visibility = "Collapsed"
    } elseif ($count -gt 0) {
        $statusLabel.Text = "发现 $count 个新提交待拉取"
        $statusLabel.Foreground = "#FFFF9D00"
        $updateButton.Visibility = "Visible"
    } else {
        $statusLabel.Text = "检查失败 (请检查网络或 Git 配置)"
        $statusLabel.Foreground = "#FFFF4D4D"
        $updateButton.Visibility = "Collapsed"
    }
}

function Invoke-GitUpdate {
    param($path, $remoteUrl, $statusLabel, $updateButton)
    $statusLabel.Text = "正在同步代码..."
    $updateButton.IsEnabled = $false
    
    # 从指定 URL pull
    $branch = Set-Location $path; git branch --show-current
    $result = Start-Process git -ArgumentList "pull $remoteUrl $branch" -WorkingDirectory $path -NoNewWindow -PassThru -Wait
    
    if ($result.ExitCode -eq 0) {
        $statusLabel.Text = "同步成功！"
        $statusLabel.Foreground = "#FF4CD964"
        $updateButton.Visibility = "Collapsed"
    } else {
        $statusLabel.Text = "同步失败，请手动解决冲突"
        $statusLabel.Foreground = "#FFFF4D4D"
        $updateButton.IsEnabled = $true
    }
}

# 绑定事件
$window.Add_Loaded({
    Get-GitStatus $lsPath $remoteLS $txtStatusLS $btnUpdateLS
    Get-GitStatus $mlPath $remoteML $txtStatusML $btnUpdateML
})

$btnUpdateLS.Add_Click({ Invoke-GitUpdate $lsPath $remoteLS $txtStatusLS $btnUpdateLS })
$btnUpdateML.Add_Click({ Invoke-GitUpdate $mlPath $remoteML $txtStatusML $btnUpdateML })

$window.ShowDialog() | Out-Null
