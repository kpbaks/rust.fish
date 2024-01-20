set -l c complete -c bacon

$c -f # Disable file completion

$c -l help
$c -l version
$c -l prefs -d "Print the path to the prefs file, create it if it doesn't exist"
$c -s s -l summary -d "Start in summary mode"
$c -s S -l no-summary -d "Start in full mode (not summary)"
$c -s w -l wrap -d "Start with lines wrapped"
$c -s W -l no-wrap -d "Start with lines not wrapped"
$c -l reverse -d "Start with gui lines wrapped"
$c -l no-reverse -d "Start with standard gui order (focus on top)"
$c -s l -l list-jobs -d "List available jobs"
$c -l offline -d "Don't access the network (jobs may use it, though)"

# not test -f bacon.toml; and $c -l init -d "Create a bacon.toml file, ready to be customized"
$c -l init -d "Create a bacon.toml file, ready to be customized"

function __bacon_jobs
    test -f Cargo.toml; or return 1
    printf "%s\n" (command bacon --list-jobs)[4..-3] \
        | string replace --all "│" " " \
        | string replace --all --regex "\033\[\d*(;\d*)*m" "" \
        | string trim \
        | while read job command
        printf "%s\t%s\n" $job (string trim $command)
    end
end

function __bacon_features
    # TODO: implement
end

$c --keep-order -a "(__bacon_jobs)"
$c -s j -l job --keep-order -a "(__bacon_jobs)"

$c -l features -d "Comma separated list of features to ask cargo to compile with (if the job defines some, they're merged)"
$c -l all-features -d "Activate all available features"
$c -s e -l export-locations -d "Export locations in .bacon-locations file"
$c -s E -l no-export-locations -d "Don't export locations"
$c -s p -l path --force-files -d "Path to watch (must be a rust directory or inside)"
