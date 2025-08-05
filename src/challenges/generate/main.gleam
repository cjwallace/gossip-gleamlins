import gleam/dict

import context
import handlers/init
import maelstrom
import node
import rpc_manager

import challenges/generate/generate_handler

pub fn main() {
  let handler_registry =
    dict.new()
    |> dict.insert("init", init.handler)
    |> dict.insert("generate", generate_handler.handler)

  let context =
    context.Context(node: node.new(), manager: rpc_manager.new(), state: Nil)

  maelstrom.run(context, handler_registry)
}
