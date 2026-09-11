import gleam/dynamic/decode
import gleam/json

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
