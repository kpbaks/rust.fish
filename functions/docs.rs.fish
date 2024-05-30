function docs.rs -d ''
    # TODO: implement --no-nested-deps

    set -l options h/help n/no-nested-deps N-no-builtins
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


    if not command --query gum
        return 1
    end

    set -l jq_program
    if command --query jaq
        set jq_program jaq
    else if command --query jq
        set jq_program jq
    else
        return 1
    end

    # 1. see if we are in a cargo project/workspace
    # - if not, then error and exit
    set -l cargo_manifest (cargo locate-project --message-format plain --workspace)
    if test $status != 0
        return 2
    end

    set -l ferris_color '#DE4400'
    set -l gum_args --no-limit --match.foreground=$ferris_color --indicator.foreground=$ferris_color --selected-indicator.foreground=$ferris_color \
        --header="select which crate(s) to open at https://docs.rs/<crate>/<version>" --header.foreground=$ferris_color

    set -l crates
    if not set --query _flag_no_builtins
        set -a crates std core alloc proc_macro test # comes with the rust toolchain
    end

    set -a crates (cargo metadata --manifest-path $cargo_manifest --format-version 1 | $jq_program -r '.packages[] | "\(.name) \(.version)"')

    # TODO: use fzf with --ansi and color each version
    set -l selected_crates (printf '%s\n' $crates | gum filter $gum_args)

    if test (count $selected_crates) -eq 0
        printf 'no crates selected 😓\n'
        return 0
    end

    printf 'opening: %s\n' (string repeat --count (count $selected_crates) 🦀)

    for selection in $selected_crates
        string match --regex --groups-only '^(\S+)\s+(\S+)' $selection | read --line crate crate_version
        # https://docs.rs/ab_glyph_rasterizer/0.1.7/ab_glyph_rasterizer/index.html
        set -l url "https://docs.rs/$crate/$crate_version/$crate"
        open $url

        printf ' - https://docs.rs/%s%s%s/%s%s%s\n' (set_color $ferris_color) $crate $reset (set_color blue) $crate_version $reset
    end



    # cargo metadata  --format-version 1 | jaq 'select(.packages[].name == "open")'

    # 2. use `taplo` to find all [dependencies], [dev-dependencies], [build-dependencies]
    # 3. filter out all those who are local, i.e. not on crates.io

    # if not command --query taplo
    #     return 1
    # end

    # 4. use fzf/gum to present a selection list to the user

    # if not command --query fzf
    #     return 1
    # end


    # taplo get -o json .dependencies < Cargo.toml | jaq -r 'keys[]' | gum filter --no-limit --sort

    # TODO: use rust colors for foreground
    # gum filter --no-limit
    # 5. for each selected crate, open the crate on docs.rs in their browser

    # *6. do somehting special for std/core/alloc crates

    return 0
end
