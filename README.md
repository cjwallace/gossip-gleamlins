# seastar

Nascent [Maelstrom](https://github.com/jepsen-io/maelstrom/blob/main/doc/01-getting-ready/index.md) client in [Gleam](https://gleam.run/) to tackle the [Gossip Glomers](https://fly.io/dist-sys/) distributed systems challenges.
This is me learning all of Maelstrom, Gleam, and distributed systems. Do not use as a reference for idiomatic Gleam code.

## Usage

Build a `seastar` binary.

```sh
gleam build && gleam run -m gleescript
```

Run a maelstrom echo test, assuming both `maelstrom` and `seastar` are on the PATH (or point to them).

```sh
maelstrom test -w echo --bin seastar --time-limit 5
```

A justfile exists for convenience. Assuming maelstrom is untarred into the maelstrom directory, run the echo test with:

```sh
just echo
```

## Notes

This doesn't set up any mutable state, and as such only works for the echo server test, since no persistent record of the node_id is kept.
Next up:
- Use actors!
- Do I really need this much manual parsing for each message type? I hope not.
  - Parser combinators?
  - Registry of encoders/decoders?
  - Less strict typing, more optionals?
  - Profit?
