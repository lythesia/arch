export GTK_IM_MODULE=fcitx
export QT_IM_MODULE=fcitx
export XMODIFIERS=@im=fictx

xset +fp /usr/share/fonts/microsoft/
xset +fp /usr/share/fonts/ttf-ms-fonts-zh_cn/

exec gnome-session
#exec gnome-session-cinnamon
#exec awesome
