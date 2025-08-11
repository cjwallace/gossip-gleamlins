import argv

import challenges/batched_broadcast/main as batched_broadcast
import challenges/broadcast/main as broadcast
import challenges/echo_/main as echo_
import challenges/generate/main as generate

pub fn main() {
  case argv.load().arguments {
    ["echo", ..] -> echo_.main()
    ["generate", ..] -> generate.main()
    ["broadcast", ..] -> broadcast.main()
    ["batched_broadcast", ..] -> batched_broadcast.main()
    _ -> Error("Invalid command")
  }
}
