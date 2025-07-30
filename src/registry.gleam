import gleam/dict.{type Dict}
import gleam/erlang/process.{type Subject}

import messages

pub type Handler(state) =
  fn(messages.Request, Subject(state)) -> Result(messages.Response, String)

pub type Registry(state) =
  Dict(String, Handler(state))

pub type RequestMessage(body) {
  RequestMessage(src: String, dest: String, body: body)
}

pub fn dispatch(
  registry: Registry(state),
  message_type: String,
  request: messages.Request,
  state: Subject(state),
) -> Result(messages.Response, String) {
  case dict.get(registry, message_type) {
    Ok(handler) -> handler(request, state)
    Error(_) -> Error("Unknown message type: " <> message_type)
  }
}
