import gleam/erlang/process.{type Subject}

import node
import rpc_manager

pub type Context(state) {
  Context(
    // Maelstrom node
    node: Subject(node.Command),
    // RPC
    manager: Subject(rpc_manager.Command),
    // Challenge-specific state
    state: state,
  )
}
