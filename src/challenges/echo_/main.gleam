import gleam/dict
import gleam/otp/actor

import handlers/init
import maelstrom
import node

import challenges/echo_/echo_handler

pub fn main() {
  let handler_registry =
    dict.new()
    |> dict.insert("init", init.handler)
    |> dict.insert("echo", echo_handler.handler)

  let assert Ok(node_actor) =
    actor.start(
      node.Node(id: "", all_node_ids: [], msg_counter: 0),
      node.handler,
    )

  maelstrom.run(handler_registry, node_actor)
}
