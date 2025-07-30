import gleam/dynamic/decode
import gleam/erlang/process.{type Subject}
import gleam/json
import gleam/otp/actor
import gleam/result

import messages
import node

type EchoRequest {
  EchoRequest(message_type: String, msg_id: Int, echo_: String)
}

type EchoResponse {
  EchoResponse(
    message_type: String,
    msg_id: Int,
    in_reply_to: Int,
    echo_: String,
  )
}

fn echo_request_decoder() {
  use message_type <- decode.field("type", decode.string)
  use msg_id <- decode.field("msg_id", decode.int)
  use echo_ <- decode.field("echo", decode.string)
  decode.success(EchoRequest(
    message_type: message_type,
    msg_id: msg_id,
    echo_: echo_,
  ))
}

fn encode_echo_response(response: EchoResponse) {
  json.object([
    #("type", json.string(response.message_type)),
    #("msg_id", json.int(response.msg_id)),
    #("echo", json.string(response.echo_)),
    #("in_reply_to", json.int(response.in_reply_to)),
  ])
}

pub fn handler(request: messages.Request, state: Subject(node.Command)) {
  use request_body <- result.try(
    decode.run(request.body, echo_request_decoder())
    |> result.map_error(fn(_) { "Invalid init request" }),
  )

  let node_id = actor.call(state, node.GetNodeId, 100)
  let msg_id = actor.call(state, node.GetNextMsgId, 100)

  let response_body =
    encode_echo_response(EchoResponse(
      message_type: "echo_ok",
      msg_id: msg_id,
      echo_: request_body.echo_,
      in_reply_to: request_body.msg_id,
    ))

  Ok(messages.Response(src: node_id, dest: request.src, body: response_body))
}
