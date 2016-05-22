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

Function New-EricomConnectUI {
[xml]$inputXml = @'
<Window 
        xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        xmlns:mc="http://schemas.openxmlformats.org/markup-compatibility/2006"
        xmlns:local="clr-namespace:AutomationUI"
        Title="MainWindow" Height="350" Width="525">
    <WrapPanel>
        <TabControl x:Name="tabControl" HorizontalAlignment="Left" Height="273" VerticalAlignment="Top" Width="481">
            <TabItem Header="Installer location ">
                <Grid Background="#FFE5E5E5" Margin="10,10,-26,-29">
                    <Grid.ColumnDefinitions>
                        <ColumnDefinition Width="25*"/>
                        <ColumnDefinition Width="21*"/>
                        <ColumnDefinition Width="443*"/>
                    </Grid.ColumnDefinitions>
                    <Label x:Name="label" Content="Installer Name" Grid.Column="2" HorizontalAlignment="Left" Margin="53,51,0,0" VerticalAlignment="Top" Width="108"/>
                    <Label x:Name="label1" Content="Download Location" Grid.Column="2" HorizontalAlignment="Left" Height="26" Margin="53,82,0,0" VerticalAlignment="Top" Width="124"/>
                    <Label x:Name="label2" Content="Location Location" Grid.Column="2" HorizontalAlignment="Left" Height="26" Margin="53,113,0,0" VerticalAlignment="Top" Width="108"/>
                    <TextBox x:Name="textBox" Grid.Column="2" HorizontalAlignment="Left" Height="23" Margin="182,51,0,0" TextWrapping="Wrap" Text="TextBox" VerticalAlignment="Top" Width="198"/>
                    <TextBox x:Name="textBox1" Grid.Column="2" HorizontalAlignment="Left" Height="23" Margin="182,82,0,0" TextWrapping="Wrap" Text="TextBox" VerticalAlignment="Top" Width="198"/>
                    <TextBox x:Name="textBox2" Grid.Column="2" HorizontalAlignment="Left" Height="23" Margin="182,113,0,0" TextWrapping="Wrap" Text="TextBox" VerticalAlignment="Top" Width="198"/>
                </Grid>
            </TabItem>
            <TabItem Header="Active Directoy">
                <Grid Background="#FFE5E5E5" Margin="10,10,-26,-29">
                    <Grid.ColumnDefinitions>
                        <ColumnDefinition Width="25*"/>
                        <ColumnDefinition Width="21*"/>
                        <ColumnDefinition Width="443*"/>
                    </Grid.ColumnDefinitions>
                    <Label x:Name="label3" Content="Domain Name" Grid.Column="2" HorizontalAlignment="Left" Margin="53,51,0,0" VerticalAlignment="Top" Width="108"/>
                    <Label x:Name="label4" Content="Admin Usrname" Grid.Column="2" HorizontalAlignment="Left" Height="26" Margin="53,82,0,0" VerticalAlignment="Top" Width="124"/>
                    <Label x:Name="label5" Content="Admin Password" Grid.Column="2" HorizontalAlignment="Left" Height="26" Margin="53,113,0,0" VerticalAlignment="Top" Width="108"/>
                    <TextBox x:Name="DomainNameBox" Grid.Column="2" HorizontalAlignment="Left" Height="23" Margin="182,51,0,0" TextWrapping="Wrap" Text="TextBox" VerticalAlignment="Top" Width="198"/>
                    <TextBox x:Name="DomainAdminBox" Grid.Column="2" HorizontalAlignment="Left" Height="23" Margin="182,82,0,0" TextWrapping="Wrap" Text="TextBox" VerticalAlignment="Top" Width="198"/>
                    <TextBox x:Name="DomainPasswordBox" Grid.Column="2" HorizontalAlignment="Left" Height="23" Margin="182,113,0,0" TextWrapping="Wrap" Text="TextBox" VerticalAlignment="Top" Width="198"/>
                </Grid>
            </TabItem>
            <TabItem Header="Grid Settings" HorizontalAlignment="Left" Height="20" VerticalAlignment="Top" Width="55">
                <Grid Background="#FFE5E5E5" Margin="10,10,-26,-29">
                    <Grid.ColumnDefinitions>
                        <ColumnDefinition Width="25*"/>
                        <ColumnDefinition Width="21*"/>
                        <ColumnDefinition Width="443*"/>
                    </Grid.ColumnDefinitions>
                    <Label x:Name="GridName" Content="GridName" Grid.Column="2" HorizontalAlignment="Left" Margin="53,47,0,0" VerticalAlignment="Top" Width="108" RenderTransformOrigin="0.444,-3.692"/>
                    <Label x:Name="HostOrIP" Content="Host Or IP" Grid.Column="2" HorizontalAlignment="Left" Height="26" Margin="53,154,0,0" VerticalAlignment="Top" Width="124"/>
                    <Label x:Name="DatabaseServer" Content="Database Server" Grid.Column="2" HorizontalAlignment="Left" Height="26" Margin="53,78,0,0" VerticalAlignment="Top" Width="108"/>
                    <Label x:Name="DatabaseName" Content="Database Name" Grid.Column="2" HorizontalAlignment="Left" Margin="53,117,0,0" VerticalAlignment="Top" Width="108"/>
                    <Label x:Name="LookupHosts" Content="Lookup Hosts" Grid.Column="2" HorizontalAlignment="Left" Height="26" Margin="53,190,0,0" VerticalAlignment="Top" Width="124"/>
                   
                    <TextBox x:Name="GridNameBox" Grid.Column="2" HorizontalAlignment="Left" Height="23" Margin="191,47,0,0" TextWrapping="Wrap" Text="TextBox" VerticalAlignment="Top" Width="198"/>
                    <TextBox x:Name="HostOrIPBox" Grid.Column="2" HorizontalAlignment="Left" Height="23" Margin="191,154,0,0" TextWrapping="Wrap" Text="TextBox" VerticalAlignment="Top" Width="198"/>
                    <TextBox x:Name="DatabaseServerBox" Grid.Column="2" HorizontalAlignment="Left" Height="23" Margin="191,82,0,0" TextWrapping="Wrap" Text="TextBox" VerticalAlignment="Top" Width="198"/>
                    <TextBox x:Name="DatabaseNameBox" Grid.Column="2" HorizontalAlignment="Left" Height="23" Margin="191,121,0,0" TextWrapping="Wrap" Text="TextBox" VerticalAlignment="Top" Width="198"/>
                    <TextBox x:Name="LookupHostsBox" Grid.Column="2" HorizontalAlignment="Left" Height="23" Margin="191,190,0,0" TextWrapping="Wrap" Text="TextBox" VerticalAlignment="Top" Width="198"/>
                </Grid>
            </TabItem>
            <TabItem Header="E-Mail" HorizontalAlignment="Left" Height="20" VerticalAlignment="Top" Width="55">
               
            </TabItem>
        </TabControl>
       

    </WrapPanel>
 <Button x:Name="Generate" Content="Generate" Width="75" AutomationProperties.Name="Generate"/>
</Window>
'@

[void][System.Reflection.Assembly]::LoadWithPartialName('presentationframework')
[xml]$XAML = $inputXml
$reader=(New-Object System.Xml.XmlNodeReader $xaml) 
$Form=[Windows.Markup.XamlReader]::Load( $reader )
$xaml.SelectNodes("//*[@Name]") | %{Set-Variable -Name "WPF$($_.Name)" -Value $Form.FindName($_.Name)}	

$WPFGenerate.Add_Click({
    Start-Process 'http://www.metzerfarms.com/DucksForSale.cfm'
})


$Form.ShowDialog() | Out-Null 
}
New-EricomConnectUI