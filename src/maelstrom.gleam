import gleam/erlang
import gleam/erlang/process.{type Subject}
import gleam/io
import gleam/result

import messages
import registry

pub fn run(handler_registry: registry.Registry(state), state: Subject(state)) {
  let assert Ok(line) = erlang.get_line("")

  use request <- result.try(
    messages.decode_request(line)
    |> result.map_error(fn(_) { "Could not decode request" }),
  )

  use message_type <- result.try(
    messages.get_message_type(request.body)
    |> result.map_error(fn(_) { "Could not extract message type" }),
  )

  case registry.dispatch(handler_registry, message_type, request, state) {
    Ok(response) -> messages.encode_response(response) |> io.println
    Error(error) -> io.println_error("Unknown message type: {}" <> error)
  }

  run(handler_registry, state)
}
