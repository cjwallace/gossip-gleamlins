/// An actor for storing maelstrom node state:
/// - the node Id
/// - the Ids of all nodes in the network,
/// - and the network topology.
import gleam/dict.{type Dict}
import gleam/erlang/process.{type Subject}
import gleam/otp/actor

pub type Node {
  Node(
    id: String,
    all_node_ids: List(String),
    msg_counter: Int,
    topology: Dict(String, List(String)),
  )
}

pub type Command {
  InitializeNode(
    reply_with: Subject(String),
    node_id: String,
    all_node_ids: List(String),
  )
  SetTopology(topology: Dict(String, List(String)))
  GetNodeId(reply_with: Subject(String))
  GetNextMsgId(reply_with: Subject(Int))
  GetNeighbours(reply_with: Subject(List(String)))
}

fn handler(command: Command, node: Node) {
  case command {
    InitializeNode(reply_with, node_id, all_node_ids) -> {
      let initialized_node = Node(..node, id: node_id, all_node_ids:)
      process.send(reply_with, initialized_node.id)
      actor.continue(initialized_node)
    }
    SetTopology(topology) -> {
      let new_node = Node(..node, topology:)
      actor.continue(new_node)
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
    GetNeighbours(reply_with) -> {
      let neighbours = dict.get(node.topology, node.id)
      case neighbours {
        Ok(neighbours) -> process.send(reply_with, neighbours)
        Error(_) -> process.send(reply_with, [])
      }
      actor.continue(node)
    }
  }
}

pub fn new() {
  let assert Ok(node) =
    actor.start(
      Node(id: "", all_node_ids: [], msg_counter: 0, topology: dict.new()),
      handler,
    )
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

pub fn set_topology(
  node_state: Subject(Command),
  topology: Dict(String, List(String)),
) {
  actor.send(node_state, SetTopology(topology))
}

pub fn get_neighbours(node_state: Subject(Command)) {
  actor.call(node_state, GetNeighbours, 100)
}
