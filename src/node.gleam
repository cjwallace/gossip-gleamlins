import gleam/erlang/process.{type Subject}
import gleam/otp/actor

pub type Node {
  Node(id: String, all_node_ids: List(String), msg_counter: Int)
}

pub type Command {
  InitializeNode(node_id: String, all_node_ids: List(String))
  GetNodeId(reply_to: Subject(String))
  GetNextMsgId(reply_to: Subject(Int))
}

pub fn handler(command: Command, node: Node) {
  case command {
    InitializeNode(node_id, all_node_ids) -> {
      let initialized_node =
        Node(id: node_id, all_node_ids: all_node_ids, msg_counter: 0)
      actor.continue(initialized_node)
    }
    GetNodeId(reply_to) -> {
      process.send(reply_to, node.id)
      actor.continue(node)
    }
    GetNextMsgId(reply_to) -> {
      process.send(reply_to, node.msg_counter)
      let updated_node = Node(..node, msg_counter: node.msg_counter + 1)
      actor.continue(updated_node)
    }
  }
}
