import gleam/dynamic.{type Dynamic}
import gleam/dynamic/decode
import gleam/erlang/process.{type Subject}
import gleam/json
import gleam/result

import maelstrom/context.{type Context}
import maelstrom/node
import maelstrom/protocol.{type Message}
import maelstrom/rpc_client

import challenges/broadcast/message_store

type ReadRequest {
  ReadRequest(message_type: String, msg_id: Int)
}

fn read_request_decoder() -> decode.Decoder(ReadRequest) {
  use message_type <- decode.field("type", decode.string)
  use msg_id <- decode.field("msg_id", decode.int)
  decode.success(ReadRequest(message_type:, msg_id:))
}

type ReadResponse {
  ReadResponse(
    message_type: String,
    msg_id: Int,
    in_reply_to: Int,
    messages: List(Int),
  )
}

fn encode_read_response(response: ReadResponse) -> json.Json {
  json.object([
    #("type", json.string(response.message_type)),
    #("msg_id", json.int(response.msg_id)),
    #("in_reply_to", json.int(response.in_reply_to)),
    #("messages", json.array(response.messages, of: json.int)),
  ])
}

pub fn handler(
  ctx: Context(Subject(message_store.Command)),
  message: Message(Dynamic),
) {
  use request_body <- result.try(
    decode.run(message.body, read_request_decoder())
    |> result.map_error(fn(_) { "Invalid read request" }),
  )

  let node_id = node.get_node_id(ctx.node)
  let msg_id = node.get_next_msg_id(ctx.node)
  let messages = message_store.read_messages(ctx.state)

  let response_body =
    encode_read_response(ReadResponse(
      message_type: "read_ok",
      msg_id: msg_id,
      in_reply_to: request_body.msg_id,
      messages: messages,
    ))

  let response =
    protocol.Message(src: node_id, dest: message.src, body: response_body)

  rpc_client.send_once(ctx.rpc_client, response)
  Ok(Nil)
}
