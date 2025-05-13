import gleam/dynamic/decode
import gleam/erlang
import gleam/int
import gleam/io
import gleam/json

type RequestBody {
  InitRequest(
    message_type: String,
    msg_id: Int,
    node_id: String,
    all_node_ids: List(String),
  )
  EchoRequest(message_type: String, msg_id: Int, echo_instruction: String)
}

type RequestMessage {
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

fn decode_request(string: String) {
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

fn respond(message: RequestMessage) -> ResponseMessage {
  case message {
    RequestMessage(
      src,
      _dest,
      InitRequest(_message_type, msg_id, node_id, _all_node_ids),
    ) -> {
      ResponseMessage(
        src: node_id,
        dest: src,
        body: InitResponse(
          message_type: "init_ok",
          msg_id: int.random(1000),
          in_reply_to: msg_id,
        ),
      )
    }
    RequestMessage(
      src,
      dest,
      EchoRequest(_message_type, msg_id, echo_instruction),
    ) -> {
      ResponseMessage(
        src: dest,
        dest: src,
        body: EchoResponse(
          message_type: "echo_ok",
          msg_id: int.random(1000),
          echo_instruction: echo_instruction,
          in_reply_to: msg_id,
        ),
      )
    }
  }
}

pub fn handle_request(request: String) -> Result(ResponseMessage, String) {
  let message = decode_request(request)
  case message {
    Ok(message) -> {
      Ok(respond(message))
    }
    Error(_) -> Error("Invalid request message received " <> request)
  }
}

pub fn main() -> Nil {
  let line = erlang.get_line("")
  case line {
    Ok(request) -> {
      let response = handle_request(request)
      case response {
        Ok(message) -> encode_response(message) |> io.println
        Error(error) -> io.println(error)
      }
    }
    _ -> Nil
  }
  main()
}
