import argv

import challenges/broadcast/main as broadcast
import challenges/echo_/main as echo_
import challenges/generate/main as generate

pub fn main() {
  case argv.load().arguments {
    ["echo", ..] -> echo_.main()
    ["generate", ..] -> generate.main()
    ["broadcast", ..] -> broadcast.main()
    _ -> Error("Invalid command")
  }
}
