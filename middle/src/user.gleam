import gleam/dynamic/decode
import gleam/json

pub type Id {
  Id(inner: String)
}

pub type User {
  User(id: Id, name: String)
}

pub fn id_to_string(id: Id) {
  id.inner
}

pub fn id_to_json(id: Id) {
  id.inner |> json.string
}

pub fn to_json(user: User) {
  [#("id", user.id |> id_to_json), #("name", user.name |> json.string)]
  |> json.object()
}

pub fn id_decoder() {
  use id <- decode.then(decode.string)
  id |> Id |> decode.success()
}

pub fn json_decoder() {
  use id <- decode.field("id", id_decoder())
  use name <- decode.field("name", decode.string)
  User(id:, name:) |> decode.success()
}
