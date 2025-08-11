/// RPC server, for handling inbound RPC messages.
import gleam/dict.{type Dict}
import gleam/dynamic.{type Dynamic}
import gleam/erlang
import gleam/io
import gleam/result

import maelstrom/context.{type Context}
import maelstrom/protocol.{type Message}

type Handler(state) =
  fn(Context(state), Message(Dynamic)) -> Result(Nil, String)

type Registry(state) =
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

pub fn start(ctx: Context(state), handler_registry: Registry(state)) {
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
  case dispatch(ctx, handler_registry, message_type, request) {
    Ok(_) -> Nil
    Error(error) -> io.println_error("Unknown message type: " <> error)
  }

  start(ctx, handler_registry)
}
