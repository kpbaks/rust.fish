function rust-logs -d 'search for usage for rust logging macros like `log::info!` in the current directory with rg'
    set -l options h/help v/verbose t/trace d/debug i/info w/warn e/error f/fzf
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

    set -l editor (command --search nano)
    if set --query EDITOR
        set editor (command --search $EDITOR)
    end

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

        printf '\n'
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



    set -l after_context 0
    set -l before_context 0

    # Enable hyperlinks introduced in rg 0.14.0
    # NOTE: --vimgrep is used to have <file>:<line>:<column>: such that when the hyperlinks is clicked, the file is opened in the editor at the given line and column
    # style oneof {no,}bold {no,}underline {no,}intense
    set -l rg_args \
        --pcre2 \
        --glob="'*.rs'" \
        --after-context=$after_context \
        --before-context=$before_context \
        --type=rust \
        --color=ansi \
        --column \
        --ignore-case \
        --hyperlink-format=default \
        --vimgrep \
        --colors="match:none" \
        --colors="path:fg:blue" \
        --colors="line:fg:green" \
        --colors="column:fg:red"

    # --colors="match:bg:yellow" \
    # --colors="match:fg:black" \
    # --colors="match:style:bold" \

    set -l log_levels
    set --query _flag_trace; and set -a log_levels trace
    set --query _flag_debug; and set -a log_levels debug
    set --query _flag_info; and set -a log_levels info
    set --query _flag_warn; and set -a log_levels warn
    set --query _flag_error; and set -a log_levels error

    if test (count $log_levels) -eq 0
        # search for all levels if nothing is specified
        set log_levels trace debug info warn error
    end

    # set -l regexp '((tracing|log)::)?(trace|debug|info|warn|error)!'
    set -l regexp "((tracing|log)::)?($(string join '|' $log_levels))!"
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
        # set -l n_matches 0
        set -l n_trace 0
        set -l n_debug 0
        set -l n_info 0
        set -l n_warn 0
        set -l n_error 0

        eval "$rg_command" | while read line
            # Ignore matches in comments '// '
            if string match --quiet '*// *' $line
                continue
            end
            string match --quiet '*trace!*' $line; and set n_trace (math $n_trace + 1)
            string match --quiet '*debug!*' $line; and set n_debug (math $n_debug + 1)
            string match --quiet '*info!*' $line; and set n_info (math $n_info + 1)
            string match --quiet '*warn!*' $line; and set n_warn (math $n_warn + 1)
            string match --quiet '*error!*' $line; and set n_error (math $n_error + 1)

            echo $line
        end \
            | string replace --regex '((tracing|log)::)?(trace!)' "$(set_color --bold -b magenta black)\$3$(set_color normal)" \
            | string replace --regex '((tracing|log)::)?(debug!)' "$(set_color --bold -b blue black)\$3$(set_color normal)" \
            | string replace --regex '((tracing|log)::)?(info!)' "$(set_color --bold -b green black)\$3$(set_color normal)" \
            | string replace --regex '((tracing|log)::)?(warn!)' "$(set_color --bold -b yellow black)\$3$(set_color normal)" \
            | string replace --regex '((tracing|log)::)?(error!)' "$(set_color --bold -b red black)\$3$(set_color normal)"

        set -l n_matches (math $n_trace + $n_debug + $n_info + $n_warn + $n_error)

        if test $n_matches -gt 0
            printf "\n"
            printf "%s%d%s match%s for regular expression %s'%s'%s in %s%s%s:\n" \
                $green $n_matches $reset \
                (test $n_matches -gt 1; and echo "es"; or echo "") \
                $green $regexp $reset \
                (set_color --bold --italics) $PWD $reset

            if contains -- trace $log_levels
                printf ' - %strace%s: %3d 🚧\n' $magenta $reset $n_trace
            end
            if contains -- debug $log_levels
                printf ' - %sdebug%s: %3d 🐛\n' $blue $reset $n_debug
            end
            if contains -- info $log_levels
                printf ' - %sinfo%s:  %3d 👍\n' $green $reset $n_info
            end
            if contains -- warn $log_levels
                printf ' - %swarn%s:  %3d ⚠️\n' $yellow $reset $n_warn
            end
            if contains -- error $log_levels
                printf ' - %serror%s: %3d 😭\n' $red $reset $n_error
            end
        end
        if test $status -ne 0
            printf "no matches for regular expression %s'%s'%s in %s%s%s ¯\_(ツ)_/¯\n" $green $regexp $reset (set_color --bold --italics) $PWD $reset
        end
    end


    return 0
end
