import gleam/json
import middle/token.{Token}

pub fn to_from_json_test() {
  let token = Token("token")

  let assert Ok(out) =
    token
    |> token.to_json()
    |> json.to_string
    |> json.parse(token.decode())

  assert out == token
}
