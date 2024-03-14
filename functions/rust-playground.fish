function rust-playground -d 'open rust playground (https://play.rust-lang.org) with a given code snippet or file'
    # https://play.rust-lang.org/help
    # If your code contains the #[test] attribute and does not contain a main method, cargo test will be executed instead of cargo run.
    set -l options h/help v/version= M/mode= e/edition= p/prelude m/main l/lib V/verbose
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

    set -l rust_editions 2015 2018 2021 2024
    set -l default_rust_edition 2021

    set -l rust_versions stable beta nightly
    set -l default_rust_version stable

    set -l rust_modes debug release
    set -l default_rust_mode debug

    if set --query _flag_help
        set -l option_color (set_color $fish_color_option)
        set -l reset (set_color normal)
        set -l bold (set_color --bold)
        set -l section_header_color (set_color yellow)
        set -l default_value_color (set_color blue)

        printf '%sopen rust playground (https://play.rust-lang.org) with a given code snippet or file%s\n' $bold $reset
        printf '\n'
        printf '%sUSAGE:%s %s%s%s [OPTIONS]\n' $section_header_color $reset (set_color $fish_color_command) (status function) $reset
        printf '\n'
        printf '%sOPTIONS:%s\n' $section_header_color $reset
        printf '\t%s-e%s, %s--edition%s EDITION   edition to use, one of: %s default: %s%s%s\n' $option_color $reset $option_color $reset (string join ', ' $rust_editions) $default_value_color $default_rust_edition $reset
        printf '\t%s-h%s, %s--help%s              show this help message and return\n' $option_color $reset $option_color $reset
        printf '\t%s-l%s, %s--lib%s               configure the code as a library\n' $option_color $reset $option_color $reset
        printf '\t%s-m%s, %s--main%s              include a main function\n' $option_color $reset $option_color $reset
        printf '\t%s-M%s, %s--mode%s MODE         which mode to use, one of: %s default: %s%s%s\n' $option_color $reset $option_color $reset (string join ', ' $rust_modes) $default_value_color $default_rust_mode $reset
        printf '\t%s-p%s, %s--prelude%s           include symbols from the rust std lib not in the prelude\n' $option_color $reset $option_color $reset
        printf '\t%s-v%s, %s--version%s VERSION   which version of rust to use, one of: %s default: %s%s%s\n' $option_color $reset $option_color $reset (string join ', ' $rust_versions) $default_value_color $default_rust_version $reset
        printf '\t%s-V%s, %s--verbose%s           show verbose output\n' $option_color $reset $option_color $reset
        printf '\n'

        printf '%sEXAMPLES:%s\n' $section_header_color $reset
        printf '\t%s%s\n' (printf (echo "$(status function) # open https://play.rust-lang.org without any code loaded" | fish_indent --ansi)) $reset
        printf '\t%s%s\n' (printf (echo "$(status function) --version nightly --mode release --edition 2024 --prelude --main" | fish_indent --ansi)) $reset
        printf '\t%s%s\n' (printf (echo "$(status function) src/main.rs # open https://play.rust-lang.org with the contents of src/main.rs" | fish_indent --ansi)) $reset

        return 0
    end >&2

    set -l rust_version $default_rust_version
    if set --query _flag_version
        set rust_version $_flag_version
    end
    if not contains -- $rust_version $rust_versions
        printf '%serror%s: --version, must be one of: %s not %s%s%s\n' $red $reset (string join ', ' $rust_versions) $red $rust_version $reset
        return 2
    end

    set -l rust_mode $default_rust_mode
    if set --query _flag_mode
        set rust_mode $_flag_mode
    end

    if not contains -- $rust_mode $rust_modes
        printf '%serror%s: --mode, must be one of: %s, not %s%s%s\n' $red $reset (string join ', ' $rust_modes) $red $rust_mode $reset
        return 2
    end

    set -l rust_edition $default_rust_edition
    if set --query _flag_edition
        set rust_edition $_flag_edition
    end

    if not contains -- $rust_edition $rust_editions
        printf '%serror%s: --edition, must be one of: %s not %s%s%s\n' $red $reset (string join ', ' $rust_editions) $red $rust_edition $reset
        return 2
    end

    if set --query _flag_lib; and set --query _flag_main
        printf '%serror%s: --lib and --main are mutually exclusive\n' $red $reset
        return 2
    end

    set -l lines

    if set --query _flag_lib
        # if this inner attribute is pretent rust-playground while compile as a lib
        #![crate_type="lib"]
        set -a lines '#![crate_type="lib"]'
        set -a lines ""
    end

    if set --query _flag_prelude
        set -a lines "#![allow(dead_code, unused_imports)]"
        set -a lines "use std::cell::RefCell;"
        set -a lines "use std::collections::{VecDeque, BTreeMap, BTreeSet, HashMap, HashSet};"
        set -a lines "use std::rc::Rc;"
        set -a lines "use std::sync::{Arc, Mutex, RwLock};"
        set -a lines ""
        set -a lines "// use regex::Regex;"
        set -a lines ""
    end

    if set --query _flag_main
        set -a lines "fn main() -> anyhow::Result<()> {"
        set -a lines ""
        set -a lines ""
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
                if test (path extension $inputfile) != '.rs'
                    printf '%serror%s: file must have a .rs extension: %s\n' $red $reset $inputfile
                    return 1
                end
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

    # TODO; handle the rest
    for line in $lines
        for char in (string split '' $line)
            switch $char
                case ' '
                    set -a url_encoded_code '+'
                case '\t'
                    set -a url_encoded_code '%09'
                case '!'
                    set -a url_encoded_code '%21'
                case '#'
                    set -a url_encoded_code '%23'
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

    if set --query _flag_verbose
        printf '%sinfo%s: uploading the following code to the rust playground:\n\n' $green $reset
        if command --query bat
            printf '%s\n' $lines | command bat --style=plain --language=rust
        else
            printf '%s\n' $lines
        end
    end

    # https://play.rust-lang.org/?version=stable&mode=debug&edition=2021
    set -l base_url 'https://play.rust-lang.org'
    set -l query_string "?version=$rust_version&mode=$rust_mode&edition=$rust_edition&code=$url_encoded_code"
    set -l url "$base_url/$query_string"

    if set --query _flag_verbose
        printf '\n%sinfo%s: opening the following url in the default browser:\n\n' $green $reset
        printf '%s\n' $url
    end

    set -l open_cmd
    if command --query open
        set open_cmd open
    else if command --query xdg-open
        set open_cmd xdg-open
    else
        printf '%serror%s: could not open the url in the default browser\n' $red $reset
        printf '%shint%s: install `open` or `xdg-open` to open the url in the default browser\n' $magenta $reset
        return 1
    end

    set -l expr "command $open_cmd '$url'"
    if set --query _flag_verbose
        printf '\n%sinfo%s: executing the following command:\n\n' $green $reset
        echo "$expr" | fish_indent --ansi
    end

    eval "$expr"

    return 0
end
