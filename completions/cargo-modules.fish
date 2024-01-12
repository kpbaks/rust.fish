set -l c complete --command (status filename | path basename | string sub --end=-5)
# set -l c complete --command cargo-modules

$c -f # Disable file completion

$c -s h -l help

set -l commands structure dependencies orphans help


# Commands:
# structure     Prints a crate's hierarchical structure as a tree.
# dependencies  Prints a crate's internal dependencies as a graph.
# orphans       Detects unlinked source files within a crate's directory.
# help          Print this message or the help of the given subcommand(s)

set -l cond "not __fish_seen_subcommand_from $commands"
$c -n $cond -a structure -d "Prints a crate's hierarchical structure as a tree."
$c -n $cond -a dependencies -d "Prints a crate's internal dependencies as a graph."
$c -n $cond -a structure -d "Detects unlinked source files within a crate's directory."
$c -n $cond -a structure -d "Print help message or the help of the given subcommand(s)"

# `cargo-modules structure |`

set -l cond "__fish_seen_subcommand_from structure"
$c -n $cond -l verbose -d "Use verbose output"
$c -n $cond -l lib -d "Process only this package's library"
# TODO: generate list of binaries
$c -n $cond -l bin -r -d "Process only the specified binary"
$c -n $cond -l no-fns
