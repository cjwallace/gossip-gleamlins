import gleam/dynamic/decode
import gleam/erlang
import gleam/erlang/process.{type Subject}
import gleam/int
import gleam/io
import gleam/json
import gleam/otp/actor

// Parsing

pub type RequestBody {
  InitRequest(
    message_type: String,
    msg_id: Int,
    node_id: String,
    all_node_ids: List(String),
  )
  EchoRequest(message_type: String, msg_id: Int, echo_instruction: String)
}

pub type RequestMessage {
  RequestMessage(src: String, dest: String, body: RequestBody)
}

pub type ResponseBody {
  InitResponse(message_type: String, msg_id: Int, in_reply_to: Int)
  EchoResponse(
    message_type: String,
    msg_id: Int,
    echo_instruction: String,
    in_reply_to: Int,
  )
}

pub type ResponseMessage {
  ResponseMessage(src: String, dest: String, body: ResponseBody)
}

fn echo_request_decoder() {
  use message_type <- decode.field("type", decode.string)
  use msg_id <- decode.field("msg_id", decode.int)
  use echo_instruction <- decode.field("echo", decode.string)
  decode.success(EchoRequest(
    message_type: message_type,
    msg_id: msg_id,
    echo_instruction: echo_instruction,
  ))
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

fn body_decoder() {
  use message_type <- decode.field("type", decode.string)
  case message_type {
    "echo" -> echo_request_decoder()
    _ -> init_request_decoder()
  }
}

fn decode_message() {
  let decode_body = body_decoder()
  use src <- decode.field("src", decode.string)
  use dest <- decode.field("dest", decode.string)
  use body <- decode.field("body", decode_body)
  decode.success(RequestMessage(src: src, dest: dest, body: body))
}

pub fn decode_request(string: String) {
  let decoder = decode_message()
  let message = json.parse(from: string, using: decoder)
  message
}

fn encode_echo_response(
  message_type: String,
  msg_id: Int,
  echo_instruction: String,
  in_reply_to: Int,
) {
  json.object([
    #("type", json.string(message_type)),
    #("msg_id", json.int(msg_id)),
    #("echo", json.string(echo_instruction)),
    #("in_reply_to", json.int(in_reply_to)),
  ])
}

fn encode_init_response(message_type: String, msg_id: Int, in_reply_to: Int) {
  json.object([
    #("type", json.string(message_type)),
    #("msg_id", json.int(msg_id)),
    #("in_reply_to", json.int(in_reply_to)),
  ])
}

fn encode_response(message: ResponseMessage) {
  let body = case message.body {
    InitResponse(message_type, msg_id, in_reply_to) ->
      encode_init_response(message_type, msg_id, in_reply_to)
    EchoResponse(message_type, msg_id, echo_instruction, in_reply_to) ->
      encode_echo_response(message_type, msg_id, echo_instruction, in_reply_to)
  }

  json.object([
    #("src", json.string(message.src)),
    #("dest", json.string(message.dest)),
    #("body", body),
  ])
  |> json.to_string()
}

// Actor

pub type Node {
  Node(id: String, all_node_ids: List(String))
}

pub type Command {
  Init(
    src: String,
    msg_id: Int,
    node_id: String,
    all_node_ids: List(String),
    reply_to: Subject(ResponseMessage),
  )
  Echo(
    src: String,
    msg_id: Int,
    echo_instruction: String,
    reply_to: Subject(ResponseMessage),
  )
}

fn handle_init(
  src: String,
  msg_id: Int,
  node_id: String,
  all_node_ids: List(String),
  reply_to: Subject(ResponseMessage),
) {
  let new_node = Node(id: node_id, all_node_ids: all_node_ids)
  let response =
    ResponseMessage(
      src: new_node.id,
      dest: src,
      body: InitResponse(
        message_type: "init_ok",
        msg_id: int.random(1000),
        in_reply_to: msg_id,
      ),
    )

  process.send(reply_to, response)
  actor.continue(new_node)
}

fn handle_echo(
  node: Node,
  src: String,
  msg_id: Int,
  echo_instruction: String,
  reply_to: Subject(ResponseMessage),
) {
  let response =
    ResponseMessage(
      src: node.id,
      dest: src,
      body: EchoResponse(
        message_type: "echo_ok",
        msg_id: int.random(1000),
        in_reply_to: msg_id,
        echo_instruction: echo_instruction,
      ),
    )
  process.send(reply_to, response)
  actor.continue(node)
}

pub fn handler(command: Command, node: Node) {
  case command {
    Init(src, msg_id, node_id, all_node_ids, reply_to) ->
      handle_init(src, msg_id, node_id, all_node_ids, reply_to)
    Echo(src, msg_id, echo_instruction, reply_to) ->
      handle_echo(node, src, msg_id, echo_instruction, reply_to)
  }
}

fn loop(node: Subject(Command)) {
  let assert Ok(line) = erlang.get_line("")
  case decode_request(line) {
    Ok(RequestMessage(src, _, body)) -> {
      let response = case body {
        InitRequest(_, msg_id, node_id, all_node_ids) -> {
          actor.call(node, Init(src, msg_id, node_id, all_node_ids, _), 50)
        }
        EchoRequest(_, msg_id, echo_instruction) -> {
          actor.call(node, Echo(src, msg_id, echo_instruction, _), 50)
        }
      }

      encode_response(response) |> io.println
    }
    Error(_) -> io.println_error("Failed to parse request")
  }
  loop(node)
}

pub fn main() {
  let assert Ok(node) = actor.start(Node(id: "", all_node_ids: []), handler)
  loop(node)
}
