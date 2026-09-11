import gleam/dynamic/decode
import gleam/json
import middle/cached

pub type ID(a) {
  ID(inner: String)
}

pub fn to_string(id: ID(a)) {
  id.inner
}

pub fn from_string(id: String) {
  ID(id)
}

pub fn to_json(id: ID(a)) {
  id.inner |> json.string
}

pub fn decode() {
  decode.string
  |> decode.map(from_string)
}

pub fn to_cached(id) {
  id |> to_string |> cached.from_string
}

pub fn from_cached(id) {
  id |> cached.to_string |> from_string |> Ok
}
