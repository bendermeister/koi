import gleam/bool
import middle/cached.{type Cached}

@external(javascript, "./cache.js", "cache_get")
fn get_internal(key: String) -> String

@external(javascript, "./cache.js", "cache_set")
fn set_internal(key: String, value: String) -> Nil

pub fn set(key: String, value: Cached) {
  set_internal(key, value |> cached.to_string)
}

pub fn get(
  key: String,
  handler: fn(Cached) -> Result(a, Nil),
) -> Result(a, Nil) {
  let value = get_internal(key)
  use <- bool.guard(when: value == "", return: Error(Nil))
  value
  |> cached.from_string
  |> handler
}

pub fn delete(key) {
  set_internal(key, "")
}
