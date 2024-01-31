#!/usr/bin/env fish

set -l reset (set_color normal)

set -l file clippy-lints.html
if not test -f $file
    exit 1
end

if not command --query htmlq
    exit 1
end

command htmlq --text -- 'span[class="ng-binding"]' <clippy-lints.html >lint-names.txt
# {{lint.group}} will be on the first line, so we remove it
command htmlq --text -- span.label-lint-group <clippy-lints.html | tail --lines=+2 >lint-groups.txt
# {{lint.level}} will be on the first line, so we remove it
command htmlq --text -- span.label-lint-level <clippy-lints.html | tail --lines=+2 >lint-levels.txt

# lint-name,lint-group,lint-level
command paste -d , lint-names.txt lint-groups.txt lint-levels.txt >clippy-lints.csv
