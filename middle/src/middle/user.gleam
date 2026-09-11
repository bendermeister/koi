import gleam/dynamic/decode
import gleam/json
import gleam/pair
import gleam/result
import middle/cached
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

pub fn to_cached(u) {
  u |> to_json |> json.to_string |> cached.from_string
}

pub fn from_cached(u) {
  u
  |> cached.to_string
  |> json.parse(decode_json())
  |> result.replace_error(Nil)
}
