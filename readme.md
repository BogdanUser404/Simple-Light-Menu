### Simple-Light-Menu

Simple-Light-Menu is a simple menu written in Vala using GTK4. It's a component of the future DE.
The menu doesn't hang in the background and doesn't consume resources unnecessarily.
The menu's life cyclel:
`Window created -> Allows the user to select an application to launch -> Dies`

The window's CSS style is located in $XDG_CONFIG_HOME/SLDE-Menu/style.css
Ready-made themes are available in themes
Screenshots are available in screenshots

## How to install?
Build dependencies:
```
Vala: Version 0.56+ recommended
GTK4: Version 4.20+ recommended
Glib: Version 4.20+ recommended
Python 3+: Version 3.12+ recommended
```

Runtime dependencies:
```
GTK4: Version 4.20+ recommended
Glib: Version 4.20+ recommended
```

To install, run the following command from the repository root:
```
python install.py
```
