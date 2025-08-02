import gleam/erlang
import gleam/erlang/process
import gleam/io
import gleam/json
import gleam/result

import messages
import registry

pub fn run(handler_registry: registry.Registry(state), state: state) {
  let assert Ok(line) = erlang.get_line("")

  use request <- result.try(
    messages.decode_request(line)
    |> result.map_error(fn(_) { "Could not decode request" }),
  )

  use message_type <- result.try(
    messages.get_message_type(request.body)
    |> result.map_error(fn(_) { "Could not extract message type" }),
  )

  process.start(
    fn() {
      case registry.dispatch(handler_registry, message_type, request, state) {
        Ok(_) -> Nil
        Error(error) -> io.println_error("Unknown message type: {}" <> error)
      }
    },
    linked: False,
  )

  run(handler_registry, state)
}

pub fn send(from src: String, to dest: String, body body: json.Json) {
  let response = messages.Response(src:, dest:, body:)
  messages.encode_response(response) |> io.println
  Nil
}
