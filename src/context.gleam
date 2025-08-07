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

pub fn new() {
  let node = node.new()
  let manager = rpc_manager.new()
  Context(node: node, manager: manager, state: Nil)
}

pub fn set_state(context: Context(_), new_state: state) {
  Context(node: context.node, manager: context.manager, state: new_state)
}
