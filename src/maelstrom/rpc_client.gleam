/// RPC client, for sending RPC messages.
/// Includes retry logic.
import gleam/dict.{type Dict}
import gleam/dynamic.{type Dynamic}
import gleam/erlang/process.{type Subject}
import gleam/int
import gleam/io
import gleam/json.{type Json}
import gleam/list
import gleam/otp/actor

import maelstrom/protocol.{type Message}

// (Destination node ID, message ID)
type PendingMessageId =
  #(String, Int)

pub type RpcClient {
  Manager(
    pending_requests: Dict(PendingMessageId, Message(Json)),
    completed_requests: List(PendingMessageId),
  )
}

pub type Command {
  SendOnce(request: Message(Json))
  SendWithRetry(reply_with: Subject(Command), request: Message(Json))
  CancelRetry(request: Message(Dynamic))
}

pub fn handler(command: Command, manager: RpcClient) {
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

      let msg_id = protocol.get_msg_id_from_json(message.body)
      case msg_id {
        Ok(msg_id) -> {
          let pending_message_id = #(message.dest, msg_id)
          case is_request_completed(manager, pending_message_id) {
            True -> actor.continue(manager)
            False -> {
              retry(message, reply_with)
              case is_request_pending(manager, pending_message_id) {
                True -> manager
                False ->
                  create_pending_request(manager, pending_message_id, message)
              }
              |> actor.continue
            }
          }
        }
        Error(_) -> actor.continue(manager)
      }
    }
    CancelRetry(request) -> {
      let msg_id = protocol.get_in_reply_to(request.body)
      case msg_id {
        Ok(id) -> {
          let pending_message_id = #(request.src, id)
          handle_reply(manager, pending_message_id) |> actor.continue
        }
        Error(_) -> actor.continue(manager)
      }
    }
  }
}

fn send(message: Message(Json)) {
  process.start(
    fn() { protocol.encode_message(message) |> io.println },
    linked: True,
  )
}

fn retry(message: Message(Json), reply_with: Subject(Command)) {
  send(message)
  process.start(
    fn() {
      process.sleep(jitter(400, 200))
      process.send(reply_with, SendWithRetry(reply_with, message))
    },
    linked: True,
  )
}

fn is_request_completed(
  manager: RpcClient,
  pending_message_id: PendingMessageId,
) {
  list.contains(manager.completed_requests, pending_message_id)
}

fn mark_request_completed(
  manager: RpcClient,
  pending_message_id: PendingMessageId,
) {
  Manager(
    pending_requests: dict.drop(manager.pending_requests, [pending_message_id]),
    completed_requests: list.append(manager.completed_requests, [
      pending_message_id,
    ]),
  )
}

fn handle_reply(manager: RpcClient, pending_message_id: PendingMessageId) {
  case is_request_completed(manager, pending_message_id) {
    True -> manager
    False -> mark_request_completed(manager, pending_message_id)
  }
}

fn is_request_pending(manager: RpcClient, pending_message_id: PendingMessageId) {
  dict.has_key(manager.pending_requests, pending_message_id)
}

fn create_pending_request(
  manager: RpcClient,
  pending_message_id: PendingMessageId,
  message: Message(Json),
) {
  Manager(
    ..manager,
    pending_requests: dict.insert(
      manager.pending_requests,
      pending_message_id,
      message,
    ),
  )
}

fn jitter(base: Int, max_add: Int) {
  base + int.random(max_add)
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
