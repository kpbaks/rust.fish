set -l c complete -c docs.rs

$c -s h -l help -d "show help message"
$c -s n -l no-nested-deps -d "only show dependencies listed in [{dev-,build-,}dependencies] section"
$c -s N -l no-builtins -d "do not show builtins crates, i.e. std, core, alloc, proc_macro, test"
