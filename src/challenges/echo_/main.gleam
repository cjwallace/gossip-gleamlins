import gleam/dict

import handlers/init
import maelstrom/context
import maelstrom/rpc_server

import challenges/echo_/echo_handler

pub fn main() {
  let handler_registry =
    dict.new()
    |> dict.insert("init", init.handler)
    |> dict.insert("echo", echo_handler.handler)

  let context = context.new()

  rpc_server.start(context, handler_registry)
}
