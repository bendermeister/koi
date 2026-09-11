import gleam/dynamic/decode
import gleam/json

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
