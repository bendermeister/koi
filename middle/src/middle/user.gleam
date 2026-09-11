import gleam/dynamic/decode
import gleam/json
import gleam/pair
import middle/id.{type ID}

pub type User {
  User(id: ID(User), name: String, email: String)
}

pub fn to_json(user: User) {
  [
    user.id |> id.to_json() |> pair.new("id", _),
    user.name |> json.string |> pair.new("name", _),
    user.email |> json.string |> pair.new("email", _),
  ]
  |> json.object()
}

pub fn decode_json() {
  use id <- decode.field("id", id.decode())
  use name <- decode.field("name", decode.string)
  use email <- decode.field("email", decode.string)
  User(id:, name:, email:)
  |> decode.success()
}
