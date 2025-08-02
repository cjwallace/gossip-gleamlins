import gleam/dynamic/decode
import gleam/erlang/process.{type Subject}
import gleam/json
import gleam/result

import maelstrom
import messages
import node

type InitRequest {
  InitRequest(
    message_type: String,
    msg_id: Int,
    node_id: String,
    all_node_ids: List(String),
  )
}

type InitResponse {
  InitResponse(message_type: String, msg_id: Int, in_reply_to: Int)
}

fn init_request_decoder() {
  use message_type <- decode.field("type", decode.string)
  use msg_id <- decode.field("msg_id", decode.int)
  use node_id <- decode.field("node_id", decode.string)
  use node_ids <- decode.field("node_ids", decode.list(decode.string))
  decode.success(InitRequest(
    message_type: message_type,
    msg_id: msg_id,
    node_id: node_id,
    all_node_ids: node_ids,
  ))
}

fn encode_init_response(response: InitResponse) {
  json.object([
    #("type", json.string(response.message_type)),
    #("msg_id", json.int(response.msg_id)),
    #("in_reply_to", json.int(response.in_reply_to)),
  ])
}

pub fn handler(request: messages.Request, node_state: Subject(node.Command)) {
  use request_body <- result.try(
    decode.run(request.body, init_request_decoder())
    |> result.map_error(fn(_) { "Invalid init request" }),
  )

  // Makes synchronous call to prevent race.
  node.initialize_node(
    node_state,
    request_body.node_id,
    request_body.all_node_ids,
  )

  let msg_id = node.get_next_msg_id(node_state)

  let response_body =
    encode_init_response(InitResponse(
      message_type: "init_ok",
      msg_id: msg_id,
      in_reply_to: request_body.msg_id,
    ))

  Ok(maelstrom.send(
    from: request_body.node_id,
    to: request.src,
    body: response_body,
  ))
}
