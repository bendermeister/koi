import types.{type ID, ID}
import youid/uuid

pub fn new() -> ID(a) {
  uuid.v4()
  |> uuid.to_string()
  |> ID()
}

pub fn to_string(id: ID(a)) -> String {
  id.inner
}

pub fn from_string(id: String) -> ID(a) {
  id
  |> ID
}
