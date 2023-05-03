#!/bin/sh
valac --pkg libnotify --pkg gtk+-3.0 --pkg webkit2gtk-4.0 site2app.vala -o bin/site2app
