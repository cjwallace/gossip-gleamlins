import gleam/erlang/process.{type Subject}
import gleam/list
import gleam/otp/actor

type Store {
  Store(messages: List(Int))
}

pub type Command {
  Add(message: Int)
  Read(reply_with: Subject(List(Int)))
}

fn handler(command: Command, store: Store) {
  case command {
    Add(message) -> {
      let updated_messages =
        Store(messages: list.append(store.messages, [message]))
      actor.continue(updated_messages)
    }
    Read(reply_with) -> {
      process.send(reply_with, store.messages)
      actor.continue(store)
    }
  }
}

pub fn new() {
  let assert Ok(messages) = actor.start(Store(messages: []), handler)
  messages
}

pub fn add_message(store: Subject(Command), message: Int) {
  // Idempotency: message can be stored only once.
  let current_messages = read_messages(store)
  case list.contains(current_messages, message) {
    True -> Nil
    False -> actor.send(store, Add(message))
  }
}

pub fn read_messages(store: Subject(Command)) {
  actor.call(store, Read, 100)
}

pub fn is_new_message(store: Subject(Command), message: Int) {
  let current_messages = read_messages(store)
  !list.contains(current_messages, message)
}
