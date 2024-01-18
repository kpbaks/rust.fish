set -l c complete -c cargo-update-installed-binaries

$c -s h -l help -d 'print help message'
$c -s v -l verbose -d 'print the command to be run'
$c -s d -l dry-run -d 'don\'t run the command (implies --verbose)'
$c -s l -l list -d 'list installed cargo binaries'
