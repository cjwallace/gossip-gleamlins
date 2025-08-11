import gleam/dict
import gleam/erlang/process.{type Subject}

import maelstrom/context.{type Context}
import maelstrom/handlers/init
import maelstrom/handlers/topology
import maelstrom/rpc_client
import maelstrom/rpc_server

import challenges/broadcast/handlers/broadcast
import challenges/broadcast/handlers/read
import challenges/broadcast/message_store

// The ok handler removes messages from the retry registry
fn ok_handler(ctx: Context(Subject(message_store.Command)), message) {
  rpc_client.cancel_retry(ctx.rpc_client, message)
}

pub fn main() {
  let handler_registry =
    dict.new()
    |> dict.insert("init", init.handler)
    |> dict.insert("topology", topology.handler)
    |> dict.insert("broadcast", broadcast.handler)
    |> dict.insert("read", read.handler)
    |> dict.insert("broadcast_ok", ok_handler)

  let messages = message_store.new()
  let context = context.new() |> context.set_state(messages)

  rpc_server.start(context, handler_registry)
}
