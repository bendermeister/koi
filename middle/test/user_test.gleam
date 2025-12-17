import gleam/json
import user

pub fn to_from_json_test() {
  let user = user.User(id: user.Id("asdf"), name: "lkjsd")

  let assert Ok(out) =
    user
    |> user.to_json()
    |> json.to_string()
    |> json.parse(user.json_decoder())

  assert out == user
}
