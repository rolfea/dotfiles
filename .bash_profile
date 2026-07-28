# Bash reads this *instead of* ~/.profile for login shells, and macOS
# terminals (Alacritty included) start login shells — so without this file a
# Mac would silently get none of the config in .profile/.bashrc.
#
# Keep it a pure redirect. Everything lives in .profile, which sources .bashrc.
[ -r "$HOME/.profile" ] && . "$HOME/.profile"
