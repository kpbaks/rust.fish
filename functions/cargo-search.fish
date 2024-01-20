function cargo-search -d "Wrapper around `cargo search`"
    set -l options h/help l/limit=
    if not argparse $options -- $argv
        eval (status function) --help
        return 2
    end

    set -l delimiter "@"
    set -l bar "│"
    set -l reset (set_color normal)
    set -l green (set_color green)
    set -l yellow (set_color yellow)
    set -l blue (set_color blue)
    set -l cyan (set_color cyan)
    set -l magenta (set_color magenta)
    set -l bold (set_color --bold)
    set -l italics (set_color --italics)
    set -l crates_url https://crates.io/crates
    set -l default_limit 10

    if set --query _flag_help
        printf "%sWrapper around %s%s\n" $bold (printf (echo "cargo search" | fish_indent --ansi)) $reset >&2
        printf "\n" >&2
        printf "%sUSAGE%s:\n" $yellow $reset >&2
        printf "\t%s%s%s [%s--limit%s] <limit:%sint%s> <query:%sstr%s>\n" (set_color $fish_color_command) (status function) $reset (set_color $fish_color_option) $reset $cyan $reset (set_color $fish_color_quote) $reset >&2
        printf "\n" >&2
        printf "%sOPTIONS%s:\n" $yellow $reset >&2
        printf "\t%sl%s, %slimit%s\tnumber of results to show [1..=100] (default: %d)\n" $green $reset $green $reset $default_limit >&2
        printf "\t%sh%s, %shelp%s\t\tprint this help message and exit\n" $green $reset $green $reset >&2
        printf "\n" >&2
        printf "%sEXAMPLES%s:\n" $yellow $reset >&2
        printf "\t%s%s\n" (printf (echo "$(status function) --limit 5 regex" | fish_indent --ansi)) $reset >&2

        printf "\n" >&2
        __rust.fish::help_footer >&2
        return 0
    end

    set -l limit $default_limit
    if set --query _flag_limit
        set limit $_flag_limit
    end

    if not test $limit -gt 1 -a $limit -le 100
        printf "%serror%s: limit must be between 1 and 100, but is %s%s%s\n" $red $reset $red $limit $reset
        return 2 # Limit imposed by crates.io
    end

    set -l search_result (command cargo search --limit=$_flag_limit $argv)
    if test (count $search_result) -eq 0
        return 0
    end

    set -l crate_names
    set -l crate_versions
    set -l crate_descriptions
    # skip the last line, as it is something like
    # ... and 1190 crates more (use --limit N to see more)
    for line in $search_result[..-2]
        # Parse each line of the search result
        string match --regex --groups-only "^(\S+) = \"(\d+\.\d+\.\d+)\"[^#]+# (.+)\$" -- $line | read --line name _version desc
        set --append crate_names $name
        set --append crate_versions $_version
        set --append crate_descriptions $desc
    end

    # set --local --long | scope

    if not test -f Cargo.toml
        begin
            # printf "name%sversion%sdescription\n" $delimiter $delimiter
            for i in (seq (count $crate_names))
                printf "%s%d%s" $magenta $i $reset
                printf "%s" $delimiter
                printf "%s%s/%s" (set_color --dim) $crates_url $reset
                printf "%s%s%s" $green $crate_names[$i] $reset
                printf "%s" $delimiter
                printf "%s%s%s" $blue $crate_versions[$i] $reset
                printf "%s" $delimiter
                printf "%s%s%s" $italics "$crate_descriptions[$i]" $reset
                printf "\n"
            end
        end | command column --table --separator=$delimiter --output-separator=" $bar "
        return 0
    end

    set -l dependencies_already_added
    set -l dependencies_that_can_be_updated
    if command --query taplo
        # printf "taplo found\n"
        set -l dependencies (command taplo get ".dependencies" --output-format toml < Cargo.toml)
        set -l dev_dependencies (command taplo get ".dev-dependencies" --output-format toml < Cargo.toml)
        begin
            # printf "name%sversion%sdescription\n" $delimiter $delimiter
            for i in (seq (count $crate_names))
                printf "%s%d%s" $magenta $i $reset
                printf "%s" $delimiter
                printf "%s%s/%s" (set_color --dim) $crates_url $reset
                printf "%s%s%s" $green $crate_names[$i] $reset
                printf "%s" $delimiter
                printf "%s%s%s" $blue $crate_versions[$i] $reset
                printf "%s" $delimiter

                # Check if the crate is already a dependency
                # Check if the crate is already a dev dependency
                set -l dependency_color $green
                set -l dependency_version ""
                set -l dependency_icon " "
                for dep in $dependencies $dev_dependencies
                    if string match --regex --groups-only "^(\S+) = \"(.+)\"\$" -- $dep | read --line name _version
                        if test $name = $crate_names[$i]
                            set dependency_version $_version
                            if test $_version = $crate_versions[$i] -o $_version = "*"
                                set dependency_color $blue
                                set dependency_icon ✅
                                set --append dependencies_already_added $name
                            else
                                set dependency_color $yellow
                                # set dependency_icon ⚠️
                                # set dependency_icon 🐶
                                set dependency_icon ❗
                                set --append dependencies_that_can_be_updated $name
                            end
                            break
                        end
                    else if string match --regex --groups-only "^(\S+) = {.*version = \"([^\"]+)\".*" -- $dep | read --line name _version
                        if test $name = $crate_names[$i]
                            set dependency_version $_version
                            if test $_version = $crate_versions[$i] -o $_version = "*"
                                set dependency_color $blue
                                set dependency_icon ✅
                                set --append dependencies_already_added $name
                            else
                                set dependency_color $yellow
                                # set dependency_icon ⚠️
                                # set dependency_icon 🐶
                                set dependency_icon ❗
                                set --append dependencies_that_can_be_updated $name
                            end
                            break
                        end
                    end
                end

                printf "%s%s%s%s" $dependency_color $dependency_version $reset $dependency_icon
                printf "%s" $delimiter

                printf "%s%s%s" $italics "$crate_descriptions[$i]" $reset
                printf "\n"
            end
        end | command column --table --separator=$delimiter --output-separator=" $bar "
    else
        begin
            # printf "name%sversion%sdescription\n" $delimiter $delimiter
            for i in (seq (count $crate_names))
                printf "%s%d%s" $magenta $i $reset
                printf "%s" $delimiter
                printf "%s%s/%s" (set_color --dim) $crates_url $reset
                printf "%s%s%s" $green $crate_names[$i] $reset
                printf "%s" $delimiter
                printf "%s%s%s" $blue $crate_versions[$i] $reset
                printf "%s" $delimiter
                printf "%s%s%s" $italics "$crate_descriptions[$i]" $reset
                printf "\n"
            end
        end | command column --table --separator=$delimiter --output-separator=" $bar "
    end

    printf "\n"
    printf "%shint%s: use %s%s to add %slibrary%s as a dependency.\n" $cyan $reset (printf (echo "cargo add library" | fish_indent --ansi)) $reset $green $reset
    printf "%shint%s: use %s%s to add %slibrary%s as a dev dependency.\n" $cyan $reset (printf (echo "cargo add --dev library" | fish_indent --ansi)) $reset $green $reset
    for i in (seq (count $crate_names))
        abbr --add cga$i cargo add $crate_names[$i]
        abbr --add cgad$i cargo add --dev $crate_names[$i]
        abbr --add cgab$i cargo add --dev $crate_names[$i]
    end
    printf "%shint%s: use abbreviation %scga{,b,d}1..=%d%s to add the %si'th%s library to your %sCargo.toml%s project.\n" $cyan $reset (set_color $fish_color_command) (count $crate_names) $reset $magenta $reset (set_color --bold) $reset

    if test (count $dependencies_already_added) -gt 0
        # printf "\n"
        printf "these crates are already dependencies, and are up to date:\n"
        for dep in $dependencies_already_added
            printf " - %s%s%s\n" $green $dep $reset
        end
    end
    if test (count $dependencies_that_can_be_updated) -gt 0
        # printf "\n"
        printf "%shint%s: these crates can be updated:\n" $cyan $reset
        for dep in $dependencies_that_can_be_updated
            printf " - %s%s%s\n" $yellow $dep $reset
        end
    end

    # begin
    #     echo name
    #     echo version
    #     echo description
    #     for i in (seq (count $crate_names))
    #         echo $crate_names[$i]
    #         # printf "%s%s%s\n" (set_color red) $crate_names[$i] (set_color $normal)
    #         echo $crate_versions[$i]
    #         echo $crate_descriptions[$i]
    #     end
    # end | tabulate -r (math "$limit + 1") -s rounded --header

end
