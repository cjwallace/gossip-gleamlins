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

A just file exists for convenience, so long as your directory setup is exactly as mine.

```sh
just echo # Run a the maelstrom echo server test
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
