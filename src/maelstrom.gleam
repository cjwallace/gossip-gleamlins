import gleam/erlang
import gleam/erlang/process
import gleam/io
import gleam/result

import context.{type Context}
import messages
import registry

pub fn run(ctx: Context(state), handler_registry: registry.Registry(state)) {
  let assert Ok(line) = erlang.get_line("")

  use request <- result.try(
    messages.decode_message(line)
    |> result.map_error(fn(_) { "Could not decode request" }),
  )

  use message_type <- result.try(
    messages.get_message_type(request.body)
    |> result.map_error(fn(_) { "Could not extract message type" }),
  )

  process.start(
    fn() {
      case registry.dispatch(ctx, handler_registry, message_type, request) {
        Ok(_) -> Nil
        Error(error) -> io.println_error("Unknown message type: {}" <> error)
      }
    },
    linked: False,
  )

  run(ctx, handler_registry)
}
