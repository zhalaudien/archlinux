oh-my-posh init fish --config $HOME/.poshthemes/montys.omp.json | source
if status is-interactive
    # Commands to run in interactive sessions can go here
    fastfetch
end

# NPM Global Binaries
if test -d $HOME/.npm-global/bin
    fish_add_path $HOME/.npm-global/bin
end

# Android SDK & Flutter
set -gx ANDROID_HOME $HOME/Android/Sdk
set -gx PATH $HOME/development/flutter/bin $PATH
set -gx PATH $ANDROID_HOME/cmdline-tools/latest/bin $ANDROID_HOME/platform-tools $ANDROID_HOME/emulator $PATH
