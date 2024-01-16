set -l c complete -c cargo

function __complete_crates.io
    set -l limit 20
    test 1 -gt $limit -a $limit -le 100; or return 1 # Limit imposed by crates.io
    set -l query (commandline --current-token)
    # set -l query ari
    test -n $query; or return 0 # Nothing to search for
    test (string sub --length=1 -- $query) = -; and return 0 # The token at the cursor is a some kind of option. `cargo search` will be confused by that

    set -l regexp (printf "^(%s[\w_-]+) = \"(\d+\.\d+\.\d+)\"\s+#\s(.+)\$" $query)

    command cargo search --limit=$limit $query \
        | string match --regex --groups-only -- $regexp \
        | while read --line crate_name crate_version desc
        # printf "%s\t(%s) %s\n" $crate_name $crate_version $desc
        printf "%s\t%s\n" $crate_name $desc
    end
end

$c -n "__fish_seen_subcommand_from add" -a "(__complete_crates.io)"
$c -n "__fish_seen_subcommand_from search" -a "(__complete_crates.io)"
