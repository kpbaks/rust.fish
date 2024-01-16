function _rust_install --on-event _rust_install
    # Set universal variables, create bindings, and other initialization logic.
end

function _rust_update --on-event _rust_update
    # Migrate resources, print warnings, and other update logic.
end

function _rust_uninstall --on-event _rust_uninstall
    # Erase "private" functions, variables, bindings, and other uninstall logic.
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

function __rust.fish::abbreviations
    string match --regex "^abbr -a.*" <(status filename) | fish_indent --ansi
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
abbr -a cgr RUST_LOG=info RUST_BACKTRACE=0 cargo run --jobs "(math (nproc) - 1)"

function abbr_cargo_run_bin
    set -l bins (__get_cargo_bins)
    # Check if RUST_LOG or RUST_BACKTRACE has already ben set, before adding temporary default
    set -l env_var_overrides
    set --query RUST_LOG; or set --append env_var_overrides "RUST_LOG=info"
    set --query RUST_BACKTRACE; or set --append env_var_overrides "RUST_BACKTRACE=0"

    printf "%s cargo run --jobs (math (nproc) - 1) --bin %% " (string join " " -- $env_var_overrides)
    if __rust.fish::inside_crate_subtree
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

    printf "\n"
end
abbr -a cgrb --set-cursor --function abbr_cargo_run_bin
abbr -a cgrr RUST_LOG=info RUST_BACKTRACE=0 cargo run --jobs "(math (nproc) - 1)" --release

function abbr_cargo_run_release_bin
    set -l bins (__get_cargo_bins)
    # Check if RUST_LOG or RUST_BACKTRACE has already ben set, before adding temporary default
    set -l env_var_overrides
    set --query RUST_LOG; or set --append env_var_overrides "RUST_LOG=info"
    set --query RUST_BACKTRACE; or set --append env_var_overrides "RUST_BACKTRACE=0"

    printf "%s cargo run --jobs (math (nproc) - 1) --release --bin %% " (string join " " -- $env_var_overrides)
    if __rust.fish::inside_crate_subtree
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

    printf "\n"
end
abbr -a cgrrb --set-cursor --function abbr_cargo_run_release_bin

abbr -a cgs cargo search --limit=10
abbr -a cgt cargo test
abbr -a cgu cargo update

# cargo thirdparty subcommands
abbr -a cgbi cargo binstall # `cargo install binstall`
abbr -a cge cargo expand # `cargo install cargo-expand`
abbr -a cgm cargo-modules # `cargo install cargo-modules`

function abbr_cargo_modules_structure_bin
    printf "%s cargo-modules structure --bin %% "
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


# completions
set -l c complete -c cargo

function __complete_crates.io
    set -l limit 20
    test 1 -gt $limit -a $limit -le 100; or return 1 # Limit imposed by crates.io
    set -l query (commandline --current-token)
    test -n $query; or return 0 # Nothing to search for
    test (string sub --length=1 -- $query) = -; and return 0 # The token at the cursor is a some kind of option. `cargo search` will be confused by that

    set -l regexp (printf "^(%s[\w_-]+) = \"(\d+\.\d+\.\d+)\"\s+#\s(.+)\$" $query)

    command cargo search --limit=$limit $query \
        | string match --regex --groups-only -- $regexp \
        | while read --line crate_name crate_version desc
        printf "%s\t(%s) %s\n" $crate_name $crate_version $desc
        # printf "%s\t%s\n" $crate_name $desc
    end
end

$c -n "__fish_seen_subcommand_from add" -a "(__complete_crates.io)"
$c -n "__fish_seen_subcommand_from search" -a "(__complete_crates.io)"
