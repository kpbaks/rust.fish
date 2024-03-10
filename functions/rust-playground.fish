function rust-playground -d ''
    # https://play.rust-lang.org/help

    # If your code contains the #[test] attribute and does not contain a main method, cargo test will be executed instead of cargo run.

    # if this inner attribute is pretent rust-playground while compile as a lib
    #![crate_type="lib"]
    set -l options h/help v/version= M-mode= e/edition= p/prelude m/main l/lib
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
        # TODO: finish --help
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

    set -l rust_version stable
    if set --query _flag_version
        set rust_version $_flag_version
    end
    if not contains -- $rust_version nightly stable beta
        printf '%serror%s: --version, must be one of: nightly, stable, beta not %s%s%s\n' $red $reset $red $rust_version $reset
        return 2
    end

    set -l rust_mode debug
    if set --query _flag_mode
        set rust_mode $_flag_mode
    end

    if not contains -- $rust_mode debug release
        printf '%serror%s: --mode, must be one of: debug, release, not %s%s%s\n' $red $reset $red $rust_mode $reset
        return 2
    end

    set -l rust_edition 2021
    if set --query _flag_edition
        set rust_edition $_flag_edition
    end

    if not contains -- $rust_edition 2015 2018 2021 2024
        printf '%serror%s: --edition, must be one of: 2015, 2018, 2021, 2024 not %s%s%s\n' $red $reset $red $rust_edition $reset
        return 2
    end

    set -l lines
    if set --query _flag_prelude
        set -a lines "use std::cell::RefCell;"
        set -a lines "use std::collections::{VecDeque, HashMap, HashSet};"
        set -a lines "use std::rc::Rc;"
        set -a lines "use std::sync::{Arc, Mutex, RwLock};"
        set -a lines ""
        set -a lines "use regex::Regex;"
        set -a lines ""
    end

    if set --query _flag_main
        set -a lines "fn main() -> anyhow::Result<()> {"
        set -a lines "    Ok(())"
        set -a lines "}"
    end

    if test (count $argv) -eq 0; and isatty stdin
        # TODO: load a default main
        # anyhow, and other top 100 crates can be used in playground
        # printf '%serror%s: no input provided\n' $red $reset
        # set -a lines "fn main() -> anyhow::Result<()> {"
        # set -a lines "    Ok(())"
        # set -a lines "}"
    else
        if isatty stdin
            set -l inputfile $argv[1]
            if not test -f $inputfile
                printf '%serror%s: file not found: %s\n' $red $reset $inputfile
                return 1
            else
                # TODO: check extension is .rs
            end

            while read -l line
                set -a lines $line
            end <$inputfile
        else
            while read -l line
                set -a lines $line
            end
        end
    end

    set -l url_encoded_code

    for line in $lines
        for char in (string split '' $line)
            switch $char
                case ' '
                    set -a url_encoded_code '+'
                case '\t'
                    set -a url_encoded_code '%09'
                case '!'
                    set -a url_encoded_code '%21'
                case '+'
                    set -a url_encoded_code '%2B'
                case '\?'
                    set -a url_encoded_code '%3F'
                case '\*'
                    set -a url_encoded_code '%2A'
                case '*'
                    set -a url_encoded_code $char
            end
        end
        set -a url_encoded_code '%0A' # '\n'
    end

    set url_encoded_code (string join '' $url_encoded_code)

    # TODO: minify the url
    if test (string length $url_encoded_code) -gt 5000
        printf '%serror%s: input is too long\n' $red $reset
        return 1
    end

    # https://play.rust-lang.org/?version=stable&mode=debug&edition=2021
    set -l base_url 'https://play.rust-lang.org'
    set -l query_string "?version=$rust_version&mode=$rust_mode&edition=$rust_edition&code=$url_encoded_code"
    set -l url "$base_url/$query_string"
    xdg-open $url

    return 0
end
