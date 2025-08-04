import gleam/dynamic.{type Dynamic}
import gleam/dynamic/decode
import gleam/json.{type Json}

pub type Response {
  Response(src: String, dest: String, body: Json)
}

pub type Message(body) {
  Message(src: String, dest: String, body: body)
}

pub fn message_decoder() {
  use src <- decode.field("src", decode.string)
  use dest <- decode.field("dest", decode.string)
  use body <- decode.field("body", decode.dynamic)

  decode.success(Message(src, dest, body))
}

pub fn decode_message(string: String) {
  json.parse(from: string, using: message_decoder())
}

pub fn encode_message(message: Message(Json)) {
  json.object([
    #("src", json.string(message.src)),
    #("dest", json.string(message.dest)),
    #("body", message.body),
  ])
  |> json.to_string()
}

// Utilities to get fields without decoding a full type
pub fn get_message_type(body: Dynamic) {
  decode.run(body, decode.at(["type"], decode.string))
}

pub fn get_msg_id(body: Dynamic) {
  decode.run(body, decode.at(["msg_id"], decode.int))
}

pub fn get_in_reply_to(body: Dynamic) {
  decode.run(body, decode.at(["in_reply_to"], decode.int))
}

pub fn json_to_dynamic(body: Json) {
  json.to_string(body) |> json.parse(using: decode.dynamic)
}

pub fn get_msg_id_from_json(body: Json) {
  case json_to_dynamic(body) {
    Ok(blob) -> decode.run(blob, decode.at(["msg_id"], decode.int))
    Error(_) -> Error([])
  }
}
