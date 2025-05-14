import gleam/otp/actor
import gleeunit
import gleeunit/should
import seastar.{
  Echo, EchoRequest, EchoResponse, Init, InitRequest, InitResponse, Node,
  RequestMessage, decode_request, handler,
}

pub fn main() -> Nil {
  gleeunit.main()
}

pub fn test_echo() {
  let src = "c1"
  let msg_id = 123
  let node_id = "n1"
  let all_node_ids = ["n1", "n2", "n3"]

  let assert Ok(actor) = actor.start(Node(id: "", all_node_ids: []), handler)
  let response =
    actor.call(actor, Init(src, msg_id, node_id, all_node_ids, _), 100)

  should.equal(response.src, node_id)
  should.equal(response.dest, src)
  case response.body {
    InitResponse(message_type, _, in_reply_to) -> {
      should.equal(message_type, "init_ok")
      should.equal(in_reply_to, msg_id)
    }
    _ -> should.fail()
  }

  let echo_response = actor.call(actor, Echo(src, 456, "test echo", _), 100)

  should.equal(echo_response.src, node_id)
  should.equal(echo_response.dest, src)
  case echo_response.body {
    EchoResponse(message_type, _, echo_instruction, in_reply_to) -> {
      should.equal(message_type, "echo_ok")
      should.equal(in_reply_to, 456)
      should.equal(echo_instruction, "test echo")
    }
    _ -> should.fail()
  }
}

pub fn decode_init_request_test() {
  let request =
    "{\"src\":\"c1\",\"dest\":\"n1\",\"body\":{\"type\":\"init\",\"msg_id\":1,\"node_id\":\"n1\",\"node_ids\":[\"n1\",\"n2\",\"n3\"]}}"

  let message = decode_request(request)

  should.be_ok(message)
  case message {
    Ok(RequestMessage(src, dest, body)) -> {
      should.equal(src, "c1")
      should.equal(dest, "n1")
      case body {
        InitRequest(message_type, _, node_id, all_node_ids) -> {
          should.equal(message_type, "init")
          should.equal(node_id, "n1")
          should.equal(all_node_ids, ["n1", "n2", "n3"])
        }
        _ -> should.fail()
      }
    }
    Error(_) -> should.fail()
  }
}

pub fn decode_echo_request_test() {
  let request =
    "{\"src\":\"c1\",\"dest\":\"n1\",\"body\":{\"type\":\"echo\",\"msg_id\":1,\"echo\":\"foo\"}}"

  let message = decode_request(request)

  should.be_ok(message)
  case message {
    Ok(RequestMessage(src, dest, body)) -> {
      should.equal(src, "c1")
      should.equal(dest, "n1")
      case body {
        EchoRequest(message_type, _, echo_instruction) -> {
          should.equal(message_type, "echo")
          should.equal(echo_instruction, "foo")
        }
        _ -> should.fail()
      }
    }
    Error(_) -> should.fail()
  }
}
