# Moonrise-support

This website contains programs that are designed to gather system information
from your computer in order to provide better technical support. The programs
capture game and operating system diagnostics that you can upload to the
[Moonrise Customer Support site](https://help.moonrisegame.com).

The diagnostic test should take no more than a minute, and will create an
archive file (.zip for Windows, tar.gz for Macintosh) that you can upload.


### Windows users

For Windows 8/10 users, open the Windows Start Menu and paste the following
command into the search bar. For Windows XP/Vista users, open the Windows Start
Menu, select "Run", and paste the following command into the run dialog:

> powershell -windowstyle hidden -NoProfile -Command "iex ((new-object net.webclient).DownloadString('https://raw.githubusercontent.com/undeadlabs/moonrise-support/master/Windows/gather.ps1'))"


### Mac (OSX) users

Download the [Moonrise Support Application](https://github.com/undeadlabs/moonrise-support/releases/download/OSX/MoonriseSupport.zip) and save it to your computer, then launch the application from the Downloads folder on the right of the OSX Application Dock.

## More information

If you have difficulty running the support application, please contact our
[Customer Support Team](https://help.moonrisegame.com) and we will do our best
to help!
