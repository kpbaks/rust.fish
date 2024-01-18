function cargo-update-installed-binaries -d "Update all installed cargo binaries in $CARGO_HOME/bin"
    # TODO: what about https://github.com/nabijaczleweli/cargo-update
    set -l options h/help v/verbose d/dry-run l/list c/check
    if not argparse $options -- $argv
        eval (status function) --help
        return 2
    end

    set -l reset (set_color normal)
    set -l bold (set_color --bold)
    set -l red (set_color red)
    set -l green (set_color green)
    set -l yellow (set_color yellow)

    if set --query _flag_help
        set -l option_color (set_color $fish_color_option)
        printf "%sUpdate all installed cargo binaries in %s%s%s\n" $bold $blue $CARGO_HOME/bin $reset >&2
        printf "\n" >&2
        printf "%sUSAGE%s:\n" $yellow $reset >&2
        printf "\t%s%s%s [OPTIONS]\n" (set_color $fish_color_command) (status function) $reset >&2
        printf "\n" >&2
        printf "%sOPTIONS%s:\n" $yellow $reset >&2
        printf "\t%s-h%s, %s--help%s\t\tprint this help message and exit\n" $option_color $reset $option_color $reset >&2
        printf "\t%s-v%s, %s--verbose%s\t\tprint the command to be run\n" $option_color $reset $option_color $reset >&2
        printf "\t%s-d%s, %s--dry-run%s\t\tdon't run the command (implies --verbose)\n" $option_color $reset $option_color $reset >&2
        printf "\t%s-l%s, %s--list%s\t\tlist installed cargo binaries\n" $option_color $reset $option_color $reset >&2
        printf "\n" >&2
        __rust.fish::help_footer >&2
        return 0
    end

    set --query _flag_dry_run; and set -l _flag_verbose

    set -l crates2_path $CARGO_HOME/.crates2.json
    if not test -f $crates2_path
        printf "%serror%s: %s not found\n" $red $reset $crates2_path >&2
        return 1
    end
    set -l cargo_binaries (command jq '.installs | keys[] | split(" ")[0]' < $crates2_path)
    if test (count $cargo_binaries) -eq 0
        printf "no cargo binaries found in %s\n" $crates2_path >&2
        return 0
    end

    if set --query _flag_list
        printf "%s\n" $cargo_binaries
        return 0
    end

    set -l command "command cargo install --locked --bins --force $cargo_binaries"
    if set --query _flag_verbose
    echo $command | fish_indent --ansi
    end

    if not set --query _flag_dry_run
        eval $command
    end
end
