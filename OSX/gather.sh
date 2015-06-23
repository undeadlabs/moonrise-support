#!/bin/bash
#-------------------------------------------------------------------------------
# gather.sh
#
# A script to gather information about your computer for game support purposes.
#
# UndeadLabs (c) 2015
#-------------------------------------------------------------------------------

<< HOWTO
  To download and run this script from the Internet:
    curl https://raw.githubusercontent.com/undeadlabs/moonrise-support/master/OSX/gather.sh | bash

  To run this script locally:
    ./gather.ps1
HOWTO


# Close stdout, stderr
exec 1<&- 2<&-


#-------------------------------------------------------------------------------
# Initialization
#-------------------------------------------------------------------------------
heredoc() { IFS='\n' read -r -d '' ${1} || true; }

moonriseBaseDir="$HOME/Library/Application Support/Steam/steamapps/common/Moonrise/Moonrise.app/Contents"
moonriseDataDir="$moonriseBaseDir/Data"

outputDir="$HOME/Desktop/MoonriseHelp"
outputArchive="$outputDir/MoonriseReport.tar.gz"

strDialogTitle="Moonrise Game Support"

listOk='{"OK"}'
listOkCancel='{"OK", "Cancel"}'

heredoc strOkayToProceed << EOF
This program will collect information to send to the Moonrise Game Support Team to diagnose your computer and network problems.

Would you like to proceed?
EOF

heredoc strAllDone << EOF
We created a file that contains information about your computer in the MoonriseHelp folder on your Desktop:

  $(basename "$(dirname "$outputArchive")")/$(basename "$outputArchive")

Please upload that file to https://help.moonrisegame.com and we will do our best to help solve the problem you are experiencing.

Thanks!
EOF

heredoc strErrorNotFound << EOF
We are sorry, but we cannot find Moonrise. It is supposed to be installed here:

 $moonriseBaseDir

but is is not there. Are you sure it is installed?
EOF

#-------------------------------------------------------------------------------
# Dialogs
#-------------------------------------------------------------------------------
popup () {
TEXT="$1"
BUTTONS="$2"
heredoc SCRIPT << EOF
try
  tell application (path to frontmost application as text)
    set theAnswer to button returned of (display dialog "$TEXT" buttons $BUTTONS default button 1 with title "$strDialogTitle")
  end
end
EOF
echo $SCRIPT
  result="$(osascript -e "$SCRIPT")"
  [[ "$result" != "OK" ]] && return 1
  return 0
}


#-------------------------------------------------------------------------------
# Let player know what's going to happen
#-------------------------------------------------------------------------------
if ! popup "$strOkayToProceed" "$listOkCancel" ; then
  exit
fi


#-------------------------------------------------------------------------------
# Ensure Moonrise is installed
#-------------------------------------------------------------------------------
if [[ ! -d "$moonriseDataDir" ]]; then
  popup "$strErrorNotFound" "$listOk"
  exit
fi


#-------------------------------------------------------------------------------
# Create temporary directory
#-------------------------------------------------------------------------------
tempDir="$(mktemp -d -t MoonriseHelp)"
cd "$tempDir"


#-------------------------------------------------------------------------------
# Run diagnostic tools
#-------------------------------------------------------------------------------
curl -sS 'https://live-versioner.moonrisegame.net:26202/' > "Connect.txt" 2>&1 &
cp "$HOME/Library/Logs/Unity/Player.log" "output_log.txt" &
cp "$moonriseDataDir/osx/VERSION" "Version.txt" &
system_profiler -detailLevel mini > "SystemProfile.txt" 2>&1 &

wait

#-------------------------------------------------------------------------------
# Zip it all into one file
#-------------------------------------------------------------------------------
mkdir -p "$outputDir"
rm -f "$outputArchive"
tar czf "$outputArchive" -C "$tempDir" .


#-------------------------------------------------------------------------------
# Let player know what happened
#-------------------------------------------------------------------------------
popup "$strAllDone" "$listOk"


#-------------------------------------------------------------------------------
# Show player the file we created
#-------------------------------------------------------------------------------
open "$outputDir"
