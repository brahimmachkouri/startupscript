<#
function Show-HiddenFile
{
    param([Switch]$Off)
    
    $value = -not $Off.IsPresent
    Set-ItemProperty -Path HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced `
    -Name Hidden -Value $value -type DWORD

    $shell = New-Object -ComObject Shell.Application
    $shell.Windows() |
        Where-Object { $_.document.url -eq $null } |
        ForEach-Object { $_.Refresh() }
} 
function Show-FileExtensions
{
    Push-Location
    Set-Location HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced
    Set-ItemProperty . HideFileExt "0"
    Pop-Location
    Stop-Process -processName: Explorer -force # This will restart the Explorer service to make this work.
}
#>

function Enable-RemoteDesktop {
<#
.SYNOPSIS
Allows Remote Desktop access to machine and enables Remote Desktop firewall rule
.PARAMETER DoNotRequireUserLevelAuthentication
Allows connections from computers running remote desktop
without Network Level Authentication (not recommended)
.LINK
https://boxstarter.org
#>

    param(
        [switch]$DoNotRequireUserLevelAuthentication
    )

    Write-host "Enabling Remote Desktop..."
    $obj = Get-WmiObject -Class "Win32_TerminalServiceSetting" -Namespace root\cimv2\terminalservices
    if($obj -eq $null) {
        Write-host "Unable to locate terminalservices namespace. Remote Desktop is not enabled"
        return
    }
    try {
        $obj.SetAllowTsConnections(1,1) | Out-Null
    }
    catch {
        throw "There was a problem enabling remote desktop. Make sure your operating system supports remote desktop and there is no group policy preventing you from enabling it."
    }

    $obj2 = Get-WmiObject -class Win32_TSGeneralSetting -Namespace root\cimv2\terminalservices -ComputerName . -Filter "TerminalName='RDP-tcp'"

    if($obj2.UserAuthenticationRequired -eq $null) {
        Write-host "Unable to locate Remote Desktop NLA namespace. Remote Desktop NLA is not enabled"
        return
    }
    try {
        if($DoNotRequireUserLevelAuthentication) {
            $obj2.SetUserAuthenticationRequired(0) | Out-Null
            Write-host "Disabling Remote Desktop NLA ..."
        }
        else {
			$obj2.SetUserAuthenticationRequired(1) | Out-Null
            Write-host "Enabling Remote Desktop NLA ..."
        }
    }
    catch {
        throw "There was a problem enabling Remote Desktop NLA. Make sure your operating system supports Remote Desktop NLA and there is no group policy preventing you from enabling it."
    }
}
function Set-TaskbarOptions {
<#
.SYNOPSIS
Sets options for the Windows Task Bar.
.PARAMETER Lock
Locks the taskbar.
.PARAMETER UnLock
Unlocks the taskbar.
.PARAMETER AutoHide
Autohides the taskbar.
.PARAMETER NoAutoHide
No autohiding on the taskbar.
.PARAMETER Size
Changes the size of the taskbar icons.  Valid inputs are Small and Large.
.PARAMETER Dock
Changes the location in which the taskbar is docked. Valid inputs are Top, Left, Bottom and Right.
.PARAMETER Combine
Changes the taskbar icon combination style. Valid inputs are Always, Full, and Never.
.PARAMETER AlwaysShowIconsOn
Turn on always show all icons in the notification area.
.PARAMETER AlwaysShowIconsOff
Turn off always show all icons in the notification area.
.PARAMETER MultiMonitorOn
Turn on Show tasbkar on all displays.
.PARAMETER MultiMonitorOff
Turn off Show taskbar on all displays.
.PARAMETER MultiMonitorMode
Changes the behavior of the taskbar when using multiple displays. Valid inputs are All, MainAndOpen, and Open.
.PARAMETER MultiMonitorCombine
Changes the taskbar icon combination style for non-primary displays. Valid inputs are Always, Full, and Never.
.EXAMPLE
Set-BoxstarterTaskbarOptions -Lock -AutoHide -AlwaysShowIconsOff -MultiMonitorOff
Locks the taskbar, enabled auto-hiding of the taskbar, turns off showing icons
in the notification area and turns off showing the taskbar on multiple monitors.
.EXAMPLE
Set-BoxstarterTaskbarOptions -Unlock -AlwaysShowIconsOn -Size Large -MultiMonitorOn -MultiMonitorCombine Always
Unlocks the taskbar and always shows large notification icons. Sets
multi-monitor support and always combine icons on non-primary monitors.
#>
    [CmdletBinding(DefaultParameterSetName='unlock')]
    param(
        [Parameter(ParameterSetName='lockhide')]
        [Parameter(ParameterSetName='locknohide')]
        [switch]
        $Lock,

        [Parameter(ParameterSetName='unlock')]
        [Parameter(ParameterSetName='unlockhide')]
        [Parameter(ParameterSetName='unlocknohide')]
        [switch]
        $UnLock,

        [Parameter(ParameterSetName='lockhide')]
        [Parameter(ParameterSetName='unlockhide')]
        [switch]
        $AutoHide,

        [Parameter(ParameterSetName='locknohide')]
        [Parameter(ParameterSetName='unlocknohide')]
        [switch]
        $NoAutoHide,

        [Parameter(ParameterSetName='AlwaysShowIconsOn')]
        [switch]
        $AlwaysShowIconsOn,

        [Parameter(ParameterSetName='AlwaysShowIconsOff')]
        [switch]
        $AlwaysShowIconsOff,

        [ValidateSet('Small','Large')]
        [String]
        $Size,

        [ValidateSet('Top','Left','Bottom','Right')]
        [String]
        $Dock,

        [ValidateSet('Always','Full','Never')]
        [String]
        $Combine,

        [Parameter(ParameterSetName='MultiMonitorOff')]
        [switch]
        $MultiMonitorOff,

        [Parameter(ParameterSetName='MultiMonitorOn')]
        [switch]
        $MultiMonitorOn,

        [Parameter(ParameterSetName='MultiMonitorOn')]
        [ValidateSet('All', 'MainAndOpen', 'Open')]
        [String]
        $MultiMonitorMode,

        [Parameter(ParameterSetName='MultiMonitorOn')]
        [ValidateSet('Always','Full','Never')]
        [String]
        $MultiMonitorCombine
    )

    $explorerKey = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer'
    $key = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced'
    $settingKey = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\StuckRects2'

    if (-not (Test-Path -Path $settingKey)) {
        $settingKey = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\StuckRects3'
    }

    if (Test-Path -Path $key) {
        if ($Lock) {
            Set-ItemProperty -Path $key -Name TaskbarSizeMove -Value 0
        }

        if ($UnLock) {
            Set-ItemProperty -Path $key -Name TaskbarSizeMove -Value 1
        }

        switch ($Size) {
            "Small" {
                Set-ItemProperty -Path $key -Name TaskbarSmallIcons -Value 1
            }

            "Large" {
                Set-ItemProperty -Path $key -Name TaskbarSmallIcons -Value 0
            }
        }

        switch ($Combine) {
            "Always" {
                Set-ItemProperty -Path $key -Name TaskbarGlomLevel -Value 0
            }

            "Full" {
                Set-ItemProperty -Path $key -Name TaskbarGlomLevel -Value 1
            }

            "Never" {
                Set-ItemProperty -Path $key -Name TaskbarGlomLevel -Value 2
            }
        }

        if ($MultiMonitorOn) {
            Set-ItemProperty -Path $key -Name MMTaskbarEnabled -Value 1

            switch ($MultiMonitorMode) {
                "All" {
                    Set-ItemProperty -Path $key -Name MMTaskbarMode -Value 0
                }

                "MainAndOpen" {
                    Set-ItemProperty -Path $key -Name MMTaskbarMode -Value 1
                }

                "Open" {
                    Set-ItemProperty -Path $key -Name MMTaskbarMode -Value 2
                }
            }

            switch ($MultiMonitorCombine) {
                "Always" {
                    Set-ItemProperty -Path $key -Name MMTaskbarGlomLevel -Value 0
                }

                "Full" {
                    Set-ItemProperty -Path $key -Name MMTaskbarGlomLevel -Value 1
                }

                "Never" {
                    Set-ItemProperty -Path $key -Name MMTaskbarGlomLevel -Value 2
                }
            }
        }

        if ($MultiMonitorOff) {
            Set-ItemProperty -Path $key -Name MMTaskbarEnabled -Value 0
        }
    }

    if (Test-Path -Path $settingKey) {
        $settings = (Get-ItemProperty -Path $settingKey -Name Settings).Settings

        switch ($Dock) {
            "Top" {
                $settings[12] = 0x01
            }

            "Left" {
                $settings[12] = 0x00
            }

            "Bottom" {
                $settings[12] = 0x03
            }

            "Right" {
                $settings[12] = 0x02
            }
        }

        if ($AutoHide) {
            $settings[8] = $settings[8] -bor 1
        }

        if ($NoAutoHide) {
            $settings[8] = $settings[8] -band 0
            Set-ItemProperty -Path $settingKey -Name Settings -Value $settings
        }

        Set-ItemProperty -Path $settingKey -Name Settings -Value $settings
    }

    if (Test-Path -Path $explorerKey) {
        if ($AlwaysShowIconsOn) {
            Set-ItemProperty -Path $explorerKey -Name 'EnableAutoTray' -Value 0
        }

        if ($alwaysShowIconsOff) {
            Set-ItemProperty -Path $explorerKey -Name 'EnableAutoTray' -Value 1
        }
    }

    Restart-Explorer
}


function Restart-Explorer {

    try{
        Write-host "Restarting the Windows Explorer process..."
        $user = Get-CurrentUser
        try { $explorer = Get-Process -Name explorer -ErrorAction stop -IncludeUserName }
        catch {$global:error.RemoveAt(0)}

        if($explorer -ne $null) {
            $explorer | ? { $_.UserName -eq "$($user.Domain)\$($user.Name)"} | Stop-Process -Force -ErrorAction Stop | Out-Null
        }

        Start-Sleep 1

        if(!(Get-Process -Name explorer -ErrorAction SilentlyContinue)) {
            $global:error.RemoveAt(0)
            start-Process -FilePath explorer
        }
    } catch {$global:error.RemoveAt(0)}
}

function set-ntpserver_urca {
	New-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\DateTime\Servers" -Name "25" -Value "ntp-ts.univ-reims.fr" -PropertyType "string"
	Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\DateTime\Servers" -Name "(Default)" -Value "25"
}

function open_ports {
	# open wmi ports
	Enable-NetFirewallRule -Name "WMI-WINMGMT-In-TCP"
	# open Ps exec port
	netsh advfirewall firewall add rule name="psexec Port 445" dir=in action=allow protocol=TCP localport=445
	# Allow ping IPV4
	netsh advfirewall firewall add rule name="All ICMP V4" protocol=icmpv4 dir=in action=allow
}

function Set-WindowsExplorerOptions {
<#
.SYNOPSIS
Sets options on the Windows Explorer shell
.PARAMETER EnableShowHiddenFilesFoldersDrives
If this flag is set, hidden files will be shown in Windows Explorer
.PARAMETER DisableShowHiddenFilesFoldersDrives
Disables the showing on hidden files in Windows Explorer, see EnableShowHiddenFilesFoldersDrives
.PARAMETER EnableShowProtectedOSFiles
If this flag is set, hidden Operating System files will be shown in Windows Explorer
.PARAMETER DisableShowProtectedOSFiles
Disables the showing of hidden Operating System Files in Windows Explorer, see EnableShowProtectedOSFiles
.PARAMETER EnableShowFileExtensions
Setting this switch will cause Windows Explorer to include the file extension in file names
.PARAMETER DisableShowFileExtensions
Disables the showing of file extension in file names, see EnableShowFileExtensions
.PARAMETER EnableShowFullPathInTitleBar
Setting this switch will cause Windows Explorer to show the full folder path in the Title Bar
.PARAMETER DisableShowFullPathInTitleBar
Disables the showing of the full path in Windows Explorer Title Bar, see EnableShowFullPathInTitleBar
.PARAMETER EnableExpandToOpenFolder
Setting this switch will cause Windows Explorer to expand the navigation pane to the current open folder
.PARAMETER DisableExpandToOpenFolder
Disables the expanding of the navigation page to the current open folder in Windows Explorer, see EnableExpandToOpenFolder
.PARAMETER EnableOpenFileExplorerToQuickAccess
Setting this switch will cause Windows Explorer to open itself to the Computer view, rather than the Quick Access view
.PARAMETER DisableOpenFileExplorerToQuickAccess
Disables the Quick Access location and shows Computer view when opening Windows Explorer, see EnableOpenFileExplorerToQuickAccess
.PARAMETER EnableShowRecentFilesInQuickAccess
Setting this switch will cause Windows Explorer to show recently used files in the Quick Access pane
.PARAMETER DisableShowRecentFilesInQuickAccess
Disables the showing of recently used files in the Quick Access pane, see EnableShowRecentFilesInQuickAccess
.PARAMETER EnableShowFrequentFoldersInQuickAccess
Setting this switch will cause Windows Explorer to show frequently used directories in the Quick Access pane
.PARAMETER DisableShowFrequentFoldersInQuickAccess
Disables the showing of frequently used directories in the Quick Access pane, see EnableShowFrequentFoldersInQuickAccess
.PARAMETER EnableShowRibbon
Setting this switch will cause Windows Explorer to show the Ribbon menu so that it is always expanded
.PARAMETER DisableShowRibbon
Disables the showing of the Ribbon menu in Windows Explorer so that it shows only the tab names, see EnableShowRibbon
.PARAMETER EnableSnapAssist
Enables Windows snap feature (side by side application selection tool). 
.PARAMETER DisableSnapAssist
Disables Windows snap feature (side by side application selection tool).
.LINK
https://boxstarter.org
#>

    [CmdletBinding()]
    param(
        [switch]$EnableShowHiddenFilesFoldersDrives,
        [switch]$DisableShowHiddenFilesFoldersDrives,
        [switch]$EnableShowProtectedOSFiles,
        [switch]$DisableShowProtectedOSFiles,
        [switch]$EnableShowFileExtensions,
        [switch]$DisableShowFileExtensions,
        [switch]$EnableShowFullPathInTitleBar,
        [switch]$DisableShowFullPathInTitleBar,
        [switch]$EnableExpandToOpenFolder,
        [switch]$DisableExpandToOpenFolder,
        [switch]$EnableOpenFileExplorerToQuickAccess,
        [switch]$DisableOpenFileExplorerToQuickAccess,
        [switch]$EnableShowRecentFilesInQuickAccess,
        [switch]$DisableShowRecentFilesInQuickAccess,
        [switch]$EnableShowFrequentFoldersInQuickAccess,
        [switch]$DisableShowFrequentFoldersInQuickAccess,
        [switch]$EnableShowRibbon,
        [switch]$DisableShowRibbon,
        [switch]$EnableSnapAssist,
        [switch]$DisableSnapAssist
    )

    $PSBoundParameters.Keys | % {
        if($_-like "En*"){ $other="Dis" + $_.Substring(2)}
        if($_-like "Dis*"){ $other="En" + $_.Substring(3)}
        if($PSBoundParameters[$_] -and $PSBoundParameters[$other]) {
            throw new-Object -TypeName ArgumentException "You may not set both $_ and $other. You can only set one."
        }
    }

    $key = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer'
    $advancedKey = "$key\Advanced"
    $cabinetStateKey = "$key\CabinetState"
    $ribbonKey = "$key\Ribbon"

    Write-Host "Setting Windows Explorer options..."

    if(Test-Path -Path $key) {
        if($EnableShowRecentFilesInQuickAccess) {Set-ItemProperty $key ShowRecent 1}
        if($DisableShowRecentFilesInQuickAccess) {Set-ItemProperty $key ShowRecent 0}

        if($EnableShowFrequentFoldersInQuickAccess) {Set-ItemProperty $key ShowFrequent 1}
        if($DisableShowFrequentFoldersInQuickAccess) {Set-ItemProperty $key ShowFrequent 0}
    }

    if(Test-Path -Path $advancedKey) {
        if($EnableShowHiddenFilesFoldersDrives) {Set-ItemProperty $advancedKey Hidden 1}
        if($DisableShowHiddenFilesFoldersDrives) {Set-ItemProperty $advancedKey Hidden 0}

        if($EnableShowFileExtensions) {Set-ItemProperty $advancedKey HideFileExt 0}
        if($DisableShowFileExtensions) {Set-ItemProperty $advancedKey HideFileExt 1}

        if($EnableShowProtectedOSFiles) {Set-ItemProperty $advancedKey ShowSuperHidden 1}
        if($DisableShowProtectedOSFiles) {Set-ItemProperty $advancedKey ShowSuperHidden 0}

        if($EnableExpandToOpenFolder) {Set-ItemProperty $advancedKey NavPaneExpandToCurrentFolder 1}
        if($DisableExpandToOpenFolder) {Set-ItemProperty $advancedKey NavPaneExpandToCurrentFolder 0}

        if($EnableOpenFileExplorerToQuickAccess) {Set-ItemProperty $advancedKey LaunchTo 2}
        if($DisableOpenFileExplorerToQuickAccess) {Set-ItemProperty $advancedKey LaunchTo 1}

        if($EnableSnapAssist) {Set-ItemProperty $advancedKey SnapAssist 1}
        if($DisableSnapAssist) {Set-ItemProperty $advancedKey SnapAssist 0}
    }

    if(Test-Path -Path $cabinetStateKey) {
        if($EnableShowFullPathInTitleBar) {Set-ItemProperty $cabinetStateKey FullPath  1}
        if($DisableShowFullPathInTitleBar) {Set-ItemProperty $cabinetStateKey FullPath  0}
    }

    if(Test-Path -Path $ribbonKey) {
        if($EnableShowRibbon) {Set-ItemProperty $ribbonKey MinimizedStateTabletModeOff 0}
        if($DisableShowRibbon) {Set-ItemProperty $ribbonKey MinimizedStateTabletModeOff 1}
    }

    Restart-Explorer
}

function AllowInsecureGuestAuth{
	Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\LanmanWorkstation\Parameters" -Name "AllowInsecureGuestAuth" -Value 1
}
function power_config{
	powercfg.exe -x -monitor-timeout-ac 30 # plugged in device
	#powercfg.exe -x -monitor-timeout-dc 30 # Battery device
	powercfg.exe -x -disk-timeout-ac 0 # plugged in device
	#powercfg.exe -x -disk-timeout-dc 0 # Battery device
	powercfg.exe -x -standby-timeout-ac 0 # plugged in device
	#powercfg.exe -x -standby-timeout-dc 0 # Battery device
	powercfg.exe -x -hibernate-timeout-ac 0 # plugged in device
	#powercfg.exe -x -hibernate-timeout-dc 0 # Battery device
	powercfg /SETACVALUEINDEX SCHEME_CURRENT SUB_NONE CONSOLELOCK 0 #Disable Disable Require a password on wakeup on plugged in device
	#powercfg /SETDCVALUEINDEX SCHEME_CURRENT SUB_NONE CONSOLELOCK 0 #Disable Disable Require a password on wakeup on battery device
	powercfg.exe -h off
}

function Set-Wsus{
if(!(Test-Path HKLM:\Software\Policies\Microsoft\Windows\WindowsUpdate)){
New-Item -Path HKLM:\Software\Policies\Microsoft\Windows -Name WindowsUpdate
}
New-Item -Path HKLM:\Software\Policies\Microsoft\Windows\WindowsUpdate -Name AU
New-ItemProperty -Path HKLM:\Software\Policies\Microsoft\Windows\WindowsUpdate -Name AcceptTrustedPublisherCerts -Value 1 -Force
New-ItemProperty -Path HKLM:\Software\Policies\Microsoft\Windows\WindowsUpdate -Name DisableWindowsUpdateAccess -Value 1 -Force
New-ItemProperty -Path HKLM:\Software\Policies\Microsoft\Windows\WindowsUpdate -Name ElevateNonAdmins -Value 0 -Force
New-ItemProperty -Path HKLM:\Software\Policies\Microsoft\Windows\WindowsUpdate -Name TargetGroup -Value "workgroup" -Force
New-ItemProperty -Path HKLM:\Software\Policies\Microsoft\Windows\WindowsUpdate -Name TargetGroupEnabled -Value 0 -Force
New-ItemProperty -Path HKLM:\Software\Policies\Microsoft\Windows\WindowsUpdate -Name WUServer -Value "http:\\10.1.1.1" -Force
New-ItemProperty -Path HKLM:\Software\Policies\Microsoft\Windows\WindowsUpdate -Name WUStatusServer -Value "http:\\10.1.1.1" -Force
#New-ItemProperty -Path HKCU:\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer -Name NoWindowsUpdate -Value 1 -Force
#New-ItemProperty -Path "HKLM:\SYSTEM\Internet Communication Management\Internet Communication" -Name DisableWindowsUpdateAccess -Value 1 -Force
#New-ItemProperty -Path HKCU:\Software\Microsoft\Windows\CurrentVersion\Policies\WindowsUpdate -Name DisableWindowsUpdateAccess -Value 1 -Force
New-ItemProperty -Path HKLM:\Software\Policies\Microsoft\Windows\WindowsUpdate\AU -Name AUOptions -Value 5 -Force
New-ItemProperty -Path HKLM:\Software\Policies\Microsoft\Windows\WindowsUpdate\AU -Name AutoInstallMinorUpdates -Value 0 -Force
New-ItemProperty -Path HKLM:\Software\Policies\Microsoft\Windows\WindowsUpdate\AU -Name DetectionFrequencyEnabled -Value 0 -Force
New-ItemProperty -Path HKLM:\Software\Policies\Microsoft\Windows\WindowsUpdate\AU -Name NoAutoRebootWithLoggedOnUsers -Value 1 -Force
New-ItemProperty -Path HKLM:\Software\Policies\Microsoft\Windows\WindowsUpdate\AU -Name NoAutoUpdate -Value 1 -Force
New-ItemProperty -Path HKLM:\Software\Policies\Microsoft\Windows\WindowsUpdate\AU -Name RebootRelaunchTimeout -Value 1440 -Force
New-ItemProperty -Path HKLM:\Software\Policies\Microsoft\Windows\WindowsUpdate\AU -Name RebootWarningTimeout -Value 30 -Force
New-ItemProperty -Path HKLM:\Software\Policies\Microsoft\Windows\WindowsUpdate\AU -Name RescheduleWaitTimeEnabled -Value 0 -Force
New-ItemProperty -Path HKLM:\Software\Policies\Microsoft\Windows\WindowsUpdate\AU -Name UseWUServer -Value 1 -Force
}

#Dans les tâches planifiées, il y a des tâches qui ne servent à rien : HP Support Assistant, par exemple, vu que nous le lancerons manuellement, ainsi que la tâche de défragmentation, mises à jour Google, ou encore l’OfficeTelemetryAgent (mouchard d’Office). Donc effacer/désactiver celles qui ne servent à rien 
function disable-scheduledtasks{
$temp =@(
'Get-ScheduledTask -TaskName "*google*" | Disable-ScheduledTask',
'Get-ScheduledTask -TaskName "*MicrosoftEdgeupdate*" | Disable-ScheduledTask',
'Get-ScheduledTask -TaskName "*Nvidia*" | Disable-ScheduledTask',
'Get-ScheduledTask -TaskName "*Ccleaner*" | Disable-ScheduledTask',
'Get-ScheduledTask -TaskName "*OfficeTelemetryAgent*" | Disable-ScheduledTask',
'Get-ScheduledTask -TaskName consolidator | Disable-ScheduledTask',
'Get-ScheduledTask -TaskName UsbCeip | Disable-ScheduledTask',
'Get-ScheduledTask -TaskName "Microsoft Compatibility Appraiser" | Disable-ScheduledTask',
'Get-ScheduledTask -TaskName "ProgramDataUpdater" | Disable-ScheduledTask',
'Get-ScheduledTask -TaskName Microsoft-Windows-DiskDiagnosticDataCollector | Disable-ScheduledTask',
'Get-ScheduledTask -TaskName Microsoft-Windows-DiskDiagnosticResolver | Disable-ScheduledTask',
'Get-ScheduledTask -TaskName "Scheduled Start"| Disable-ScheduledTask'
)

$temp | foreach {
try{
Invoke-Expression $_ |Out-Null
if($?){
write-host $_ "--------------Nok" -ForegroundColor Red

}
else{
write-host $_ "---------------------OK" -ForegroundColor Green
}

}
}
catch{}
}
#A titre d’exemple de simplification de la UI, aller dans les paramètres avancés,sélectionner « Ajuster pour obtenir les meilleures performances pour lesprogrammes » et cochez dans la liste dessous « Afficher des miniatures au lieu d’icônes », ainsi que « Lisser les polices d’écran ».
function performance_options_visual_effects{
Set-ItemProperty -Path HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects -Name VisualFXSetting -Value 3
Set-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name UserPreferencesMask -Value "90 12 03 80 10 00 00 00"
}
function set-desktop-icon-small{
Set-ItemProperty -path HKCU:\Software\Microsoft\Windows\Shell\Bags\1\Desktop -name IconSize -value 36
Stop-Process -name explorer  # explorer.exe restarts automatically after stopping
}
