import gleam/dict

import context
import handlers/init
import maelstrom

import challenges/echo_/echo_handler

pub fn main() {
  let handler_registry =
    dict.new()
    |> dict.insert("init", init.handler)
    |> dict.insert("echo", echo_handler.handler)

  let context = context.new()

  maelstrom.run(context, handler_registry)
}
