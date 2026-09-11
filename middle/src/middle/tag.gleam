import gleam/dynamic/decode
import gleam/json
import gleam/result
import middle/cached
import middle/id.{type ID}

pub type Tag {
  Tag(id: ID(Tag), name: String)
}

pub fn to_string(tag: Tag) {
  tag.name
}

pub fn to_json(tag: Tag) {
  [#("id", id.to_json(tag.id)), #("name", json.string(tag.name))]
  |> json.object()
}

pub fn decode_json() {
  use id <- decode.field("id", id.decode())
  use name <- decode.field("name", decode.string)
  Tag(id:, name:)
  |> decode.success
}

pub fn to_cached(t) {
  t
  |> to_json
  |> json.to_string()
  |> cached.from_string()
}

pub fn from_cached(t) {
  t
  |> cached.to_string()
  |> json.parse(decode_json())
  |> result.replace_error(Nil)
}
