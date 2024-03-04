# TODO: integrate sccache somehow

function __rust::on::install --on-event rust_install
    # Set universal variables, create bindings, and other initialization logic.
end

function __rust::on::update --on-event rust_update
    # Migrate resources, print warnings, and other update logic.
end

function __rust::on::uninstall --on-event rust_uninstall
    # Erase "private" functions, variables, bindings, and other uninstall logic.
end

set --query rust_fish_default_rust_backtrace_level
or set --universal rust_fish_default_rust_backtrace_level 0

set --query rust_fish_default_rust_log_level
or set --universal rust_fish_default_rust_log_level info

# TODO: create functions to detect if in a bin or lib crate

set -l rust_edition 2021
set -l reset (set_color normal)
set -l red (set_color red)
set -l yellow (set_color yellow)
set -l green (set_color green)

if not set --query CARGO_HOME
    printf "%srust.fish%s %swarning%s: %sCARGO_HOME%s is not set\n" $yellow $reset $red $reset $yellow $reset
    if test -d ~/.cargo
        printf "%sCARGO_HOME%s will be set to %s~/.cargo%s\n" $yellow $reset $green $reset
        set -gx CARGO_HOME ~/.cargo
    else
        printf "are you sure you have rust installed?\n"
        return 0
    end
end

if not test -d ~/.cargo/bin
    # TODO:
    # set -l reset (set_color normal)
    # set -l red (set_color red)
    # set -l yellow (set_color yellow)
    # printf "rust.fish %swarning:%s %s%s%s does not exist"
    # https://www.rust-lang.org/learn/get-started
else
    if not contains -- ~/.cargo/bin $PATH
        fish_add_path ~/.cargo/bin
    end
end

function __rust::get_rust_edition
    if not set --query __rust_get_rust_edition_cache
        set --global __rust_get_rust_edition_cache 2021
    end
    echo $__rust_get_rust_edition_cache
end

function __rust::cargo::find_crate_root_dir
    set -l dir $PWD
    while test $dir != /
        if test -f "$dir/Cargo.toml"
            if test -f "..$dir/Cargo.toml"
                # Handle case where you are in a subcrate of a workspace
                path dirname $dir
            else
                echo $dir
            end
            return 0
        end

        set dir (path dirname $dir)
    end

    return 1
end

function __rust::cargo::inside_crate_subtree
    __rust::cargo::find_crate_root_dir >/dev/null
end

function __rust::cargo::inside_workspace
    echo todo
    return 1
end

function __rust::cargo::crate_type
    echo todo
    echo lib
    echo bin
    return 1
end

function __rust::rustc::get_targets
    command rustc --print target-list
end

function __rust::rustc::get_target_features -a target_triple
    # e.g. set target_triple x86_64-unknown-linux-gnu
    # command rustc --target=$target_triple --print target-features \
    #     | while read line
    #     echo $line
    # end

    # TODO: filter the above result
    # TODO: it generates some empty lines for some reason
    command rustc --target=$target_triple --print target-features \
        | while read line
        string match --regex --groups-only "^\s+(\S+)\s+-\s(.+)\$" $line | read --line feature desc
        printf "%s\t%s\n" $feature $desc
    end

end

function __rust::cargo::get_tests -a target
    set -l expr "command cargo test $target -- --list --format=terse 2>/dev/null | sort --unique | string split --fields=1 ': '"
    set --query RUST_FISH_DEBUG; and echo $expr | fish_indent --ansi >&2
    eval $expr
end

function __rust::cargo::get_lib_tests
    __rust::cargo::get_tests --lib
end

function __rust::cargo::get_examples_tests
    __rust::cargo::get_tests --examples
end

function __rust::cargo::get_bins_tests
    __rust::cargo::get_tests --bins
end

function __rust::cargo::get_benches_tests
    __rust::cargo::get_tests --benches
end

function __get_cargo_bins
    set -l expr "command cargo run --bin 2>&1 | string replace --regex --filter '^\s+' ''"
    set --query RUST_FISH_DEBUG; and echo $expr | fish_indent --ansi >&2
    eval $expr
end

function __get_cargo_examples
    command cargo run --example 2>&1 | string replace --regex --filter '^\s+' ''
end

function __rust::abbr::utils::check_inside_crate
    if not __rust::cargo::inside_crate_subtree
        echo "# $PWD is not a subdirectory of a crate!"
    end
end

function __rust::abbr::list -d "list all abbreviations in rust.fish"
    string match --regex "^abbr -a.*" <(status filename) | fish_indent --ansi
end

function __rust::abbr::gen_jobs
    printf "set -l jobs (math (nproc) - 1) # leave one CPU core for interactivity\n"
end

function __rust::abbr::in_cargo_project
    if not __rust::cargo::inside_crate_subtree
        echo "# YOU ARE NOT INSIDE A CARGO PROJECT!"
    end
end

function __rust::abbr::env_var_overrides
    # TODO: what about CARGO_INCREMENTAL
    # TODO: what about RUSTFLAGS https://github.com/rust-lang/portable-simd/blob/master/beginners-guide.md#selecting-additional-target-features
    set -l env_var_overrides
    set -l buffer (commandline)

    # TODO: add
    # COLORBT_SHOW_HIDDEN=1

    # command --query mold
    # and not set --query --export RUSTFLAGS
    # and not string match --regex --quiet "RUSTFLAGS=\w+" -- $buffer
    # # or set --append env_var_overrides (printf "RUSTFLAGS='-C link-arg=-fuse-ld=%s'" (command --search mold))
    # and set --append env_var_overrides (printf "RUSTFLAGS='-C link-arg=-fuse-ld=%s'" mold)

    if not string match --regex --quiet "RUST_LOG=\w+" -- $buffer
        # commandline does not contain RUST_LOG as a temporary env var override
        # if it is already exported as a env var, then add it with the default value of "info"
        set --query RUST_LOG; or set --append env_var_overrides "RUST_LOG=$rust_fish_default_rust_log_level"
    end
    if not string match --regex --quiet "RUST_BACKTRACE=\d+" -- $buffer
        set --query RUST_BACKTRACE; or set --append env_var_overrides "RUST_BACKTRACE=$rust_fish_default_rust_backtrace_level"
    end

    printf "%s\n" $env_var_overrides
end

function __rust::abbr::gen_env_var_overrides
    # set -l overrides (__rust::abbr::env_var_overrides)
    __rust::abbr::env_var_overrides | while read -d = var value
        printf 'set -lx %s %s\n' $var $value
    end
end

function __rust::abbr::bin_postfix
    # CHECK if in a lib or bin crate
    if __rust::cargo::inside_crate_subtree
        set -l bins (__get_cargo_bins)
        set -l n_bins (count $bins)
        switch $n_bins
            case 0
                printf "# no binaries found, probably in a --lib crate"
            case 1
                printf "# 1 binary found: %s" $bins[1]
            case '*'
                printf "# %d binaries found: %s" $n_bins (string join ", " -- $bins)
        end

    else
        printf "# YOU ARE NOT INSIDE A CARGO PROJECT!"
    end
end

# abbreviations

# cargo
abbr -a cg cargo
# TODO: if in a cargo workspace, maybe suggest user to user `--package <package>` to specify which subcrate should hae
abbr -a cga cargo add
abbr -a cgad cargo add --dev
abbr -a cgab cargo add --build
abbr -a cgb cargo build --jobs "(math (nproc) - 1)"
abbr -a cgbr cargo build --jobs "(math (nproc) - 1)" --release
abbr -a cgc cargo check
abbr -a cgd cargo doc --open
function __rust::abbr::cargo_install
    __rust::abbr::gen_jobs
    printf "cargo install --jobs=\$jobs"
    set -l clipboard (fish_clipboard_paste)
    if string match --regex --quiet "https://git(hub|lab)\.com/\w+/\w+" -- $clipboard
        # Check if clipboard contains a git url, e.g. "https://github.com/Doctave/doctave"
        # If it does then expand `cgi` -> `cargo install --git "https://github.com/Doctave/doctave"`
        printf " --git %s%%" (string trim $clipboard)
    end
    printf "\n"
end

function __rust::abbr::cargo_install_locked
    __rust::abbr::gen_jobs
    printf "cargo install --jobs=\$jobs --locked"
    set -l clipboard (fish_clipboard_paste)
    if string match --regex --quiet "https://git(hub|lab)\.com/\w+/\w+" -- $clipboard
        printf " --git %s%%" (string trim $clipboard)
    end
    printf "\n"
end

abbr -a cgi --set-cursor --function __rust::abbr::cargo_install
abbr -a cgil --set-cursor --function __rust::abbr::cargo_install_locked

function __rust::abbr::cargo_metadata
    printf "cargo metadata --format-version=1"
    if command --query fx
        printf "| fx"
    else if command --query jaq
        printf "| jaq '.%%'"
    else if command --query jq
        printf "| jq '.%%'"
    end
    printf "\n"
end

abbr -a cgmt --set-cursor --function __rust::abbr::cargo_metadata


function __rust::abbr::cargo_new -a crate_type
    if test (count $argv) -eq 0
        printf "%s <(--)?(bin|lib)>\n" (status function)
        return 2
    end

    if not string match --regex --quiet '(--)?(bin|lib)' $crate_type
        return 2
    end

    if not string match --regex --quiet '^--' $crate_type
        set crate_type "--$crate_type"
    end

    set -l vcs git
    set -l edition (__rust::get_rust_edition)

    # TODO: if already in a cargo project, then do not add --vcs flag, as the user is most likely in a cargo workspace

    echo "set -l name %"
    echo "cargo new --vcs=$vcs --edition=$edition $crate_type \$name"
    echo "cd \$name"
end

function __rust::abbr::cargo_new_bin
    __rust::abbr::cargo_new bin
end
function __rust::abbr::cargo_new_lib
    __rust::abbr::cargo_new lib
end

abbr -a cgn -f __rust::abbr::cargo_new_bin --set-cursor
abbr -a cgnb -f __rust::abbr::cargo_new_bin --set-cursor
abbr -a cgnl -f __rust::abbr::cargo_new_lib --set-cursor

function abbr_cargo_run
    __rust::abbr::in_cargo_project
    __rust::abbr::gen_jobs
    __rust::abbr::gen_env_var_overrides
    # printf "%s cargo run --jobs=\$jobs" (string join " " -- (__rust::abbr::env_var_overrides))
    printf "cargo run --jobs=\$jobs"
end
abbr -a cgr --function abbr_cargo_run

function abbr_cargo_run_bin
    __rust::abbr::in_cargo_project
    __rust::abbr::gen_jobs
    printf "%s cargo run --jobs=\$jobs --bin %% " (string join " " -- (__rust::abbr::env_var_overrides))
    __rust::abbr::bin_postfix
    printf "\n"
end
abbr -a cgrb --set-cursor --function abbr_cargo_run_bin

function abbr_cargo_run_release
    __rust::abbr::in_cargo_project
    __rust::abbr::gen_jobs
    printf "%s cargo run --jobs=\$jobs --release" (string join " " -- (__rust::abbr::env_var_overrides))
end
abbr -a cgrr --function abbr_cargo_run_release

function abbr_cargo_run_release_bin
    __rust::abbr::in_cargo_project
    __rust::abbr::gen_jobs
    printf "%s cargo run --jobs=\$jobs --release --bin %% " (string join " " -- (__rust::abbr::env_var_overrides))
    __rust::abbr::bin_postfix
    printf "\n"
end
abbr -a cgrrb --set-cursor --function abbr_cargo_run_release_bin

function __rust::abbr::cargo_search
    set -l limit 10
    if string match --regex --groups-only "(\d+)" $argv | read n
        set limit $n
    end

    printf "cargo-search --limit=%d %%\n" $limit

end
abbr -a cgs --set-cursor --function __rust::abbr::cargo_search --regex "cgs\d*"
# abbr -a cgs cargo-search --limit=10
function __rust::abbr::cargo_test
    # If `cargo-nextest` is installed then use it, otherwise suggest the user install it
    if command --query cargo-nextest
        printf "# NOTE: `cargo-nextest` (as of 20-02-24) does not support DOC tests, use `cargo test --doc` instead\n"
        printf "cargo nextest run"
    else
        set -l nextest_url "https://nexte.st/"
        printf "# check out %s as an alternative to `cargo test`\n" $nextest_url
        printf "cargo test"
    end
end

abbr -a cgt -f __rust::abbr::cargo_test
abbr -a cgtd cargo test --doc

abbr -a cgu cargo update
# function abbr_cargo_update_package
#     printf "cargo update --package %%\n"
#     if test -f Cargo.toml
#         # TODO: what if you do not have taplo?
#         set -l dependencies (command taplo get ".dependencies" --output-format toml < Cargo.toml)
#         set -l dev_dependencies (command taplo get ".dev-dependencies" --output-format toml < Cargo.toml)
#         # TODO: align by "="
#         if test (count $dependencies) -gt 0
#             # TODO: handle case where crate is of the form: "<name> = { version = <version> ... }"
#             printf "# dependencies:\n"
#             printf "# - %s\n" $dependencies
#         end
#         if test (count $dev_dependencies) -gt 0
#             printf "#\n"
#             printf "# dev-dependencies:\n"
#             printf "# - %s\n" $dev_dependencies
#         end
#     end
# end
abbr -a cgup cargo update --package
# abbr -a cgup --set-cursor --function abbr_cargo_update_package
abbr -a cgud cargo update --dry-run

# cargo thirdparty subcommands
abbr -a cgbi cargo binstall # `cargo install binstall`
abbr -a cge cargo expand # `cargo install cargo-expand`
abbr -a cgm cargo-modules # `cargo install cargo-modules`

function __rust::abbr::cargo_modules_structure_bin
    printf "cargo-modules structure --bin %% "
    __rust::abbr::bin_postfix

    printf "\n"
end
# abbr -a cgmb cargo-modules structure --bin
abbr -a cgmb --set-cursor -f __rust::abbr::cargo_modules_structure_bin
abbr -a cgml cargo-modules structure --lib
abbr -a cgmo cargo-modules orphans

abbr -a cgw cargo watch # `cargo install cargo-watch`
# set -l cargo_watch_flags --why --postpone --clear --notify
set -l cargo_watch_flags
set -a cargo_watch_flags --why # show paths that changed
set -a cargo_watch_flags --postpone # postpone first run until a file changes
set -a cargo_watch_flags --clear # clear the screen before each run
set -a cargo_watch_flags --notify # send desktop notification when watchexec notices a change
# set -a cargo_watch_flags -L=info # inject RUST_LOG=info into the environment

abbr -a cgwc cargo watch $cargo_watch_flags --exec check
abbr -a cgwt cargo watch $cargo_watch_flags --exec test

# rustfmt
abbr -a rfmt rustfmt --edition=$rust_edition
abbr -a rfmtc rustfmt --edition=$rust_edition --check

# rustup
abbr -a rup rustup
abbr -a rupu rustup update
abbr -a rupus rustup update stable
function __rust::rustup::installed_toolchains
    command rustup toolchain list | string split --fields=1 " "
end

abbr -a rupr rustup run # toolchain

# bacon
abbr -a bc bacon # sorry `/usr/bin/bc`
abbr -a bct bacon test

# completions
set -l c complete -c cargo

function __complete_crates.io
    set -l limit 35
    test $limit -gt 1 -a $limit -le 100; or return 1 # Limit imposed by crates.io
    if test (count $argv) -eq 1
        set -f query $argv[1]
    else
        set -f query (commandline --current-token)
    end
    test -n $query; or return 0 # Nothing to search for
    test (string sub --length=1 -- $query) = -; and return 0 # The token at the cursor is a some kind of option. `cargo search` will be confused by that

    set -l regexp (printf "^(%s[\w_-]+) = \"(\d+\.\d+\.\d+)\"\s+#\s(.+)\$" $query)

    # PERF: add a caching mechanism for doing the same query 2 or more times consequtively
    command cargo search --limit=$limit $query \
        | string match --regex --groups-only -- $regexp \
        | while read --line crate_name crate_version desc
        printf "%s\t(v%s) %s\n" $crate_name $crate_version $desc
        # printf "%s\t%s\n" $crate_name $desc
    end
end

complete -c cargo -n "__fish_seen_subcommand_from add" -a "(__complete_crates.io)"
complete -c cargo -n "__fish_seen_subcommand_from search" -a "(__complete_crates.io)"

# TODO: find a way to intelligently search for all #[test] cases in a crate for `cargo test`

# function complete_condition_rustup_run
#     set -l buffer (commandline --current-process --cut-at-cursor)
#     string match --quiet "rustup run" -- $buffer
#     # test "$buffer" = "rustup run"
# end

# complete -c rustup -n complete_condition_rustup_run -a hahaha

function __complete_rustc_error_codes
    set -l cache_file /tmp/(status function).cache.txt
    if not test -f $cache_file
        set -l url https://doc.rust-lang.org/error_codes/error-index.html
        set -l curl_opts --silent
        command curl $curl_opts $url \
            | string match --regex --groups-only "(E\d{4})" \
            | sort --unique >$cache_file
    end

    while read line
        echo $line
    end <$cache_file
    # command cat $cache_file
end

# complete -c rustc -n "string match --quiet -- --explain (commandline --current-process --tokenize --cut-at-cursor)[-1]" -a "(__complete_rustc_error_codes)"
complete -c rustc -l explain -a "(__complete_rustc_error_codes)"

function __rust::emitters::enter_cargo_project_root_folder --on-variable PWD
    test -d Cargo.toml; or return 0
    # We could be in a subcrate of a cargo workspace so we have to
    # check if the parent also has a Cargo.toml
    test -d ../Cargo.toml; and return 0
    emit enter_cargo_project_root_folder $PWD
end

if command --query mold
    function __rust::hooks::use_mold_as_linker --on-event enter_cargo_project_root_folder
        # check if ./.cargo/config.toml exists
        if test .cargo/config.toml
            # TODO: finish
        end
    end
end

if command --query sccache
    function __rust::hooks::use_sccache --on-event enter_cargo_project_root_folder
        # check if ./.cargo/config.toml exists
        if test .cargo/config.toml
            # TODO: finish
        end
    end
end

# keybinds --------------------------------------------------------------------

# FIXME: does not work with multiline buffers e.g.
# ```fish
# set -l jobs 10
# cargo run --jobs=$jobs |
# ```
# Should change buffer to:
# ```fish
# set -l jobs 10
# RUST_BACKTRACE=0 cargo run --jobs=$jobs |
# ```
function __rust::keybinds::shuffle_RUST_BACKTRACE_impl -a buf
    set -l options l/linenum=
    if not argparse $options -- $argv
        return 2
    end

    set -l linenum 1
    if set --query _flag_linenum
        set linenum $_flag_linenum
    end

    if string match --regex '^\s*$' -- $buf
        # string is empty, do nothing
        return
    end

    set -l lines (string split \n -- $buf)


    if string match --regex --index "RUST_BACKTRACE=(0|1|full) " $buf | read --line entire_span value_span
        set entire_span (string split " " $entire_span)
        set value_span (string split " " $value_span)
        # echo "entire_span: $entire_span"
        # echo "value_span: $value_span"
        # RUST_BACKTRACE exists in the commandline buffer
        set -l current_backtrace_value (string sub --start=$value_span[1] --length=$value_span[2] $buf)
        switch $current_backtrace_value
            case 0 # -> 1
                set -f next_backtrace_value 1
            case 1 # -> full
                set -f next_backtrace_value full
            case full # -> None
                # Remove RUST_BACKTRACE=full from the commandline
                # NOTE: There is no way of changing a selection/span of the commandline buffer
                # with the `commandline` command. You have the override the ENTIRE buffer with the updated buffer
                set -l before
                if test $entire_span[1] -ne 1
                    # TODO: explain why we do this
                    set -l before (string sub --start=1 --end=$entire_span[1] $buf)
                end
                set -l after (string sub --start=(math "$entire_span[1] + $entire_span[2]") $buf)
                set -l updated_buffer "$before$after"
                echo $updated_buffer
            case '*'
                # unreachable!()
        end
        if set --query next_backtrace_value
            set -l before
            if test $entire_span[1] -ne 1
                set -l before (string sub --start=1 --end=$entire_span[1] $buf)
            end
            set -l after (string sub --start=(math "$entire_span[1] + $entire_span[2]") $buf)
            printf "%sRUST_BACKTRACE=%s %s\n" "$before" $next_backtrace_value $after
        end
    else
        # RUST_BACKTRACE does not exist in the commandline buffer
        # Prepend RUST_BACKTRACE=0 as a ephemeral env var
        echo "RUST_BACKTRACE=0 $buf"
    end
end

function __rust::keybinds::shuffle_RUST_BACKTRACE
    set -l buf (commandline)
    set -l line (commandline --line)
    set -l updated_buf (__rust::keybinds::shuffle_RUST_BACKTRACE_impl $buf --linenum $line)
    commandline --replace $updated_buf
    commandline --function repaint
end

begin
    # set -l mode rust
    # bind --mode=$mode \eb __rust::keybinds::shuffle_RUST_BACKTRACE
    bind \eb __rust::keybinds::shuffle_RUST_BACKTRACE
end
