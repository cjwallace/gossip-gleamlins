import gleam/dynamic/decode
import gleam/erlang/process.{type Subject}
import gleam/int
import gleam/json
import gleam/otp/actor
import gleam/result

import messages
import node

type GenerateRequest {
  GenerateRequest(message_type: String, msg_id: Int)
}

type GenerateResponse {
  GenerateResponse(
    message_type: String,
    msg_id: Int,
    in_reply_to: Int,
    id: String,
  )
}

fn generate_request_decoder() {
  use message_type <- decode.field("type", decode.string)
  use msg_id <- decode.field("msg_id", decode.int)
  decode.success(GenerateRequest(message_type: message_type, msg_id: msg_id))
}

fn encode_generate_response(response: GenerateResponse) {
  json.object([
    #("type", json.string(response.message_type)),
    #("msg_id", json.int(response.msg_id)),
    #("id", json.string(response.id)),
    #("in_reply_to", json.int(response.in_reply_to)),
  ])
}

pub fn handler(request: messages.Request, state: Subject(node.Command)) {
  use request_body <- result.try(
    decode.run(request.body, generate_request_decoder())
    |> result.map_error(fn(_) { "Invalid generate request" }),
  )

  let node_id = actor.call(state, node.GetNodeId, 100)
  let msg_id = actor.call(state, node.GetNextMsgId, 100)

  let unique_id = node_id <> "-" <> int.to_string(msg_id)

  let response_body =
    encode_generate_response(GenerateResponse(
      message_type: "generate_ok",
      msg_id: msg_id,
      id: unique_id,
      in_reply_to: request_body.msg_id,
    ))

  Ok(messages.Response(src: node_id, dest: request.src, body: response_body))
}
