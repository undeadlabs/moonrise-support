#-------------------------------------------------------------------------------
# gather.ps1
#
# A script to gather information about your computer for game support purposes.
#
# UndeadLabs (c) 2015
#-------------------------------------------------------------------------------


<#
  To download and run this script from the Internet:
    powershell -windowstyle hidden -NoProfile -Command "iex ((new-object net.webclient).DownloadString('https://raw.githubusercontent.com/undeadlabs/moonrise-support/master/Windows/gather.ps1'))"

  To run this script locally:
    powershell -windowstyle hidden -NoProfile -File gather.ps1
#>


#-------------------------------------------------------------------------------
# Initialization
#-------------------------------------------------------------------------------
$wshell = New-Object -ComObject Wscript.Shell

$moonriseBaseDir = "${Env:ProgramFiles(x86)}\Steam\steamapps\common\Moonrise"
$moonriseDataDir = "$moonriseBaseDir\Moonrise_Data"

$tempDir = $env:temp + "\MoonriseHelp"

$outputDir = [Environment]::GetFolderPath("Desktop") + "\MoonriseHelp"
$outputZip = "$outputDir\MoonriseReport.zip"

$strDialogTitle = "Moonrise Game Support"

$strOkayToProceed = @"
This program will collect information to send to the Moonrise Game Support Team to diagnose your computer and network problems.

Would you like to proceed?
"@

$strAllDone = @"
We've created a file that contains information about your computer in the MoonriseHelp folder on your Desktop:

  $outputZip

Please upload that file to https://help.moonrisegame.com and we'll do our best to help solve the problem you're experiencing.

Thanks!
"@

$strErrorNotFound = @"
We're sorry, but we can't find Moonrise. It's supposed to be installed here:

 $moonriseBaseDir

but we don't see it. Are you sure it is installed?
"@

#-------------------------------------------------------------------------------
# Let player know what's going to happen
#-------------------------------------------------------------------------------
$result = $wshell.Popup($strOkayToProceed, 0, $strDialogTitle, 1)
if ($result -ne 1) {
  exit
}


#-------------------------------------------------------------------------------
# Ensure Moonrise is installed
#-------------------------------------------------------------------------------
if (! (Test-Path -Path $moonriseDataDir)) {
  $result = $wshell.Popup($strErrorNotFound, 0, $strDialogTitle, 0)
  exit
}


#-------------------------------------------------------------------------------
# Create temporary directory
#-------------------------------------------------------------------------------
if (Test-Path -Path $tempDir) {
  Remove-Item $tempDir -Force -Recurse | Out-Null
}
mkdir $tempDir | Out-Null
Set-Location $tempDir


#-------------------------------------------------------------------------------
# Run diagnostic tools
#-------------------------------------------------------------------------------
$processes = @()
Try {
  $web = New-Object Net.WebClient
  $web.DownloadString('https://live-versioner.moonrisegame.net:26202/') | Out-File "Connect.txt"
}
Catch {
  Write-Warning "Error connecting to server: $($error[0])"
}

if (Test-Path("$moonriseDataDir\output_log.txt")) {
  Copy-Item "$moonriseDataDir\output_log.txt" "output_log.txt"
}
if (Test-Path("$moonriseDataDir\Data\windows\VERSION")) {
  Copy-Item "$moonriseDataDir\Data\windows\VERSION" "Version.txt"
}

$processes += Start-Process "dxdiag.exe" "/whql:off /tMoonriseDxDiag.txt" -PassThru -NoNewWindow
$processes += Start-Process "Msinfo32.exe" "/report MoonriseSystemInfo.txt" -PassThru -NoNewWindow
$processes += Start-Process "netsh.exe" "winhttp show proxy" -RedirectStandardOutput MoonriseProxy.txt -PassThru -NoNewWindow
$processes += Start-Process "netsh.exe" "advfirewall firewall show rule name=all" -RedirectStandardOutput MoonriseFirewall.txt -PassThru -NoNewWindow
$processes | Wait-Process


#-------------------------------------------------------------------------------
# Zip it all into one file
#-------------------------------------------------------------------------------
function Add-Zip {
    param([string]$zipFile)

    # While CopyHere documentation *says* that it accepts silent and noconfirm
    # options, it doesn't work on *my* system, so instead let's delete the zip
    if (Test-Path($zipFile)) {
      Remove-Item $zipFile -Force -Recurse
    }

    set-content $zipFile ("PK" + [char]5 + [char]6 + ("$([char]0)" * 18))
    (dir $zipFile).IsReadOnly = $false

    $shellApplication = new-object -com shell.application
    $zipPackage = $shellApplication.NameSpace($zipFile)

    foreach($file in $input) {
      $zipPackage.CopyHere($file.FullName)

      # Using this method, sometimes files can be 'skipped'
      # This 'while' loop checks each file is added before moving to the next.
      # Thanks PowerShell, for your totally non-obvious behavior.
      while ($zipPackage.Items().Item($file.name) -eq $null){
        Start-Sleep -m 50
      }
    }
}
New-Item -ItemType Directory -Force -Path $outputDir | Out-Null
dir $tempDir | Add-Zip $outputZip


#-------------------------------------------------------------------------------
# Let player know what happened
#-------------------------------------------------------------------------------
$wshell.Popup($strAllDone, 0, $strDialogTitle, 0)


#-------------------------------------------------------------------------------
# Show player the file we created
#-------------------------------------------------------------------------------
Invoke-Item $outputDir


#-------------------------------------------------------------------------------
# Note to you programmers: friends don't let friends write code in Powershell.
#-------------------------------------------------------------------------------
