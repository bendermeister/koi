import gleam/json
import middle/id.{ID}

pub fn to_from_json_test() {
  let id = ID("id")

  let assert Ok(out) =
    id
    |> id.to_json()
    |> json.to_string()
    |> json.parse(id.decode())

  assert out == id
}
