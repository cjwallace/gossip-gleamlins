import gleam/dict.{type Dict}
import gleam/dynamic.{type Dynamic}

import messages.{type Message}

pub type Handler(state) =
  fn(Message(Dynamic), state) -> Result(Nil, String)

pub type Registry(state) =
  Dict(String, Handler(state))

pub type RequestMessage(body) {
  RequestMessage(src: String, dest: String, body: body)
}

pub fn dispatch(
  registry: Registry(state),
  message_type: String,
  request: Message(Dynamic),
  state: state,
) -> Result(Nil, String) {
  case dict.get(registry, message_type) {
    Ok(handler) -> handler(request, state)
    Error(_) -> Error("Unknown message type: " <> message_type)
  }
}
