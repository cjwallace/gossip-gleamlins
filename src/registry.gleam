import gleam/dict.{type Dict}

import messages

pub type Handler(state) =
  fn(messages.Request, state) -> Result(Nil, String)

pub type Registry(state) =
  Dict(String, Handler(state))

pub type RequestMessage(body) {
  RequestMessage(src: String, dest: String, body: body)
}

pub fn dispatch(
  registry: Registry(state),
  message_type: String,
  request: messages.Request,
  state: state,
) -> Result(Nil, String) {
  case dict.get(registry, message_type) {
    Ok(handler) -> handler(request, state)
    Error(_) -> Error("Unknown message type: " <> message_type)
  }
}
