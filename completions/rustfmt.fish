# based on rustfmt 1.7.0
set -l c complete -c rustfmt

$c -l check -d "Run in 'check' mode. Exits with 0 if input is formatted correctly. Exits with 1 and prints a diff if formatting is required."
$c -l emit -a "files stdout" -d "What data to emit and how"
$c -l backup -d "Backup any modified files."
$c -l config-path -d "Path for the configuration file"
set -l editions 2015 2018 2021 2024
$c -l edition -a "$editions" -d "Rust edition to use"
set -l colors always never auto
$c -l color -a "$colors" -d "Use colored output (if supported)"
set -l config_templates default minimal current
$c -l print-config -a "$config_templates" -d "Dumps a default or minimal config to PATH."
$c -l files-with-diff -d "Prints the names of mismatched files that were formatted. Prints the names of files that would be formatted when used with --check mode."
$c -l config -d "Set options from command line. These settings take priority over .rustfmt.toml"
$c -s v -l verbose -d "Print verbose output"
$c -s q -l quiet -d "Print less output"
$c -s V -l version -d "Show version information"
set -l topics config
$c -s h -l help -d "Show this message or help about a specific topic: $(string join ', ' $config)"
