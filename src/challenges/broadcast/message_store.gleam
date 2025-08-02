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

pub fn add_message(messages: Subject(Command), message: Int) {
  actor.send(messages, Add(message))
}

pub fn read_messages(messages: Subject(Command)) {
  actor.call(messages, Read, 100)
}
