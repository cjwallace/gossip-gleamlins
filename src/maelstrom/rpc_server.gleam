import gleam/erlang
import gleam/io
import gleam/result

import maelstrom/context.{type Context}
import maelstrom/protocol
import maelstrom/registry

pub fn start(ctx: Context(state), handler_registry: registry.Registry(state)) {
  let assert Ok(line) = erlang.get_line("")

  use request <- result.try(
    protocol.decode_message(line)
    |> result.map_error(fn(_) { "Could not decode request" }),
  )

  use message_type <- result.try(
    protocol.get_message_type(request.body)
    |> result.map_error(fn(_) { "Could not extract message type" }),
  )

  // Dispatch synchronously (ensures, eg, node initialization has
  // completed before handling additional requests).
  case registry.dispatch(ctx, handler_registry, message_type, request) {
    Ok(_) -> Nil
    Error(error) -> io.println_error("Unknown message type: " <> error)
  }

  start(ctx, handler_registry)
}
