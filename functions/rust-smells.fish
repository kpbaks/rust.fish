function rust-smells -d "Search for rust smells e.g. todo!(), .unwrap() in the current directory with rg"

    # TODO: allow the user to pass options to rg by using that argparse will ignore options after --, e.g. rust-smells -- -t rs
    # TODO: add options to filter which smells to search for
    set -l options h/help F/fzf v/verbose # A/after-context= B/before-context=

    if not argparse $options -- $argv
        eval (status function) --help
        return 2
    end

    set -l reset (set_color normal)
    set -l green (set_color green)
    set -l red (set_color red)
    set -l yellow (set_color yellow)
    set -l blue (set_color blue)
    set -l cyan (set_color cyan)
    set -l magenta (set_color magenta)
    set -l option_color (set_color $fish_color_option)
    set -l bold (set_color --bold)

    set -l editor (command --search nano)
    if set --query EDITOR
        set editor (command --search $EDITOR)
    end

    if set --query _flag_help
        printf "%sSearch for rust smells e.g. todo!(), .unwrap() with %srg%s in %s%s%s\n" $bold (set_color $fish_color_command) $reset (set_color --italics --underline) $PWD $reset
        printf "\n"
        printf "%sUSAGE%s: %s%s%s [OPTIONS]\n" $yellow $reset (set_color $fish_color_command) (status function) $reset
        printf "\n"
        printf "%sOPTIONS%s:\n" $yellow $reset
        printf "\t%s-h%s, %s--help%s                Print this help message and exit.\n" $option_color $reset $option_color $reset
        printf "\t%s-v%s, %s--verbose%s             Print the rg command that will be run.\n" $option_color $reset $option_color $reset
        # printf "\t%s-A%s, %s--after-context%s=NUM   Print NUM lines of trailing context after matching lines.\n" $option_color $reset $option_color $reset
        # printf "\t%s-B%s, %s--before-context%s=NUM  Print NUM lines of leading context before matching lines.\n" $option_color $reset $option_color $reset
        if command --query fzf
            printf "\t%s-F%s, %s--fzf%s                 Use %s%s%s to select the file and line to open with %s%s%s\n" $option_color $reset $option_color $reset (set_color $fish_color_command) (command --search fzf) $reset (set_color $fish_color_command) $editor $reset
        end
        printf "\n"
        printf "%sEXAMPLES%s:\n" $yellow $reset
        if command --query fzf
            printf "\t"
            printf "%s --fzf # Search for lines containing rust smells across *.rs in %s and use fzf to select the file and line to open in the editor" (status function) $PWD | fish_indent --ansi
        end

        if not command --query rg
            printf "\n"
            printf "%sERROR%s: rg (%s%s%s) is not found in \$PATH\n" $red $reset (set_color --underline) "https://github.com/BurntSushi/ripgrep" $reset
        end

        printf "\n"
        __rust.fish::help_footer

        return 0
    end >&2

    if not command --query rg
        printf "\n"
        printf "%sERROR%s: rg (%s%s%s) is not found in \$PATH\n" $red $reset (set_color --underline) "https://github.com/BurntSushi/ripgrep" $reset
        return 1
    end

    if test $PWD = $HOME
        printf "%swarning%s: Not sure it is a good idea to RECURSIVELY search through %s%s%s\n" $yellow $reset (set_color --italics --underline) $PWD $reset
        return 0
    end

    # the --fzf flag overrules --after-context and --before-context flags
    # because fzf needs to show the context of the matches, which it cannot do
    # if the match context spans multiple lines
    # set -l after_context 0
    # if set --query _flag_after_context; and not set --query _flag_fzf
    #     # fish's argparse does not support -<opt>=<val> syntax for short options
    #     # if string match --quiet --regexp '^=.*' -- $_flag_after_context
    #     #     set after_context (string sub --start 1 -- $_flag_after_context)
    #     # else
    #     # end
    #         set after_context $_flag_after_context
    # end

    # set -l before_context 0
    # if set --query _flag_before_context; and not set --query _flag_fzf
    #     # fish's argparse does not support -<opt>=<val> syntax for short options
    #     # if string match --quiet --regexp '^=.*' -- $_flag_before_context
    #     #     set before_context (string sub --start 1 -- $_flag_before_context)
    #     # else
    #     # end
    #         set before_context $_flag_before_context
    # end

    # # set --long --local


    # if not string match --regex --quiet '^\d+$' $after_context
    #     printf "%serror%s: --after-context %s%s%s is not a positive integer\n" $red $reset (set_color --bold) $after_context $reset
    #     return 1
    # end

    # if not string match --regex --quiet '^\d+$' $before_context
    #     printf "%serror%s: --before-context %s%s%s is not a positive integer\n" $red $reset (set_color --bold) $before_context $reset
    #     return 1
    # end

    set -l after_context 0
    set -l before_context 0

    # Enable hyperlinks introduced in rg 0.14.0
    # NOTE: --vimgrep is used to have <file>:<line>:<column>: such that when the hyperlinks is clicked, the file is opened in the editor at the given line and column
    # style oneof {no,}bold {no,}underline {no,}intense
    set -l rg_args \
        --pcre2 \
        --after-context=$after_context \
        --before-context=$before_context \
        --type=rust \
        --pretty \
        --column \
        --ignore-case \
        --hyperlink-format=default \
        --vimgrep \
        --colors="match:none" \
        --colors="match:bg:yellow" \
        --colors="match:fg:black" \
        --colors="match:style:bold" \
        --colors="path:fg:blue" \
        --colors="line:fg:green" \
        --colors="column:fg:red"


    set -l regexp '(todo!\(\)|unimplemented!\(\)|unreachable!\(\)|\.clone\(\)|\.unwrap\(\)|\.expect\("[^"]*"\))'
    set -l rg_command "command rg $rg_args '\\b$regexp'"

    if set --query _flag_verbose
        echo $rg_command | fish_indent --ansi
    end

    if set --query _flag_fzf
        if not command --query fzf
            printf "\n"
            printf "%serror%s: fzf (%s%s%s) is not found in \$PATH\n" $red $reset (set_color --underline) "https://github.com/junegunn/fzf" $reset
            return 1
        end
        # TODO: show some lines above and below the found line
        # TODO: improve colors
        set -l fzf_opts \
            --ansi \
            --exit-0 \
            --delimiter : \
            --nth 3.. \
            --header-first \
            --scroll-off=5 \
            --multi \
            --pointer='|>' \
            --marker='✓ ' \
            --no-mouse \
            --color='marker:#00ff00' \
            --color="header:#$fish_color_command" \
            --color="info:#$fish_color_keyword" \
            --color="prompt:#$fish_color_autosuggestion" \
            --color='border:#F80069' \
            --color="gutter:-1" \
            --color="hl:#FFB600" \
            --color="hl+:#FFB600" \
            --no-scrollbar \
            --cycle \
            --bind "enter:become($EDITOR {1} +{2})" \
            --preview "bat --style=numbers --color=always --highlight-line {2} --line-range {2}: {1}" \
            --preview-window '~3'
        eval "$rg_command" | while read line
            # Ignore matches in comments '// '
            if string match --quiet '*// *' $line
                continue
            end
            echo $line
        end | command fzf $fzf_opts
        set -l pstatus $pipestatus
        if test $pstatus[1] -ne 0
            printf "No matches for regular expression %s'%s'%s in %s%s%s 😎\n" $green $regexp $reset (set_color --bold --italics) $PWD $reset
        end
        if test $pstatus[2] -ne 0
            # User most likely pressed `<esc>` in fzf, which will cause it quit and return 1
        end
    else
        set -l n_matches 0
        eval "$rg_command" | while read line
            # Ignore matches in comments '// '
            if string match --quiet '*// *' $line
                continue
            end
            echo $line
            set n_matches (math $n_matches + 1)
        end
        if test $n_matches -gt 0
            printf "\n"
            printf "Found %s%d%s matches for regular expression %s'%s'%s in %s%s%s 😎\n" $green $n_matches $reset $green $regexp $reset (set_color --bold --italics) $PWD $reset
        end
        if test $status -ne 0
            printf "No matches for regular expression %s'%s'%s in %s%s%s 😎\n" $green $regexp $reset (set_color --bold --italics) $PWD $reset
        end
    end
end
