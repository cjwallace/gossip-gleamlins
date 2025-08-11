# seastar

Nascent [Maelstrom](https://github.com/jepsen-io/maelstrom/blob/main/doc/01-getting-ready/index.md) client in [Gleam](https://gleam.run/) to tackle the [Gossip Glomers](https://fly.io/dist-sys/) distributed systems challenges.
This is me learning all of Maelstrom, Gleam, and distributed systems. Do not use as a reference for idiomatic Gleam code.

## Usage

See the included justfile. With the maelstrom executable is at `maelstrom/maelstrom` relative to the root of this repo, each challenge can be run with:

```bash
just echo               # ... echo (challenge 1)
just generate           # unique per-node id generation (challenge 2)
just broadcast          # multi-node fault-tolerant broadcast (challenge 3a..3c)
just batched-broadcast  # more message-efficient broadcast (challenge 3d..3e)
just all                # all of the above, with curtailed output
```

## Organisation

At a high level, the code is split between implementations of the Gossip Glomers challenges, and a generic maelstrom client (to say, the implementation of a single node).
The client does not implement the full maelstrom protocol, and is evolving to serve the needs of the challenges.

```bash
src
├── challenges      # code specific to each gossip glomers challenge
├── maelstrom       # maelstrom client code (RPC, node state and related message handlers etc)
└── seastar.gleam   # entry point
```


## Todo

- Tests.
  The defacto tests for the codebase are the challenges themselves, but the maelstrom client needs unit tests.
- Docs!
  This is a learning project for me, and it might be useful to others!
- More challenges!
  Currently implemented through the broadcast challenge.
