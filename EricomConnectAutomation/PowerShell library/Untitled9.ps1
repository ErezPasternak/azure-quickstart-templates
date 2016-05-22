<#
.Synopsis
   To simply create a Nano Server VHD(x) file.
.DESCRIPTION
   Creates a Nano Server VHD(x) file to be mounted to a VM shell in Hyper-V. 
   This interfaces uses the NanoGenerator module that is included as part of the Windows Server 2016 install media.
   It is a prerequisite that the media be mounted to the machine you are running the function from. 
    
   see "http://flynnbundy.com/2015/12/21/visual-studio-2015-creating-a-powershell-gui/" for examples on usage

.EXAMPLE
   New-NanoServer

#>
Function New-NanoServer {

$inputXml = @"
<Window 
        xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        xmlns:d="http://schemas.microsoft.com/expression/blend/2008"
        xmlns:mc="http://schemas.openxmlformats.org/markup-compatibility/2006"
        xmlns:local="clr-namespace:NanoFinal"
        Title="NanoBuilder 1.1" Height="350" Width="525" ResizeMode="CanMinimize" WindowStartupLocation="CenterScreen" Cursor="Arrow" FontFamily="Tahoma">
    <Grid Background="{DynamicResource {x:Static SystemColors.ActiveCaptionBrushKey}}" OpacityMask="{DynamicResource {x:Static SystemColors.GrayTextBrushKey}}">
        <Label Name="IntroLabel" Content="Please fill in the required information. Then, press Build." HorizontalAlignment="Left" Margin="14,11,0,0" VerticalAlignment="Top" Width="309"/>
        <TextBox Name="Name" HorizontalAlignment="Left" Height="23" Margin="109,41,0,0" TextWrapping="Wrap" Text="" VerticalAlignment="Top" Width="133"/>
        <TextBox Name="DomainName" HorizontalAlignment="Left" Height="23" Margin="109,69,0,0" TextWrapping="Wrap" Text="" VerticalAlignment="Top" Width="133" RenderTransformOrigin="0.495,0.524"/>
        <TextBox Name="IPv4" HorizontalAlignment="Left" Height="23" Margin="109,98,0,0" TextWrapping="Wrap" Text="" VerticalAlignment="Top" Width="133"/>
        <TextBox Name="Gateway" HorizontalAlignment="Left" Height="23" Margin="109,126,0,0" TextWrapping="Wrap" Text="" VerticalAlignment="Top" Width="133"/>
        <TextBox Name="Subnet" HorizontalAlignment="Left" Height="23" Margin="109,154,0,0" TextWrapping="Wrap" Text="" VerticalAlignment="Top" Width="133"/>
        <PasswordBox Name="passwordBox" HorizontalAlignment="Left" Margin="109,182,0,0" VerticalAlignment="Top" Width="133" Height="23"/>
        <TextBox Name="MediaPath" HorizontalAlignment="Left" Height="23" Margin="109,221,0,0" TextWrapping="Wrap" Text="" VerticalAlignment="Top" Width="158"/>
        <TextBox Name="BasePath" HorizontalAlignment="Left" Height="23" Margin="109,250,0,0" TextWrapping="Wrap" Text="" VerticalAlignment="Top" Width="158"/>
        <TextBox Name="TargetPath" HorizontalAlignment="Left" Height="23" Margin="109,278,0,0" TextWrapping="Wrap" Text="" VerticalAlignment="Top" Width="158"/>
        <Label Name="NameLabel" Content="Name" HorizontalAlignment="Left" Margin="26,39,0,0" VerticalAlignment="Top"/>
        <Label Name="DomainNameLabel" Content="Domain Name" HorizontalAlignment="Left" Margin="26,68,0,0" VerticalAlignment="Top"/>
        <Label Name="IPv4Label" Content="IPv4" HorizontalAlignment="Left" Margin="26,95,0,0" VerticalAlignment="Top"/>
        <Label Name="GatewayLabel" Content="Gateway" HorizontalAlignment="Left" Margin="26,124,0,0" VerticalAlignment="Top"/>
        <Label Name="SubnetLabel" Content="Mask" HorizontalAlignment="Left" Margin="26,153,0,0" VerticalAlignment="Top"/>
        <Label Name="PasswordLabel" Content="Password" HorizontalAlignment="Left" Margin="26,181,0,0" VerticalAlignment="Top" Width="72"/>
        <Label Name="MediaPathLabel" Content="Media Path" HorizontalAlignment="Left" Margin="26,220,0,0" VerticalAlignment="Top"/>
        <Label Name="BasePathLabel" Content="Base Path" HorizontalAlignment="Left" Margin="26,250,0,0" VerticalAlignment="Top"/>
        <Label Name="TargetPathLabel" Content="Target Path" HorizontalAlignment="Left" Margin="26,279,0,0" VerticalAlignment="Top"/>
        <Border BorderThickness="1" HorizontalAlignment="Left" Height="101" Margin="26,210,0,0" VerticalAlignment="Top" Width="247" Opacity="0.8">
            <Border.BorderBrush>
                <LinearGradientBrush EndPoint="0.5,1" StartPoint="0.5,0">
                    <GradientStop Color="Black" Offset="0"/>
                    <GradientStop Color="#FF3C618D" Offset="1"/>
                </LinearGradientBrush>
            </Border.BorderBrush>
        </Border>
        <CheckBox Name="checkBoxCompute" Content="Compute" HorizontalAlignment="Left" Margin="381,55,0,0" VerticalAlignment="Top"/>
        <CheckBox Name="checkBoxDefender" Content="Defender" HorizontalAlignment="Left" Margin="381,75,0,0" VerticalAlignment="Top"/>
        <CheckBox Name="checkBoxDSC" Content="DSC" HorizontalAlignment="Left" Margin="381,95,0,0" VerticalAlignment="Top"/>
        <CheckBox Name="checkBoxClustering" Content="Clustering" HorizontalAlignment="Left" Margin="381,115,0,0" VerticalAlignment="Top"/>
        <CheckBox Name="checkBoxContainer" Content="Containers" HorizontalAlignment="Left" Margin="381,135,0,0" VerticalAlignment="Top"/>
        <CheckBox Name="checkBoxStorage" Content="Storage" HorizontalAlignment="Left" Margin="381,156,0,0" VerticalAlignment="Top"/>
        <CheckBox Name="checkBoxIIS" Content="IIS" HorizontalAlignment="Left" Margin="381,176,0,0" VerticalAlignment="Top"/>
        <Border BorderThickness="1" HorizontalAlignment="Left" Height="157" Margin="378,48,0,0" VerticalAlignment="Top" Width="130">
            <Border.BorderBrush>
                <LinearGradientBrush EndPoint="0.5,1" StartPoint="0.5,0">
                    <GradientStop Color="Black" Offset="0"/>
                    <GradientStop Color="#FF213A64" Offset="1"/>
                </LinearGradientBrush>
            </Border.BorderBrush>
        </Border>
        <Label Name="label" Content="Packages" HorizontalAlignment="Left" Margin="409,24,0,0" VerticalAlignment="Top" Width="63"/>
        <Button Name="Build" Content="Build" HorizontalAlignment="Left" Margin="434,293,0,0" VerticalAlignment="Top" Width="75"/>
    </Grid>
</Window>
"@

    [void][System.Reflection.Assembly]::LoadWithPartialName('presentationframework')
    [xml]$XAML = $inputXML
    $reader=(New-Object System.Xml.XmlNodeReader $xaml) 
    $Form=[Windows.Markup.XamlReader]::Load( $reader )
    $xaml.SelectNodes("//*[@Name]") | %{Set-Variable -Name "WPF$($_.Name)" -Value $Form.FindName($_.Name)}

    #Button
    $WPFBuild.Add_Click({

    #drives
    $Drives = Get-PSDrive

    #Packages
    $Packages = (((Get-Variable -Name *Checkbox*).Value -match "IsChecked:True")).Name

    $ToInstall = Switch ($Packages){

    "CHECKBOXSTORAGE" { "Microsoft-NanoServer-Storage-Package" }
    "CHECKBOXCOMPUTE" { "Microsoft-NanoServer-Compute-Package"}
    "CHECKBOXDEFENDER" { "Microsoft-NanoServer-Defender-Package"}
    "CHECKBOXCLUSTERING" { "Microsoft-NanoServer-FailoverCluster-Package"}
    "CHECKBOXCONTAINER" { "Microsoft-NanoServer-Containers-Package"}
    "CHECKBOXDSC" { "Microsoft-NanoServer-DSC-Package"}
    "CHECKBOXIIS" { "Microsoft-NanoServer-IIS-Package"}

    }
    #TextBoxes
    $BasePath = $WPFBasePath.text
    $Name = $WPFName.text
    $IPv4 = $WPFIPv4.text
    $MediaPath = $WPFMediaPath.text                                                                              
    $WPFDomainName.text                                                                           
    $TargetPath = $WPFTargetPath.text
    $Gateway = $WPFGateway.text
    $SubnetMask = $WPFSubnet.text
    $passwordBox = $WPFpasswordBox.SecurePassword

    #required for Nano Module, Microsoft's idea not mine!
    if ((Get-Culture).Name -ne 'en-US'){

    $nc = New-Object Globalization.CultureInfo 'en-US'
    [Threading.Thread]::CurrentThread.CurrentCulture = $nc

    }

    Import-Module "$MediaPath\NanoServer\NanoServerImageGenerator\NanoServerImageGenerator.psm1" -Verbose

        $NanoProps = @{
        Mediapath = $MediaPath
        BasePath = $BasePath
        TargetPath = $TargetPath
        ComputerName = $Name
        AdministratorPassword = $passwordBox
        Ipv4Address = $IPv4
        EnableRemoteManagementPort = $true
        DomainName = $DomainName
        Ipv4SubnetMask = $SubnetMask
        Ipv4Gateway  = $Gateway
        InterfaceNameOrIndex = 'Ethernet'
        DeploymentType = 'Guest'
        Edition = 'Datacenter'
     } 
    if ($Null -eq $NanoProps.DomainName){
    $NanoProps.Remove('DomainName')
    }

    #create
    New-NanoServerImage @NanoProps -Verbose
    
        #Add packages
        Mount-DiskImage -ImagePath "$TargetPath" -Verbose
    
        #find nano drive
        $Newlymounted = Get-PSDrive
        $NanoDrive = (Compare-Object -ReferenceObject $Drives -DifferenceObject $Newlymounted).inputObject.Name
    
        foreach ($Package in $ToInstall){
        Add-WindowsPackage –Path ($NanoDrive + ':') –PackagePath "$BasePath\Packages\$Package.cab" -Verbose
        }
        Dismount-DiskImage -ImagePath "$TargetPath" -verbose

    $form.Close()

    })

    $Form.ShowDialog() | Out-Null 

}
New-NanoServer