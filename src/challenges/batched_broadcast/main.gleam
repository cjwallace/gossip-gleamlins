import gleam/dict
import gleam/erlang/process.{type Subject}

import context.{type Context}
import handlers/init
import handlers/topology
import maelstrom
import rpc_manager

import challenges/batched_broadcast/handlers/broadcast
import challenges/batched_broadcast/handlers/read
import challenges/batched_broadcast/message_store

// The ok handler removes messages from the retry registry
fn ok_handler(ctx: Context(Subject(message_store.Command)), message) {
  rpc_manager.cancel_retry(ctx.manager, message)
}

pub fn main() {
  let handler_registry =
    dict.new()
    |> dict.insert("init", init.handler)
    |> dict.insert("topology", topology.handler)
    |> dict.insert("broadcast", broadcast.handler)
    |> dict.insert("multiple_broadcast", broadcast.handler)
    |> dict.insert("read", read.handler)
    |> dict.insert("broadcast_ok", ok_handler)

  let messages = message_store.new()
  let context = context.new() |> context.set_state(messages)

  maelstrom.run(context, handler_registry)
}
