# The maelstrom binary
MAELSTROM := 'maelstrom/maelstrom'

# The binary for a single maelstrom node
NODE := 'seastar'

@list:
    just --list

build:
    gleam build && gleam run -m gleescript

echo: build
    {{MAELSTROM}} test -w echo --bin {{NODE}} echo --time-limit 5
    rm {{NODE}}

generate: build
    {{MAELSTROM}} test -w unique-ids --bin {{NODE}} generate --time-limit 30 --rate 1000 --node-count 3 --availability total --nemesis partition
    rm {{NODE}}

all: build
    @echo "Running maelstrom echo test"
    @just echo 2>/dev/null | tail -n 1
    @echo "Running maelstrom unique ID generation test"
    @just generate 2>/dev/null | tail -n 1
