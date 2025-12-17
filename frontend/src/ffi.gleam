import gleam/list
import gleam/pair
import gleam/result
import gleam/string

@external(javascript, "./ffi.js", "get_cookies")
fn get_cookies_() -> String

@external(javascript, "./ffi.js", "set_cookie")
pub fn set_cookie(key: String, value: String) -> Nil

pub fn get_cookies() {
  get_cookies_()
  |> string.split(";")
  |> list.map(string.split_once(_, "="))
  |> result.partition()
  |> pair.first()
}
