import gleam/dict

import handlers/init
import handlers/topology
import maelstrom
import node

import challenges/broadcast/handlers/broadcast
import challenges/broadcast/handlers/read
import challenges/broadcast/message_store
import challenges/broadcast/state

// The generic "init" handler is for all challenges, and expects Subject(node.Command)
// as its second argument. This challenge has richer state, so we wrap the init handler
// such that our handler function signatures are homogeneous.
fn init_handler(req, state: state.BroadcastState) {
  init.handler(req, state.node)
}

// Likewise to init
fn topology_handler(req, state: state.BroadcastState) {
  topology.handler(req, state.node)
}

pub fn main() {
  let handler_registry =
    dict.new()
    |> dict.insert("init", init_handler)
    |> dict.insert("topology", topology_handler)
    |> dict.insert("broadcast", broadcast.handler)
    |> dict.insert("read", read.handler)

  let node_actor = node.new()
  let messages = message_store.new()
  let state = state.BroadcastState(node: node_actor, messages: messages)

  maelstrom.run(handler_registry, state)
}
