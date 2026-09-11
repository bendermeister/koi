import gleam/json
import middle/id.{ID}
import middle/user.{User}

pub fn to_from_json_test() {
  let user = User(id: ID("user_id"), name: "Hans", email: "hans@email.com")

  let assert Ok(out) =
    user
    |> user.to_json()
    |> json.to_string
    |> json.parse(user.decode_json())

  assert out == user
}
