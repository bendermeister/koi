import gleam/dynamic/decode
import gleam/json

pub type Id {
  Id(inner: String)
}

pub type User {
  User(id: Id, name: String)
}

pub type Token {
  Token(inner: String)
}

pub type Password {
  Password(inner: String)
}

pub fn id_to_json(id: Id) {
  id.inner |> json.string
}

pub fn id_json_decoder() {
  use id <- decode.then(decode.string)
  id |> Id |> decode.success
}

pub fn token_to_json(token: Token) {
  token.inner |> json.string
}

pub fn token_json_decoder() {
  decode.then(decode.string, fn(token) { token |> Token |> decode.success })
}

pub fn password_to_json(password: Password) {
  password.inner |> json.string
}

pub fn password_json_decoder() {
  decode.then(decode.string, fn(x) { x |> Password |> decode.success })
}

pub fn to_json(user: User) {
  [#("id", user.id |> id_to_json), #("name", user.name |> json.string)]
  |> json.object()
}

pub fn json_decoder() {
  use id <- decode.field("id", id_json_decoder())
  use name <- decode.field("name", decode.string)
  User(id:, name:)
  |> decode.success
}
