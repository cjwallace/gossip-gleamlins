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
  ClearQueue
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
    ClearQueue -> {
      let updated_queue = Store(..store, queue: [])
      actor.continue(updated_queue)
    }
  }
}

pub fn new() {
  let assert Ok(messages) = actor.start(Store(messages: [], queue: []), handler)
  messages
}

pub fn add_message(messages: Subject(Command), message: Int) {
  let current_messages = read_messages(messages)
  case list.contains(current_messages, message) {
    True -> Nil
    False -> actor.send(messages, Add([message]))
  }
}

pub fn add_messages(messages: Subject(Command), new_messages: List(Int)) {
  let current_messages = read_messages(messages)

  // Do not insert a message if it is already stored
  let deduplicated_messages =
    set.difference(set.from_list(new_messages), set.from_list(current_messages))
    |> set.to_list
  actor.send(messages, Add(deduplicated_messages))
}

pub fn enqueue_message(messages: Subject(Command), message: Int) {
  actor.send(messages, Enqueue([message]))
}

pub fn enqueue_messages(messages: Subject(Command), new_messages: List(Int)) {
  let current_messages = read_messages(messages)

  let deduplicated_messages =
    set.difference(set.from_list(new_messages), set.from_list(current_messages))
    |> set.to_list

  case deduplicated_messages {
    [] -> Nil
    _ -> actor.send(messages, Enqueue(deduplicated_messages))
  }
}

pub fn read_queue(messages: Subject(Command)) {
  actor.call(messages, Read, 100)
}

pub fn clear_queue(messages: Subject(Command)) {
  actor.send(messages, ClearQueue)
}

pub fn read_messages(messages: Subject(Command)) {
  actor.call(messages, Read, 100)
}

pub fn is_new_message(messages: Subject(Command), message: Int) {
  let current_messages = read_messages(messages)
  !list.contains(current_messages, message)
}
