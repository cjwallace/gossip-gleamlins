build:
    gleam build && gleam run -m gleescript

echo: build
    maelstrom/maelstrom test -w echo --bin ./seastar --time-limit 5
