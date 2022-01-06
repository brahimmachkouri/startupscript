Try
{
$chocoapps = @(
    	"7zip.install",
        "dotnetfx",
    	"ccleaner",
    	"dellcommandupdate", 
    	"filezilla", 
    	"firefox", 
    	"foxitreader", 
    	"pdfcreator", 
    	"sublimetext4",
    	"totalcommander"
)
cinst -s chocosia -y Powershell | Out-Null 
#dependency for dell command update
cinst -s chocolatey -y dotnet4.6.1 | Out-Null 
$counter = 0
foreach($item in $chocoapps){
    $counter++
    Write-Progress -Activity 'Install Apps' -CurrentOperation $item -PercentComplete (($counter / $chocoapps.count) * 100)
    Start-Sleep -Milliseconds 200
    cinst -s chocosia -y --ignore-checksums $item | Out-Null
    if($LASTEXITCODE -eq 0){write-host $item"--------Ok" -ForegroundColor Green}
    else{write-host $item"--failed installing with internal server----------Nok" -ForegroundColor Red
    write-host "Trying to install with Chocolatey sever" -ForeGroundColor Yellow
    cinst -s chocolatey -y --ignore-checksums $item | Out-Null
    if($LASTEXITCODE -eq 0){write-host $item"--------Ok" -ForegroundColor Green}
    else{write-host $item"-failed installing even with chocolatey server-----------Nok" -ForegroundColor Red}
    }
}
write-host "Stage: chocolatey_apps completed" -ForegroundColor Green
Set-ItemProperty -Path 'HKCU:\osinstall_local' -Name stage -value 'windowsupdate_initiate'
Set-Runonce
Stop-Transcript
Restart-Computer
}
catch
{
write-host "Stage: chocolatey_apps Failed" -ForegroundColor Red
Set-ItemProperty -Path 'HKCU:\osinstall_local' -Name stage -value chocolatey_apps
Set-Runonce
Stop-Transcript
Pause
}
