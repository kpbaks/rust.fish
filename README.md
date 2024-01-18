# rust.fish

## Installation
```fish
fisher install kpbaks/rust.fish
```

## Abbreviations

<!-- use `__rust.fish::abbr::list` to list all abbreviations -->

```fish
abbr -a cg cargo
abbr -a cga cargo add
abbr -a cgad cargo add --dev
abbr -a cgb cargo build --jobs "(math (nproc) - 1)"
abbr -a cgbr cargo build --jobs "(math (nproc) - 1)" --release
abbr -a cgc cargo check
abbr -a cgd cargo doc --open
abbr -a cgi cargo install --jobs "(math (nproc) - 1)"
abbr -a cgmt --set-cursor --function abbr_cargo_metadata
abbr -a cgr --function abbr_cargo_run
abbr -a cgrb --set-cursor --function abbr_cargo_run_bin
abbr -a cgrr --function abbr_cargo_run_release
abbr -a cgrrb --set-cursor --function abbr_cargo_run_release_bin
abbr -a cgs cargo-search --limit=10
abbr -a cgt cargo test
abbr -a cgu cargo update
abbr -a cgbi cargo binstall # `cargo install binstall`
abbr -a cge cargo expand # `cargo install cargo-expand`
abbr -a cgm cargo-modules # `cargo install cargo-modules`
abbr -a cgmb --set-cursor --function abbr_cargo_modules_structure_bin
abbr -a cgml cargo-modules structure --lib
abbr -a cgmo cargo-modules orphans
abbr -a cgw cargo watch # `cargo install cargo-watch`
set -l cargo_watch_flags
set -a cargo_watch_flags --why # show paths that changed
set -a cargo_watch_flags --postpone # postpone first run until a file changes
set -a cargo_watch_flags --clear # clear the screen before each run
set -a cargo_watch_flags --notify # send desktop notification when watchexec notices
abbr -a cgwc cargo watch $cargo_watch_flags --exec check
abbr -a cgwt cargo watch $cargo_watch_flags --exec test
set -l rust_edition 2021
abbr -a rfmt rustfmt --edition=$rust_edition
abbr -a rfmtc rustfmt --edition=$rust_edition --check
```

## Functions

### `cargo-search`

A wrapper around `cargo search` that displays the results in a table. With the option to easily add any of the crates to the current project.
![image](https://github.com/kpbaks/rust.fish/assets/57013304/310d42b1-40a6-4a1c-8f43-e187a8697d2d)



## Completions

`cargo add` and `cargo search` have been enhanced such that they complete the crate names from crates.io.

![image](https://github.com/kpbaks/rust.fish/assets/57013304/d31e767b-0624-4099-b372-e21f531693ff)
