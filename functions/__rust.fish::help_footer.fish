function __rust.fish::help_footer -d "Print a help footer. This way all help messages are consistent in rust.fish"
    set -l github_url https://github.com/kpbaks/rust.fish
    set -l star_symbol ⭐
    set -l reset (set_color normal)
    set -l blue (set_color blue)
    set -l red (set_color red)

    printf "Part of %srust.fish%s. A plugin for the %s><>%s shell.\n" $red $reset $blue $reset
    printf "See %s%s%s for more information, and if you like it, please give it a %s\n" (set_color --underline cyan) $github_url $reset $star_symbol
end
