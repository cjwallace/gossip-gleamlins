# seastar

Nascent [Maelstrom](https://github.com/jepsen-io/maelstrom/blob/main/doc/01-getting-ready/index.md) client in [Gleam](https://gleam.run/) to tackle the [Gossip Glomers](https://fly.io/dist-sys/) distributed systems challenges.
This is me learning all of Maelstrom, Gleam, and distributed systems. Do not use as a reference for idiomatic Gleam code.

## Usage

See the included justfile. With the maelstrom executable is at `maelstrom/maelstrom` relative to the root of this repo, each challenge can be run with:

```bash
just echo      # ... echo (challenge 1)
just generate  # unique per-node id generation (challenge 2)
just broadcast # multi-node fault-tolerant broadcast (challenge 3a..3c)
```

## Notes

Next up:
- more message efficient broadcast
- tests!
