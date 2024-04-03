function rust-init -d '`cargo init` on steroids'

    set -l options h/help w/workspace n/name= d/description= c/channel=
    if not argparse $options -- $argv
        printf '\n'
        eval (status function) --help
        return 2
    end

    set -l reset (set_color normal)
    set -l bold (set_color --bold)
    set -l italics (set_color --italics)
    set -l red (set_color red)
    set -l green (set_color green)
    set -l yellow (set_color yellow)
    set -l blue (set_color blue)
    set -l cyan (set_color cyan)
    set -l magenta (set_color magenta)

    if set --query _flag_help
        set -l option_color (set_color $fish_color_option)
        set -l reset (set_color normal)
        set -l bold (set_color --bold)
        set -l section_header_color (set_color yellow)

        printf '%sdescription%s\n' $bold $reset
        printf '\n'
        printf '%sUSAGE:%s %s%s%s [OPTIONS]\n' $section_header_color $reset (set_color $fish_color_command) (status function) $reset
        printf '\n'
        printf '%sOPTIONS:%s\n' $section_header_color $reset
        printf '%s\t%s-h%s, %s--help%s Show this help message and return\n'
        # printf '%sEXAMPLES:%s\n' $section_header_color $reset
        # printf '\t%s%s\n' (printf (echo "$(status function)" | fish_indent --ansi)) $reset
        return 0
    end >&2

    set -l channel stable
    if set --query _flag_channel
        set channel $_flag_channel
    end

    if not contains -- $channel stable beta nightly
        echo err
        return 2
    end

    # TODO: use gum for a dialog
    # TODO: use taplo to insert some toml values

    # .cargo/config.toml
    # rust-toolchain.toml
    # rustfmt.toml
    # bacon.toml
    # .envrc
    # flake.nix
    # - https://github.com/oxalica/rust-overlay
    # - https://drakerossman.com/blog/rust-development-on-nixos-bootstrapping-rust-nightly-via-flake
    # .pre-commit-config.yaml

    begin # rust-toolchain.toml
        echo "[toolchain]
channel = "$channel"
        " >rust-toolchain.toml
    end

    if command --query nix
        if test -f flake.nix -o -f flake.lock
            echo err
        else
            # TODO: use $channel
            echo "

            " >flake.nix
        end


        if command --query direnv
            if not test -f .envrc; or test -f .envrc; and not string match --quiet --regex '^use flake' <.envrc
                echo 'use flake' >>.envrc
            end
        end

        command direnv allow
    end


    return 0
end
