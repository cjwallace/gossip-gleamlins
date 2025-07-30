# seastar

Nascent [Maelstrom](https://github.com/jepsen-io/maelstrom/blob/main/doc/01-getting-ready/index.md) client in [Gleam](https://gleam.run/) to tackle the [Gossip Glomers](https://fly.io/dist-sys/) distributed systems challenges.
This is me learning all of Maelstrom, Gleam, and distributed systems. Do not use as a reference for idiomatic Gleam code.

## Usage

Run a maelstrom echo test, assuming the `maelstrom` executable is at `maelstrom/maelstrom` relative to the root of this repo.

```sh
just echo
```

## Notes

Next up:
- tests
- next challenge: unique id generation
- spawn an actor per request
