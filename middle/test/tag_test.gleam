import gleam/json
import middle/id.{ID}
import middle/tag.{Tag}

pub fn to_from_json_test() {
  let tag = Tag(id: ID("someid"), name: "sometag")

  let assert Ok(out) =
    tag
    |> tag.to_json
    |> json.to_string
    |> json.parse(tag.decode_json())

  assert out == tag
}

pub fn to_from_cached() {
  let tag = Tag(id: ID("someid"), name: "sometag")

  let assert Ok(out) =
    tag
    |> tag.to_cached()
    |> tag.from_cached()

  assert out == tag
}
