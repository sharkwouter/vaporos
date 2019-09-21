![](https://github.com/sharkwouter/vaporos/raw/master/logo.png)

SteamOS is an operating system which can turn a computer into a game console. VaporOS improves on this by not only focussing on games, but also offer multimedia and emulation support along with some other extras to make the system more enjoyable to use.

![](https://github.com/sharkwouter/vaporos/raw/master/screenshot1.jpg)
![](https://github.com/sharkwouter/vaporos/raw/master/screenshot2.jpg)

## Features

VaporOS contains all the features found in SteamOS plus the following additions:

- **Retroarch**, an emulator  frontend with support for PSP, PS1, N64, SNES, NES, GBA and more
- **Kodi**, an entertainment center which can play videos and music
- **VaporOS-FTPServer**, a file server which allows you to easily transfer files
- **VaporOS Flatpak Manager**, a front-end for flatpak. It allows for easy software installation
- **Improved desktop experience** with a text editor, archive manager, media player (**VLC**) and **Gnome Tweak Tool** added
- **Bash completion** for command line users
- **TRIM support** for SSDs

## Download

Download the latest Vaporos release [here](https://github.com/sharkwouter/vaporos/releases).

## System Requirements

VaporOS has the following hardware requirements:

- Intel or AMD 64-bit capable processor
- 4GB or more RAM
- 30GB or larger hard drive or SSD

The following graphics cards are supported:
- Nvidia GTX 600 series or newer
- AMD HD 7000 series or newer
- Intel HD 4000 series or newer

## Installation

VaporOS can be installed from a DVD or from a USB stick. To be able to do so, the latest VaporOS ISO (vaporos-XXX.iso) has to be downloaded like mentioned above. Burning the ISO to a DVD can be done with any DVD burning program like Imgburn. Instructions on how to use a USB stick will be listed below. A USB stick of at least 2 GB will be required for this.

After having made the installation media (DVD or USB stick), installing from it is pretty straight forward. Put the installation media in the computer and press F8, F9, F11 or F12 during boot to open the boot menu and pick it. Which of these buttons works depends on the hardware and might take some trial and error. After that pick the option "Automated installation" (**this will erase your disk!**) and wait for the installation to finish. The system will reboot multiple times during installation. Once finished select the reboot option and press enter. You are now ready to use VaporOS.

### Installing from USB

Download the tool [Balena Etcher](https://www.balena.io/etcher/) and use it to copy the VaporOS ISO to your USB stick. **This erases all data on the USB stick!!**

## Using VaporOS

After installation there are a couple of steps to take to allow the use of VaporOS' features. These are listed here.

### Adding the VaporOS Applications to Steam

After logging in the Retroarch, Kodi, VaporOS-FTPServer and VaporOS Flatpak Manager have to be added to Steam before then can be used. To do this go to setting and under System pick "Add Library Shortcut". Pick the application you'd like to add. Repeat until all of them are in your Steam library.

### Transfering Files from Another Computer

To do this simply start the VaporOS-FTPServer program from Steam and enter the address shown in the file browser or and FTP client. This will allow you to transfer files to and from your Steam machine.

### Installing Applications with VaporOS Flatpak Manager

Installing applications with VaporOS Flatpak Manager is quite easy, just pick the software you'd like to install and press A. Installation can take a while. Once the installation screen disappears you can return to Steam.

Within Steam go to "Settings" -> "Add Library Shortcut" and pick the installed application from the list. It can now be launched from your Steam library.

## Known Issues

- Retroarch and Kodi don't work with every type of controller, the Steam controller does work
- On BIOS systems the installer will ask where to install the bootloader, filling in /dev/sda should work on most systems. This is a SteamOS bug.
- Exiting VaporOS-FTPServer doesn't work with every type of controller at the moment. Binding Esc to the controller or pressing Esc on the keyboard quits it
- Applications installed with Flatpak don't have sound

## Support

If you need any help or would like to help out with this project, feel free to [join us on Discord](https://discord.gg/qynSaKY).

## Development

Instructions on how to build VaporOS yourself can be found [here](https://github.com/sharkwouter/vaporos/wiki/Build-Instructions). You can also find more information on how this works [here](https://github.com/sharkwouter/vaporos/wiki/Developer-Information).

## Special Thanks

- ProfessorKaos64 for packaging Retroarch.
- The Deb Multimedia team for packaging ffmpeg and Kodi.
- Nate Wardawg for the name.
- Jorgën Såagrid for allowing the continued use of the name VaporOS.
- Valve for creating SteamOS.
