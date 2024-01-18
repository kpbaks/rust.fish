# function _rust_install --on-event _rust_install
#     # Set universal variables, create bindings, and other initialization logic.
# end

# function _rust_update --on-event _rust_update
#     # Migrate resources, print warnings, and other update logic.
# end

# function _rust_uninstall --on-event _rust_uninstall
#     # Erase "private" functions, variables, bindings, and other uninstall logic.
# end

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


function __rust.fish::find_crate_root_dir
    set -l dir $PWD
    while test $dir != /
        if test -f "$dir/Cargo.toml"
            printf "%s\n" $dir
            return 0
        end

        set dir (path dirname $dir)
    end

    return 1
end

function __rust.fish::inside_crate_subtree
    __rust.fish::find_crate_root_dir >/dev/null
end

function __get_cargo_bins
    command cargo run --bin 2>&1 | string replace --regex --filter '^\s+' ''
    # if __rust.fish::find_crate_root_dir | read root_dir

    # end
end
function __get_cargo_examples
    command cargo run --example 2>&1 | string replace --regex --filter '^\s+' ''
end

function __rust.fish::abbr::list -d "list all abbreviations in rust.fish"
    string match --regex "^abbr -a.*" <(status filename) | fish_indent --ansi
end

function __rust.fish::abbr::env_var_overrides
    set -l env_var_overrides
    set -l buffer (commandline)
    if not string match --regex --quiet "RUST_LOG=\w+" -- $buffer
        # commandline does not contain RUST_LOG as a temporary env var override
        # if it is already exported as a env var, then add it with the default value of "info"
        set --query RUST_LOG; or set --append env_var_overrides "RUST_LOG=info"
    end
    if not string match --regex --quiet "RUST_BACKTRACE=\d+" -- $buffer
        set --query RUST_BACKTRACE; or set --append env_var_overrides "RUST_BACKTRACE=0"
    end

    printf "%s\n" $env_var_overrides
end

function __rust.fish::abbr::bin_postfix
    if __rust.fish::inside_crate_subtree
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
abbr -a cga cargo add
abbr -a cgad cargo add --dev
abbr -a cgb cargo build --jobs "(math (nproc) - 1)"
abbr -a cgbr cargo build --jobs "(math (nproc) - 1)" --release
abbr -a cgc cargo check
abbr -a cgd cargo doc --open
abbr -a cgi cargo install --jobs "(math (nproc) - 1)"
abbr -a cgil cargo install --jobs "(math (nproc) - 1)" --locked
function abbr_cargo_metadata
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

abbr -a cgmt --set-cursor --function abbr_cargo_metadata

function abbr_cargo_run
    printf "%s cargo run --jobs (math (nproc) - 1)" (string join " " -- (__rust.fish::abbr::env_var_overrides))
end
abbr -a cgr --function abbr_cargo_run

function abbr_cargo_run_bin
    printf "%s cargo run --jobs (math (nproc) - 1) --bin %% " (string join " " -- (__rust.fish::abbr::env_var_overrides))
    __rust.fish::abbr::bin_postfix
    printf "\n"
end
abbr -a cgrb --set-cursor --function abbr_cargo_run_bin

function abbr_cargo_run_release
    printf "%s cargo run --jobs (math (nproc) - 1) --release" (string join " " -- (__rust.fish::abbr::env_var_overrides))
end
abbr -a cgrr --function abbr_cargo_run_release

function abbr_cargo_run_release_bin
    printf "%s cargo run --jobs (math (nproc) - 1) --release --bin %% " (string join " " -- (__rust.fish::abbr::env_var_overrides))
    __rust.fish::abbr::bin_postfix
    printf "\n"
end
abbr -a cgrrb --set-cursor --function abbr_cargo_run_release_bin

abbr -a cgs cargo-search --limit=10
abbr -a cgt cargo test
abbr -a cgu cargo update
function abbr_cargo_update_package
    printf "cargo update --package %%\n"
    if test -f Cargo.toml
        set -l dependencies (command taplo get ".dependencies" --output-format toml < Cargo.toml)
        set -l dev_dependencies (command taplo get ".dev-dependencies" --output-format toml < Cargo.toml)
        # TODO: align by "="
        if test (count $dependencies) -gt 0
            # TODO: handle case where crate is of the form: "<name> = { version = <version> ... }"
            printf "# dependencies:\n"
            printf "# - %s\n" $dependencies
        end
        if test (count $dev_dependencies) -gt 0
            printf "#\n"
            printf "# dev-dependencies:\n"
            printf "# - %s\n" $dev_dependencies
        end
    end
end
abbr -a cgup cargo update --package
abbr -a cgup --set-cursor --function abbr_cargo_update_package
abbr -a cgud cargo update --dry-run

# cargo thirdparty subcommands
abbr -a cgbi cargo binstall # `cargo install binstall`
abbr -a cge cargo expand # `cargo install cargo-expand`
abbr -a cgm cargo-modules # `cargo install cargo-modules`

function abbr_cargo_modules_structure_bin
    printf "cargo-modules structure --bin %% "
    __rust.fish::abbr::bin_postfix

    printf "\n"
end
# abbr -a cgmb cargo-modules structure --bin
abbr -a cgmb --set-cursor --function abbr_cargo_modules_structure_bin
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
set -l rust_edition 2021
abbr -a rfmt rustfmt --edition=$rust_edition
abbr -a rfmtc rustfmt --edition=$rust_edition --check

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

$c -n "__fish_seen_subcommand_from add" -a "(__complete_crates.io)"
$c -n "__fish_seen_subcommand_from search" -a "(__complete_crates.io)"
