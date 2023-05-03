# Site2App
Site2App is a webkit wrapper for sites that lets you create a desktop file for each sites.

Startup parameters:

  - --session=<session_name>
    - optional, set a session name, application with same session share the data folder (default value: default)
  - --app=<application_name>
    - required, the application name to use for window and for notifications
  - --appurl=<application_url>
    - required, the url of site that must be showed
  - --tray
    - optional, show an icon in system tray (default: false)
  - --icon=<icon_path>
    - optional, use the specified icon, if not specified the program draw a custom icon
  - --level=none|error|info|debug]
    - optional, set logger error level (default value: error)
  - --private
    - optional, create a private instance, no datas are stored (default: false)
  - --save
    - optional, create desktop file for menu (default: false, if private is set to true this flag is ignored)
  - --help
    - print this message and exit


The script test.sh contains some usage examples.


---

## Installation

### Using script

Launch the script *install.sh* if you want to install globally with sudo.

### Manual installation

 - Copy the file in bin (or the file that you compile with build.sh script) in ${HOME}/.local/bin/ or /usr/local/bin/ and make sure you have that folder in your $PATH env variable.
 - Check also that the bin is executable.

### How to build

From source use the *build.sh* script.

You need vala with libnotify, gtk+ 3.0 and webkit2gtk-4.0.

---

## Release

**Latest: 20230503.1800**

### History

#### 20230503.1800
 - First release for this vala version
