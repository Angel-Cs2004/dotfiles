#!/usr/bin/env python3
"""Aplica el esquema Dinamico.colors a ~/.config/kdeglobals (Dolphin, Ark, Okular…).

Solo escribe las claves de color con kwriteconfig6 (el resto de kdeglobals queda
igual) y avisa por D-Bus a las apps KDE abiertas para que recarguen los colores.
"""
import configparser
import os
import shutil
import subprocess

SCHEME = os.path.expanduser("~/.local/share/color-schemes/Dinamico.colors")


def main():
    if not os.path.isfile(SCHEME) or not shutil.which("kwriteconfig6"):
        return
    cp = configparser.ConfigParser(interpolation=None, strict=False)
    cp.optionxform = str                      # KDE distingue mayúsculas
    cp.read(SCHEME)
    for group in cp.sections():
        for key, value in cp[group].items():
            if group == "General" and key == "Name":
                continue
            subprocess.run(["kwriteconfig6", "--file", "kdeglobals", "--group", group,
                            "--key", key, value], check=False)
    # Avisar a las apps KDE abiertas (KGlobalSettings: cambio de paleta)
    if shutil.which("dbus-send"):
        subprocess.run(["dbus-send", "--session", "--type=signal", "/KGlobalSettings",
                        "org.kde.KGlobalSettings.notifyChange", "int32:0", "int32:0"],
                       check=False, stderr=subprocess.DEVNULL)


if __name__ == "__main__":
    main()
