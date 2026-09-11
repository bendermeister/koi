pub type Cached {
  Cached(inner: String)
}

pub fn to_string(c: Cached) {
  c.inner
}

pub fn to_ok_string(c: Cached) {
  c |> to_string |> Ok
}

pub fn from_string(c: String) {
  Cached(c)
}

pub fn from_bool(c: Bool) {
  case c {
    True -> "true"
    False -> "false"
  }
  |> from_string()
}

pub fn to_bool(c) {
  let c = to_string(c)
  case c {
    "true" -> Ok(True)
    "false" -> Ok(False)
    _ -> Error(Nil)
  }
}
