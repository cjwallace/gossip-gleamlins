import gleam/dynamic.{type Dynamic}
import gleam/dynamic/decode
import gleam/erlang/atom
import gleam/erlang/process.{type Subject}
import gleam/int
import gleam/io
import gleam/json
import gleam/list
import gleam/result
import gleam/string

import context.{type Context}
import messages.{type Message}
import node
import rpc_manager

import challenges/batched_broadcast/message_store

type BroadcastRequest {
  BroadcastRequest(message_type: String, msg_id: Int, message: Int)
  MultipleBroadcastRequest(
    message_type: String,
    msg_id: Int,
    messages: List(Int),
  )
}

fn broadcast_request_decoder() -> decode.Decoder(BroadcastRequest) {
  use variant <- decode.field("type", decode.string)
  case variant {
    "broadcast" -> {
      use message_type <- decode.field("type", decode.string)
      use msg_id <- decode.field("msg_id", decode.int)
      use message <- decode.field("message", decode.int)
      decode.success(BroadcastRequest(message_type:, msg_id:, message:))
    }
    _ -> {
      use message_type <- decode.field("type", decode.string)
      use msg_id <- decode.field("msg_id", decode.int)
      use messages <- decode.field("messages", decode.list(decode.int))
      decode.success(MultipleBroadcastRequest(message_type:, msg_id:, messages:))
    }
  }
}

fn encode_broadcast_request(broadcast_request: BroadcastRequest) -> json.Json {
  case broadcast_request {
    BroadcastRequest(message_type:, msg_id:, message:) ->
      json.object([
        #("type", json.string("broadcast")),
        #("message_type", json.string(message_type)),
        #("msg_id", json.int(msg_id)),
        #("message", json.int(message)),
      ])
    MultipleBroadcastRequest(message_type:, msg_id:, messages:) ->
      json.object([
        #("type", json.string("multiple_broadcast")),
        #("message_type", json.string(message_type)),
        #("msg_id", json.int(msg_id)),
        #("messages", json.array(messages, json.int)),
      ])
  }
}

type BroadcastResponse {
  BroadcastResponse(message_type: String, msg_id: Int, in_reply_to: Int)
}

fn encode_broadcast_response(response: BroadcastResponse) -> json.Json {
  json.object([
    #("type", json.string(response.message_type)),
    #("msg_id", json.int(response.msg_id)),
    #("in_reply_to", json.int(response.in_reply_to)),
  ])
}

pub fn handler(
  ctx: Context(Subject(message_store.Command)),
  request: Message(Dynamic),
) {
  use request_body <- result.try(
    decode.run(request.body, broadcast_request_decoder())
    |> result.map_error(fn(_) { "Invalid broadcast request" }),
  )

  let node_id = node.get_node_id(ctx.node)
  let msg_id = node.get_next_msg_id(ctx.node)

  // Use the same broadcast_ok type for single and multiple message broadcasts
  let response_body =
    encode_broadcast_response(BroadcastResponse(
      message_type: "broadcast_ok",
      msg_id: msg_id,
      in_reply_to: request_body.msg_id,
    ))

  rpc_manager.send_once(
    ctx.manager,
    messages.Message(src: node_id, dest: request.src, body: response_body),
  )

  case request_body {
    BroadcastRequest(_, _, message) -> {
      message_store.add_message(ctx.state, message)
      message_store.enqueue_message(ctx.state, message)
      schedule_batch_broadcast(ctx)
    }
    MultipleBroadcastRequest(_, _, messages) -> {
      message_store.add_messages(ctx.state, messages)
      message_store.enqueue_messages(ctx.state, messages)
      schedule_batch_broadcast(ctx)
    }
  }
  Ok(Nil)
}

// Register a single broadcast process, effectively a lock on batching.
// If this process already exists, do nothing, the messages will be collected
// by the already extant process.
pub fn schedule_batch_broadcast(ctx: Context(Subject(message_store.Command))) {
  debounce_with_lock("batching", 200, fn() {
    broadcast(ctx)
    message_store.clear_queue(ctx.state)
  })
}

fn debounce_with_lock(lock_name: String, delay_ms: Int, task: fn() -> a) {
  let name = atom.create_from_string(lock_name)

  case process.register(process.self(), name) {
    Ok(_) -> {
      process.start(
        fn() {
          process.sleep(delay_ms)
          task()
          process.unregister(name)
        },
        linked: True,
      )
      Nil
    }
    Error(_) -> Nil
  }
}

fn broadcast(ctx: Context(Subject(message_store.Command))) {
  let messages_to_broadcast = message_store.read_queue(ctx.state)

  let node_id = node.get_node_id(ctx.node)

  // Send message to all neighbours except sender
  case messages_to_broadcast {
    [] -> []
    _ ->
      ctx.node
      |> node.get_neighbours
      |> list.map(fn(n) {
        let msg_id = node.get_next_msg_id(ctx.node)
        let request_body =
          encode_broadcast_request(MultipleBroadcastRequest(
            message_type: "multiple_broadcast",
            msg_id: msg_id,
            messages: messages_to_broadcast,
          ))
        io.println_error(
          "type: multiple_broadcast, msg_id: "
          <> int.to_string(msg_id)
          <> ", messages: ",
        )
        io.println_error(string.join(
          list.map(messages_to_broadcast, int.to_string),
          with: ", ",
        ))
        rpc_manager.send_with_retry(
          ctx.manager,
          messages.Message(src: node_id, dest: n, body: request_body),
        )
      })
  }
}
