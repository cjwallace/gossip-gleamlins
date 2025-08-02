import gleam/dict
import gleam/dynamic/decode
import gleam/erlang/process.{type Subject}
import gleam/json
import gleam/result
import maelstrom

import messages
import node

type TopologyRequest {
  TopologyRequest(
    message_type: String,
    msg_id: Int,
    topology: dict.Dict(String, List(String)),
  )
}

fn topology_request_decoder() -> decode.Decoder(TopologyRequest) {
  use message_type <- decode.field("type", decode.string)
  use msg_id <- decode.field("msg_id", decode.int)
  use topology <- decode.field(
    "topology",
    decode.dict(decode.string, decode.list(decode.string)),
  )
  decode.success(TopologyRequest(message_type:, msg_id:, topology:))
}

type TopologyResponse {
  TopologyResponse(message_type: String, msg_id: Int, in_reply_to: Int)
}

fn encode_topology_response(response: TopologyResponse) -> json.Json {
  json.object([
    #("type", json.string(response.message_type)),
    #("msg_id", json.int(response.msg_id)),
    #("in_reply_to", json.int(response.in_reply_to)),
  ])
}

pub fn handler(request: messages.Request, node_state: Subject(node.Command)) {
  use request_body <- result.try(
    decode.run(request.body, topology_request_decoder())
    |> result.map_error(fn(_) { "Invalid topology request" }),
  )

  node.set_topology(node_state, request_body.topology)

  let node_id = node.get_node_id(node_state)
  let msg_id = node.get_next_msg_id(node_state)

  let response_body =
    encode_topology_response(TopologyResponse(
      message_type: "topology_ok",
      msg_id: msg_id,
      in_reply_to: request_body.msg_id,
    ))

  Ok(maelstrom.send(from: node_id, to: request.src, body: response_body))
}
