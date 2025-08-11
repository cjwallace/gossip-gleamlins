import gleam/erlang/process.{type Subject}

import maelstrom/node
import maelstrom/rpc_client

pub type Context(state) {
  Context(
    // Maelstrom node
    node: Subject(node.Command),
    // RPC client, handles outbound messages
    rpc_client: Subject(rpc_client.Command),
    // Challenge-specific state
    state: state,
  )
}

pub fn new() {
  let node = node.new()
  let rpc_client = rpc_client.new()
  Context(node: node, rpc_client: rpc_client, state: Nil)
}

pub fn set_state(context: Context(_), new_state: state) {
  Context(node: context.node, rpc_client: context.rpc_client, state: new_state)
}
