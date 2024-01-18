set -l c complete -c cargo-search

$c -s l -l limit -r -d "number of results to show [1..=100] (default: 10)"
