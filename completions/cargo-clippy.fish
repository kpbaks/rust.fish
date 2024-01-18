set -l c complete -c cargo-clippy
$c -f # Disable file completion

function __complete_clippy_lints
    # TODO:
    # cargo clippy --explain LINT

    set -l dir (printf "/tmp/%s" (status function))
    test -d $dir; or command mkdir -p $dir
    set -l file $dir/clippy-lints.csv
    if not test -f $file

    end


end

$c -l no-deps -d "Run Clippy only on the given crate, without linting the dependencies"
$c -s h -l help -d "Print help message"
$c -s V -l version -d "Print version info"

$c -l explain -r -d "Print the documentation for a given lint"

set -l cond "contains -- -- (commandline --tokenize --cut-at-cursor)"
$c -n $cond -s W -l warn -r -d "Set lint warnings"
$c -n $cond -s W -l allow -r -d "Set lint allowed"
$c -n $cond -s W -l deny -r -d "Set lint denied"
$c -n $cond -s W -l forbid -r -d "Set lint forbidden"
