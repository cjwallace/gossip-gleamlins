import gleam/erlang/process.{type Subject}

import node

import challenges/broadcast/message_store

pub type BroadcastState {
  BroadcastState(
    node: Subject(node.Command),
    messages: Subject(message_store.Command),
  )
}
