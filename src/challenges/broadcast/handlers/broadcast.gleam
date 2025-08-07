import gleam/dynamic.{type Dynamic}
import gleam/dynamic/decode
import gleam/erlang/process.{type Subject}
import gleam/json
import gleam/list
import gleam/result

import context.{type Context}
import messages.{type Message}
import node
import rpc_manager

import challenges/broadcast/message_store

type BroadcastRequest {
  BroadcastRequest(message_type: String, msg_id: Int, message: Int)
}

fn broadcast_request_decoder() -> decode.Decoder(BroadcastRequest) {
  use message_type <- decode.field("type", decode.string)
  use msg_id <- decode.field("msg_id", decode.int)
  use message <- decode.field("message", decode.int)
  decode.success(BroadcastRequest(message_type:, msg_id:, message:))
}

fn encode_broadcast_request(request: BroadcastRequest) -> json.Json {
  json.object([
    #("type", json.string(request.message_type)),
    #("msg_id", json.int(request.msg_id)),
    #("message", json.int(request.message)),
  ])
}

type BroadcastResponse {
  BroadcastResponse(message_type: String, msg_id: Int, in_reply_to: Int)
}

fn encode_broadcast_response(response: BroadcastResponse) -> json.Json {
  json.object([
    #("type", json.string(response.message_type)),
    #("msg_id", json.int(response.msg_id)),
    #("in_reply_to", json.int(response.in_reply_to)),
  ])
}

pub fn handler(
  ctx: Context(Subject(message_store.Command)),
  request: Message(Dynamic),
) {
  use request_body <- result.try(
    decode.run(request.body, broadcast_request_decoder())
    |> result.map_error(fn(_) { "Invalid broadcast request" }),
  )

  let node_id = node.get_node_id(ctx.node)
  let msg_id = node.get_next_msg_id(ctx.node)

  let is_new_message =
    message_store.is_new_message(ctx.state, request_body.message)

  let response_body =
    encode_broadcast_response(BroadcastResponse(
      message_type: "broadcast_ok",
      msg_id: msg_id,
      in_reply_to: request_body.msg_id,
    ))

  rpc_manager.send_once(
    ctx.manager,
    messages.Message(src: node_id, dest: request.src, body: response_body),
  )

  // Do not broadcast message to neighbours if it has been seen before
  case is_new_message {
    True -> {
      message_store.add_message(ctx.state, request_body.message)

      let neighbours = node.get_neighbours(ctx.node)

      // Send message to all neighbours except sender
      neighbours
      |> list.filter(fn(n) { n != request.src })
      |> list.map(fn(n) {
        let msg_id = node.get_next_msg_id(ctx.node)
        let request_body =
          encode_broadcast_request(BroadcastRequest(
            message_type: "broadcast",
            msg_id: msg_id,
            message: request_body.message,
          ))
        rpc_manager.send_with_retry(
          ctx.manager,
          messages.Message(src: node_id, dest: n, body: request_body),
        )
      })
    }
    False -> []
  }

  Ok(Nil)
}
