function rustc-explain-error -a error

    if test (count $argv) -eq 0
        set -l error_codes (__complete_rustc_error_codes)
        set -l padding 3
        # Know the length of every word is 5 "E\d{4}"
        set -l w 0
        for error_code in $error_codes
            if test (math "$w + 2 * $padding + 5") -gt $COLUMNS
                printf "\n"
                set w 0
            end
            printf "%s%s%s" (string repeat --count $padding " ") $error_code (string repeat --count $padding " ")
        end

        return 0
    end

    # e.g. https://doc.rust-lang.org/error_codes/E0014.html
    set -l url https://doc.rust-lang.org/error_codes/$error.html

    set -l curl_opts --silent
    set -l lines (command curl $curl_opts $url \
        | command htmlq -- main \
        | command pandoc -f html -t markdown - \
        | string match --invert ":::*" \
        | string replace "{.header}" "" \
        | string replace "{#note-this-error-code-is-no-longer-emitted-by-the-compiler}" ""
    )


    #![allow(unused)]
    # fn main() {
    # fn f(u: i32) {}

    # f(); // error!
    # }

    # TODO: to hard to this way, without parsing the html
    set -l i 1
    set -l n_lines (count $lines)
    while test $i -le $n_lines
        if string match --regex --quiet "^\s+#!\[allow\(unused\)\]" -- $lines[$i]

            # echo ADLKSJDSKALDJL
            set i (math "$i + 2")
            set j $i
            # Find the last line that matches "^\s+\}\$"
            while test $j -le $n_lines; and not string match --regex --quiet "^\S" -- $lines[$j]
                set j (math "$j + 1")
            end
            if test $j -eq $n_lines
                echo GOCHA
            end
            set j (math "$j - 3")
            # Wrap in a code block
            echo "```rust"
            for k in (seq $i $j)
                printf "%d %s\n" $k $lines[$k]
                # string trim $lines[$k]
                # echo $lines[$k]
            end
            echo "```"
            set i (math "$j + 2")
            continue
        end

        printf "%d %s\n" $i $lines[$i]
        # echo $lines[$i]
        set i (math "$i + 1")
    end

    # | command glow
end
