import gleam/dynamic/decode
import gleam/json
import middle/cached

pub type Token {
  Token(inner: String)
}

pub fn to_string(token: Token) {
  token.inner
}

pub fn from_string(token: String) {
  Token(token)
}

pub fn to_json(token) {
  token
  |> to_string
  |> json.string
}

pub fn decode() {
  decode.string
  |> decode.map(from_string)
}

pub fn to_cached(t) {
  t |> to_string |> cached.from_string
}

pub fn from_cached(t) {
  t |> cached.to_string |> from_string |> Ok
}
