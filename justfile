echo:
    gleam build && gleam run -m gleescript -- --module challenges/echo
    maelstrom/maelstrom test -w echo --bin ./seastar --time-limit 5
    rm ./seastar
