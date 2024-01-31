function cargo-update-dependencies -d "Update all dependencies in Cargo.toml"
    set -l options h/help c/check
    if not argparse $options -- $argv
        eval (status function) --help
        return 2
    end

    set -l reset (set_color normal)
    set -l bold (set_color --bold)
    set -l italics (set_color --italics)
    set -l red (set_color red)
    set -l green (set_color green)
    set -l yellow (set_color yellow)

    if set --query _flag_help
        set -l option_color (set_color $fish_color_option)
        printf "%sUpdate all dependencies in Cargo.toml\n" $bold $reset >&2
        printf "\n" >&2
        printf "%sUSAGE%s:\n" $yellow $reset >&2
        printf "\t%s%s%s [OPTIONS]\n" (set_color $fish_color_command) (status function) $reset >&2
        printf "\n" >&2
        printf "%sOPTIONS%s:\n" $yellow $reset >&2
        printf "\t%s-h%s, %s--help%s\t\tprint this help message and exit\n" $option_color $reset $option_color $reset >&2
        printf "\n" >&2
        # TODO: check if jq is installed, and color the link accordingly
        printf "%sDEPENDENCIES%s:\n" $yellow $reset >&2
        printf "\t%sjq%s %s%s%s\n" (set_color $fish_color_command) $reset $italics https://github.com/jqlang/jq $reset >&2
        printf "\n" >&2
        __rust.fish::help_footer >&2
        return 0
    end

    if not test -f Cargo.toml
        printf "%serror%s: %s%s%s/Cargo.toml not found\n" $red $reset $blue $PWD $reset >&2
        return 1
    end

    set -l dependencies (command taplo get ".dependencies" --output-format toml < Cargo.toml)
    set -l dev_dependencies (command taplo get ".dev-dependencies" --output-format toml < Cargo.toml)
    # echo "dependencies: $dependencies"
    # echo "dev_dependencies: $dev_dependencies"

    set -l endpoint "https://crates.io/api/v1"

    # for dependency in $dependencies
    #     printf "%s\n" $dependency
    # end

        set -l url "$endpoint/crates/ariadne"

        command curl -s "$url"
        # command curl -s "$url" | jaq -r '.crate.max_version'
        # curl -s "$url" | jq -r '.max_version'
end
