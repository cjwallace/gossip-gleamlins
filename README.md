# seastar

Nascent Maelstrom client in Gleam.
This is me learning both Maelstrom and Gleam, do not use as a reference for idiomatic Gleam code.

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
