import gleam/dict
import gleam/erlang/process.{type Subject}

import context.{type Context}
import handlers/init
import handlers/topology
import maelstrom
import node
import rpc_manager

import challenges/broadcast/handlers/broadcast
import challenges/broadcast/handlers/read
import challenges/broadcast/message_store

// The ok handler removes messages from the retry registry
fn ok_handler(ctx: Context(Subject(message_store.Command)), message) {
  rpc_manager.receive(ctx.manager, message)
}

pub fn main() {
  let handler_registry =
    dict.new()
    |> dict.insert("init", init.handler)
    |> dict.insert("topology", topology.handler)
    |> dict.insert("broadcast", broadcast.handler)
    |> dict.insert("read", read.handler)
    |> dict.insert("broadcast_ok", ok_handler)

  let node_actor = node.new()
  let manager = rpc_manager.new()
  let messages = message_store.new()
  let context =
    context.Context(node: node_actor, state: messages, manager: manager)

  maelstrom.run(context, handler_registry)
}
