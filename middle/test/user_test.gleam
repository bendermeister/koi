import gleam/json
import user

pub fn id_to_from_json_test() {
  let id = user.Id("user id")
  let assert Ok(out) =
    id
    |> user.id_to_json()
    |> json.to_string
    |> json.parse(user.id_json_decoder())
  assert out == id
}

pub fn token_to_from_json_test() {
  let token = user.Token("user token")
  let assert Ok(out) =
    token
    |> user.token_to_json()
    |> json.to_string
    |> json.parse(user.token_json_decoder())
  assert out == token
}

pub fn password_to_from_json_test() {
  let password = user.Password("userpassword")
  let assert Ok(out) =
    password
    |> user.password_to_json()
    |> json.to_string
    |> json.parse(user.password_json_decoder())
  assert out == password
}

pub fn user_to_from_json_test() {
  let user = user.User(id: user.Id("user id"), name: "name user")
  let assert Ok(out) =
    user
    |> user.to_json()
    |> json.to_string
    |> json.parse(user.json_decoder())
  assert out == user
}
