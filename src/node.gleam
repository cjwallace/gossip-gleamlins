import gleam/erlang/process.{type Subject}
import gleam/otp/actor

type Node {
  Node(id: String, all_node_ids: List(String), msg_counter: Int)
}

pub type Command {
  InitializeNode(
    reply_with: Subject(String),
    node_id: String,
    all_node_ids: List(String),
  )
  GetNodeId(reply_with: Subject(String))
  GetNextMsgId(reply_with: Subject(Int))
}

fn handler(command: Command, node: Node) {
  case command {
    InitializeNode(reply_with, node_id, all_node_ids) -> {
      let initialized_node =
        Node(id: node_id, all_node_ids: all_node_ids, msg_counter: 0)
      process.send(reply_with, node.id)
      actor.continue(initialized_node)
    }
    GetNodeId(reply_with) -> {
      process.send(reply_with, node.id)
      actor.continue(node)
    }
    GetNextMsgId(reply_with) -> {
      process.send(reply_with, node.msg_counter)
      let updated_node = Node(..node, msg_counter: node.msg_counter + 1)
      actor.continue(updated_node)
    }
  }
}

pub fn new() {
  let assert Ok(node) =
    actor.start(Node(id: "", all_node_ids: [], msg_counter: 0), handler)
  node
}

pub fn initialize_node(
  node_state: Subject(Command),
  node_id: String,
  all_node_ids: List(String),
) {
  // We use call rather than send, and return the node_id, just to prevent races.
  // No other messages should be sent while initializing.
  actor.call(node_state, InitializeNode(_, node_id, all_node_ids), 100)
}

pub fn get_node_id(node_state: Subject(Command)) {
  actor.call(node_state, GetNodeId, 100)
}

pub fn get_next_msg_id(node_state: Subject(Command)) {
  actor.call(node_state, GetNextMsgId, 100)
}
