
# Ericom Connect installer location   
$InstallerName = "EricomConnectPOC.exe"
$EC_download_url_or_unc = "https://www.ericom.com/demos/"+ $InstallerName 
$EC_local_path = "C:\Windows\Temp\" + $InstallerName

# Active Directory 
$domainName = "test.local"
$AdminUser = "admin@test.local"
$AdminPassword = "admin"

# Ericom Connect Grid Setting
$GridName = $env:computername
$HostOrIp = (Get-NetIPAddress -AddressFamily IPv4)[0].IPAddress # [System.Net.Dns]::GetHostByName((hostname)).HostName
$SaUser = ""
$SaPassword = ""
$DatabaseServer = $env:computername+"\ERICOMCONNECTDB"
$DatabaseName = $env:computername
$ConnectConfigurationToolPath = "\Ericom Software\Ericom Connect Configuration Tool\EricomConnectConfigurationTool.exe"
$UseWinCredentials = "true"
$LookUpHosts = [System.Net.Dns]::GetHostByName((hostname)).HostName

# E-mail Settings
$To = "erez.pasternak@ericom.com"
$From = "daas@ericom.com"
$SMTPServer = "ericom-com.mail.protection.outlook.com"
$SMTPSUser = "daas@ericom.com"
$SMTPassword = "1qaz@Wsx#"
$SMTPPort = 25
$externalFqdn = [System.Net.Dns]::GetHostByName((hostname)).HostName

Function New-ConnectServer {

$inputXml = @"
<Window 
        xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        xmlns:d="http://schemas.microsoft.com/expression/blend/2008"
        xmlns:mc="http://schemas.openxmlformats.org/markup-compatibility/2006"
        xmlns:local="clr-namespace:NanoFinal"
        Title="Ericom Connect Builder 0.9" Height="400" Width="525" ResizeMode="CanMinimize" WindowStartupLocation="CenterScreen" Cursor="Arrow" FontFamily="Tahoma">
    <Grid Background="{DynamicResource {x:Static SystemColors.ActiveCaptionBrushKey}}" OpacityMask="{DynamicResource {x:Static SystemColors.GrayTextBrushKey}}">
        <Label Name="IntroLabel" Content="Please fill in the required information. Then, press Deploy." HorizontalAlignment="Left" Margin="14,11,0,0" VerticalAlignment="Top" Width="349"/>
        <TextBox Name="DomainName" HorizontalAlignment="Left" Height="23" Margin="129,41,0,0" TextWrapping="Wrap" Text="" VerticalAlignment="Top" Width="193"/>
        <TextBox Name="AdminName" HorizontalAlignment="Left" Height="23" Margin="129,69,0,0" TextWrapping="Wrap" Text="" VerticalAlignment="Top" Width="193" RenderTransformOrigin="0.495,0.524"/>
        <TextBox Name="AdminPassword" HorizontalAlignment="Left" Height="23" Margin="129,98,0,0" TextWrapping="Wrap" Text="" VerticalAlignment="Top" Width="193"/>
        <TextBox Name="GridName" HorizontalAlignment="Left" Height="23" Margin="129,126,0,0" TextWrapping="Wrap" Text="" VerticalAlignment="Top" Width="193"/>
        <TextBox Name="DatabaseServer" HorizontalAlignment="Left" Height="23" Margin="129,154,0,0" TextWrapping="Wrap" Text="" VerticalAlignment="Top" Width="193"/>
        <TextBox Name="DatabaseName" HorizontalAlignment="Left" Margin="129,182,0,0" VerticalAlignment="Top" Width="193" Height="23"/>
        <TextBox Name="EMail" HorizontalAlignment="Left" Margin="129,210,0,0" VerticalAlignment="Top" Width="193" Height="23"/>
        <TextBox Name="DownloadPath" HorizontalAlignment="Left" Height="23" Margin="129,250,0,0" TextWrapping="Wrap" Text="" VerticalAlignment="Top" Width="333"/>
        <TextBox Name="LocalPath" HorizontalAlignment="Left" Height="23" Margin="129,278,0,0" TextWrapping="Wrap" Text="" VerticalAlignment="Top" Width="333"/>
        <TextBox Name="MSIName" HorizontalAlignment="Left" Height="23" Margin="129,306,0,0" TextWrapping="Wrap" Text="" VerticalAlignment="Top" Width="333"/>
        <Label Name="DomainNameLabel" Content="Domain Name" HorizontalAlignment="Left" Margin="26,39,0,0" VerticalAlignment="Top"/>
        <Label Name="NameLabel" Content="Admin Name" HorizontalAlignment="Left" Margin="26,68,0,0" VerticalAlignment="Top"/>
        <Label Name="PasswordLabel" Content="Admin Password" HorizontalAlignment="Left" Margin="26,95,0,0" VerticalAlignment="Top"/>
        <Label Name="GridLabel" Content="Grid Name" HorizontalAlignment="Left" Margin="26,124,0,0" VerticalAlignment="Top"/>
        <Label Name="DBServerLabel" Content="Database Server" HorizontalAlignment="Left" Margin="26,153,0,0" VerticalAlignment="Top"/>
        <Label Name="DNNameLabel" Content="Database Name" HorizontalAlignment="Left" Margin="26,181,0,0" VerticalAlignment="Top" Width="99"/>
        <Label Name="MailLabel" Content="E-Mail" HorizontalAlignment="Left" Margin="26,210,0,0" VerticalAlignment="Top" Width="99"/>
        <Label Name="DownloadPathLabel" Content="Download Path" HorizontalAlignment="Left" Margin="26,250,0,0" VerticalAlignment="Top"/>
        <Label Name="LocalPathLabel" Content="Local Path" HorizontalAlignment="Left" Margin="26,279,0,0" VerticalAlignment="Top"/>
        <Label Name="MSINameLabel" Content="Target Path" HorizontalAlignment="Left" Margin="26,306,0,0" VerticalAlignment="Top"/>
        <Border BorderThickness="1" HorizontalAlignment="Left" Height="101" Margin="26,240,0,0" VerticalAlignment="Top" Width="447" Opacity="0.8">
            <Border.BorderBrush>
                <LinearGradientBrush EndPoint="0.5,1" StartPoint="0.5,0">
                    <GradientStop Color="Black" Offset="0"/>
                    <GradientStop Color="#FF3C618D" Offset="1"/>
                </LinearGradientBrush>
            </Border.BorderBrush>
        </Border>
        <CheckBox Name="checkBoxConfigureWindows" Content="Configure Windows" HorizontalAlignment="Left" Margin="381,55,0,0" VerticalAlignment="Top"/>
        <CheckBox Name="checkBoxInstallEC" Content="InstallEC" HorizontalAlignment="Left" Margin="381,75,0,0" VerticalAlignment="Top"/>
        <CheckBox Name="checkBoxCreateGrid" Content="CreateGrid" HorizontalAlignment="Left" Margin="381,95,0,0" VerticalAlignment="Top"/>
        <CheckBox Name="checkBoxCreateUser" Content="Create Users" HorizontalAlignment="Left" Margin="381,115,0,0" VerticalAlignment="Top"/>
        <CheckBox Name="checkBoxInstallApps" Content="Install Apps" HorizontalAlignment="Left" Margin="381,135,0,0" VerticalAlignment="Top"/>
        <CheckBox Name="checkBoxPublishApps" Content="Publish Apps" HorizontalAlignment="Left" Margin="381,156,0,0" VerticalAlignment="Top"/>
        <CheckBox Name="checkBoxSystem" Content="System Test" HorizontalAlignment="Left" Margin="381,176,0,0" VerticalAlignment="Top"/>
        <Border BorderThickness="1" HorizontalAlignment="Left" Height="157" Margin="378,48,0,0" VerticalAlignment="Top" Width="130">
            <Border.BorderBrush>
                <LinearGradientBrush EndPoint="0.5,1" StartPoint="0.5,0">
                    <GradientStop Color="Black" Offset="0"/>
                    <GradientStop Color="#FF213A64" Offset="1"/>
                </LinearGradientBrush>
            </Border.BorderBrush>
        </Border>
        <Label Name="label" Content="Actions" HorizontalAlignment="Left" Margin="409,24,0,0" VerticalAlignment="Top" Width="63"/>
        <Button Name="Deploy" Content="Deploy" HorizontalAlignment="Left" Margin="434,350,0,0" VerticalAlignment="Top" Width="75"/>
    </Grid>
</Window>
"@

    [void][System.Reflection.Assembly]::LoadWithPartialName('presentationframework')
    [xml]$XAML = $inputXML
    $reader=(New-Object System.Xml.XmlNodeReader $xaml) 
    $Form=[Windows.Markup.XamlReader]::Load( $reader )
    $xaml.SelectNodes("//*[@Name]") | %{Set-Variable -Name "WPF$($_.Name)" -Value $Form.FindName($_.Name)}

    $WPFDomainName.text = $domainName
    $WPFAdminName.text = $AdminUser
    $WPFAdminPassword.text = $AdminPassword
    $WPFGridName.text = $GridName
    $WPFDatabaseServer.text = $DatabaseServer 
    $WPFDatabaseName.text = $DatabaseName
    $WPFDownloadPath.text = $EC_download_url_or_unc 
    $WPFLocalPath.text    = $EC_local_path
    $WPFMSIName.text      = $InstallerName
    $WPFEMail.text        = $To
    
    #Button
    $WPFDeploy.Add_Click({
    
    $domainName     = $WPFDomainName.text 
    $AdminUser      = $WPFAdminName.text  
    $AdminPassword  = $WPFAdminPassword.SecurePassword 
    $GridName       = $WPFGridName.text  
    $DatabaseServer = $WPFDatabaseServer.text  
    $DatabaseName   = $WPFDatabaseName.text 
    $EC_download_url_or_unc = $WPFDownloadPath.text  
    $EC_local_path  = $WPFLocalPath.text    
    $InstallerName  = $WPFMSIName.text       
    $To             = $WPFEMail.text  
    
   
    #Actions
    $Actions = (((Get-Variable -Name *Checkbox*).Value -match "IsChecked:True")).Name

    $ToInstall = Switch ($Actions){

    "CHECKBOXSTORAGE" { "Microsoft-NanoServer-Storage-Package" }
    "CHECKBOXCOMPUTE" { "Microsoft-NanoServer-Compute-Package"}
    "CHECKBOXDEFENDER" { "Microsoft-NanoServer-Defender-Package"}
    "CHECKBOXCLUSTERING" { "Microsoft-NanoServer-FailoverCluster-Package"}
    "CHECKBOXCONTAINER" { "Microsoft-NanoServer-Containers-Package"}
    "CHECKBOXDSC" { "Microsoft-NanoServer-DSC-Package"}
    "CHECKBOXIIS" { "Microsoft-NanoServer-IIS-Package"}

    }
  

    $form.Close()

    })

    $Form.ShowDialog() | Out-Null 

}
New-ConnectServer