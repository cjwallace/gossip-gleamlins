import gleam/dict

import handlers/init
import maelstrom
import node

import challenges/echo_/echo_handler

pub fn main() {
  let handler_registry =
    dict.new()
    |> dict.insert("init", init.handler)
    |> dict.insert("echo", echo_handler.handler)

  let node_actor = node.new()

  maelstrom.run(handler_registry, node_actor)
}
