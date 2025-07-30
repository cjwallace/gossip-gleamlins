import gleam/dynamic.{type Dynamic}
import gleam/dynamic/decode
import gleam/json.{type Json}

pub type Request {
  Request(src: String, dest: String, body: Dynamic)
}

pub type Response {
  Response(src: String, dest: String, body: Json)
}

pub fn request_decoder() {
  use src <- decode.field("src", decode.string)
  use dest <- decode.field("dest", decode.string)
  use body <- decode.field("body", decode.dynamic)

  decode.success(Request(src, dest, body))
}

pub fn decode_request(string: String) {
  json.parse(from: string, using: request_decoder())
}

pub fn encode_response(response: Response) {
  json.object([
    #("src", json.string(response.src)),
    #("dest", json.string(response.dest)),
    #("body", response.body),
  ])
  |> json.to_string()
}

pub fn get_message_type(body: Dynamic) {
  decode.run(body, decode.at(["type"], decode.string))
}
