import gleam/dict.{type Dict}
import gleam/dynamic.{type Dynamic}
import gleam/erlang/process.{type Subject}
import gleam/int
import gleam/io
import gleam/json.{type Json}
import gleam/list
import gleam/otp/actor

import messages.{type Message}

pub type Manager {
  Manager(
    // Requests are identified by (destination node ID, message ID)
    pending_requests: Dict(#(String, Int), Message(Json)),
    completed_requests: List(#(String, Int)),
  )
}

pub type Command {
  SendOnce(request: Message(Json))
  SendWithRetry(reply_with: Subject(Command), request: Message(Json))
  CancelRetry(request: Message(Dynamic))
}

pub fn handler(command: Command, manager: Manager) {
  case command {
    SendOnce(message) -> {
      send(message)
      actor.continue(manager)
    }
    SendWithRetry(reply_with, message) -> {
      io.println_error(
        "RPC pending="
        <> int.to_string(dict.size(manager.pending_requests))
        <> " completed="
        <> int.to_string(list.length(manager.completed_requests)),
      )

      let msg_id = messages.get_msg_id_from_json(message.body)
      case msg_id {
        Ok(msg_id) -> {
          let request_id = #(message.dest, msg_id)
          case is_request_completed(manager, request_id) {
            True -> actor.continue(manager)
            False -> {
              retry(message, reply_with)
              case is_request_pending(manager, request_id) {
                True -> manager
                False -> create_pending_request(manager, request_id, message)
              }
              |> actor.continue
            }
          }
        }
        Error(_) -> actor.continue(manager)
      }
    }
    CancelRetry(request) -> {
      let msg_id = messages.get_in_reply_to(request.body)
      case msg_id {
        Ok(id) -> {
          let request_id = #(request.src, id)
          handle_reply(manager, request_id) |> actor.continue
        }
        Error(_) -> actor.continue(manager)
      }
    }
  }
}

fn send(message: Message(Json)) {
  process.start(
    fn() { messages.encode_message(message) |> io.println },
    linked: False,
  )
}

fn retry(message: Message(Json), reply_with: Subject(Command)) {
  send(message)
  process.start(
    fn() {
      process.sleep(jitter())
      process.send(reply_with, SendWithRetry(reply_with, message))
    },
    linked: True,
  )
}

fn is_request_completed(manager: Manager, request_id: #(String, Int)) {
  list.contains(manager.completed_requests, request_id)
}

fn mark_request_completed(manager: Manager, request_id: #(String, Int)) {
  Manager(
    pending_requests: dict.drop(manager.pending_requests, [request_id]),
    completed_requests: list.append(manager.completed_requests, [request_id]),
  )
}

fn handle_reply(manager: Manager, request_id: #(String, Int)) {
  case is_request_completed(manager, request_id) {
    True -> manager
    False -> mark_request_completed(manager, request_id)
  }
}

fn is_request_pending(manager: Manager, request_id: #(String, Int)) {
  dict.has_key(manager.pending_requests, request_id)
}

fn create_pending_request(
  manager: Manager,
  request_id: #(String, Int),
  message: Message(Json),
) {
  Manager(
    ..manager,
    pending_requests: dict.insert(manager.pending_requests, request_id, message),
  )
}

fn jitter() {
  400 + int.random(100)
}

pub fn new() {
  let manager = Manager(pending_requests: dict.new(), completed_requests: [])
  let assert Ok(actor) = actor.start(manager, handler)
  actor
}

pub fn send_once(manager: Subject(Command), request) {
  actor.send(manager, SendOnce(request))
}

pub fn send_with_retry(manager: Subject(Command), request) {
  actor.send(manager, SendWithRetry(manager, request))
}

pub fn cancel_retry(manager: Subject(Command), response) {
  Ok(actor.send(manager, CancelRetry(response)))
}
