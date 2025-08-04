import gleam/dynamic.{type Dynamic}
import gleam/dynamic/decode
import gleam/list

import gleam/json
import gleam/result

import maelstrom
import messages.{type Message}
import node

import challenges/broadcast/message_store
import challenges/broadcast/state

type BroadcastRequest {
  BroadcastRequest(message_type: String, msg_id: Int, message: Int)
}

fn broadcast_request_decoder() -> decode.Decoder(BroadcastRequest) {
  use message_type <- decode.field("type", decode.string)
  use msg_id <- decode.field("msg_id", decode.int)
  use message <- decode.field("message", decode.int)
  decode.success(BroadcastRequest(message_type:, msg_id:, message:))
}

fn encode_broadcast_request(broadcast_request: BroadcastRequest) -> json.Json {
  let BroadcastRequest(message_type:, msg_id:, message:) = broadcast_request
  json.object([
    #("type", json.string(message_type)),
    #("msg_id", json.int(msg_id)),
    #("message", json.int(message)),
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

pub fn handler(request: Message(Dynamic), state: state.BroadcastState) {
  use request_body <- result.try(
    decode.run(request.body, broadcast_request_decoder())
    |> result.map_error(fn(_) { "Invalid broadcast request" }),
  )

  let node_id = node.get_node_id(state.node)
  let msg_id = node.get_next_msg_id(state.node)

  message_store.add_message(state.messages, request_body.message)

  let response_body =
    encode_broadcast_response(BroadcastResponse(
      message_type: "broadcast_ok",
      msg_id: msg_id,
      in_reply_to: request_body.msg_id,
    ))

  maelstrom.send(from: node_id, to: request.src, body: response_body)

  let neighbours = node.get_neighbours(state.node)

  // Send message to all neighbours except sender
  neighbours
  |> list.filter(fn(n) { n != request.src })
  |> list.map(fn(n) {
    let msg_id = node.get_next_msg_id(state.node)
    let request_body =
      encode_broadcast_request(BroadcastRequest(
        message_type: "broadcast",
        msg_id: msg_id,
        message: request_body.message,
      ))

    maelstrom.send(from: node_id, to: n, body: request_body)
  })

  Ok(Nil)
}
