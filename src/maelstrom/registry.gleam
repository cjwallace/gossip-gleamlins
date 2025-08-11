import gleam/dict.{type Dict}
import gleam/dynamic.{type Dynamic}

import maelstrom/context.{type Context}
import maelstrom/protocol.{type Message}

pub type Handler(state) =
  fn(Context(state), Message(Dynamic)) -> Result(Nil, String)

pub type Registry(state) =
  Dict(String, Handler(state))

pub fn dispatch(
  ctx: Context(state),
  registry: Registry(state),
  message_type: String,
  message: Message(Dynamic),
) -> Result(Nil, String) {
  case dict.get(registry, message_type) {
    Ok(handler) -> handler(ctx, message)
    Error(_) -> Error("Unknown message type: " <> message_type)
  }
}
