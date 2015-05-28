[ -f ~/.Xresources ] && xrdb -load ~/.Xresources
[ -f  ~/.xsession-errors ] && [ `stat -c %s ~/.xsession-errors` -gt 2097152 ] && rm -f ~/.xseesion-errors

exec dbus-launch --exit-with-session awesome
