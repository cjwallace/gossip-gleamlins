import gleam/dict

import maelstrom/context
import maelstrom/handlers/init
import maelstrom/rpc_server

import challenges/generate/generate_handler

pub fn main() {
  let handler_registry =
    dict.new()
    |> dict.insert("init", init.handler)
    |> dict.insert("generate", generate_handler.handler)

  let context = context.new()

  rpc_server.start(context, handler_registry)
}
