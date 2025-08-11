import gleam/erlang/process.{type Subject}
import gleam/int
import gleam/io
import gleam/list
import gleam/otp/actor
import gleam/set
import gleam/string

type Store {
  Store(messages: List(Int), queue: List(Int))
}

pub type Command {
  Add(messages: List(Int))
  Read(reply_with: Subject(List(Int)))
  Enqueue(messages: List(Int))
  ReadQueue(reply_with: Subject(List(Int)))
  TakeQueue(reply_with: Subject(List(Int)))
}

fn handler(command: Command, store: Store) {
  case command {
    Add(messages) -> {
      let updated_messages =
        Store(..store, messages: list.append(store.messages, messages))
      actor.continue(updated_messages)
    }
    Read(reply_with) -> {
      process.send(reply_with, store.messages)
      actor.continue(store)
    }
    Enqueue(messages) -> {
      let updated_queue =
        Store(..store, queue: list.append(store.queue, messages))
      io.println_error(
        "Queue:"
        <> string.join(list.map(updated_queue.queue, int.to_string), with: ", "),
      )
      actor.continue(updated_queue)
    }
    ReadQueue(reply_with) -> {
      process.send(reply_with, store.queue)
      actor.continue(store)
    }
    TakeQueue(reply_with) -> {
      process.send(reply_with, store.queue)
      let updated_queue = Store(..store, queue: [])
      actor.continue(updated_queue)
    }
  }
}

pub fn new() {
  let assert Ok(messages) = actor.start(Store(messages: [], queue: []), handler)
  messages
}

fn deduplicate(new: List(a), current: List(a)) {
  set.difference(set.from_list(new), set.from_list(current))
  |> set.to_list
}

pub fn store_message(store: Subject(Command), message: Int) {
  store_messages(store, [message])
}

pub fn store_messages(store: Subject(Command), new_messages: List(Int)) {
  let current_messages = read_messages(store)
  // Do not insert a message if it is already stored
  let deduplicated_messages = deduplicate(new_messages, current_messages)
  case deduplicated_messages {
    [] -> Nil
    _ -> actor.send(store, Add(deduplicated_messages))
  }
}

pub fn enqueue_message(store: Subject(Command), message: Int) {
  enqueue_messages(store, [message])
}

/// Do not enqueue messages already stored, or already queued
pub fn enqueue_messages(store: Subject(Command), new_messages: List(Int)) {
  let current_messages = read_messages(store)
  let queued_messages = read_queue(store)
  let deduplicated_messages =
    deduplicate(new_messages, list.append(current_messages, queued_messages))
  case deduplicated_messages {
    [] -> Nil
    _ -> actor.send(store, Enqueue(deduplicated_messages))
  }
}

pub fn read_messages(store: Subject(Command)) {
  actor.call(store, Read, 100)
}

pub fn read_queue(store: Subject(Command)) {
  actor.call(store, ReadQueue, 100)
}

/// Read and clear the queue atomically
pub fn take_queue(store: Subject(Command)) {
  actor.call(store, TakeQueue, 100)
}
