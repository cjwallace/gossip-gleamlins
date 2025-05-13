import gleeunit
import gleeunit/should
import seastar

pub fn main() -> Nil {
  gleeunit.main()
}

pub fn init_request_test() {
  let init_json =
    "{\"src\":\"c1\",\"dest\":\"n1\",\"body\":{\"type\":\"init\",\"msg_id\":1,\"node_id\":\"n1\",\"node_ids\":[\"n1\",\"n2\",\"n3\"]}}"

  let result = seastar.handle_request(init_json)

  should.be_ok(result)
  case result {
    Ok(response) -> {
      should.equal(response.src, "n1")
      should.equal(response.dest, "c1")
      case response.body {
        seastar.InitResponse(message_type, _, in_reply_to) -> {
          should.equal(message_type, "init_ok")
          should.equal(in_reply_to, 1)
        }
        _ -> should.fail()
      }
    }
    Error(_) -> should.fail()
  }
}

pub fn decode_echo_request_test() {
  let echo_json =
    "{\"src\":\"c1\",\"dest\":\"n1\",\"body\":{\"type\":\"echo\",\"msg_id\":1,\"echo\":\"foo\"}}"
  let result = seastar.handle_request(echo_json)

  should.be_ok(result)
  case result {
    Ok(response) -> {
      should.equal(response.src, "n1")
      should.equal(response.dest, "c1")
      case response.body {
        seastar.EchoResponse(message_type, _, echo_instruction, in_reply_to) -> {
          should.equal(message_type, "echo_ok")
          should.equal(in_reply_to, 1)
          should.equal(echo_instruction, "foo")
        }
        _ -> should.fail()
      }
    }
    Error(_) -> should.fail()
  }
}
