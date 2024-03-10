set -l c complete -c rust-playground

# $c -f # Disable file completion

$c -s h -l help -d 'show help message and return'
$c -s v -l version -x -a "stable beta nightly" -d "which version of rust to use, default: stable"
$c -s e -l edition -x -a "2015 2018 2021 2024" -d "edition to use, default: 2021"
$c -s M -l mode -x -a "debug release" -d "which mode to use, default: debug"
$c -s p -l prelude -d "include symbols from the rust std lib not in the prelude"
$c -s m -l main -d "include a main function"
$c -s l -l lib -d "configure the code as a library"
$c -s V -l verbose -d "show verbose output"
