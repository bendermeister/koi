import gleam/json
import tag.{Tag}
import user

pub fn to_from_json_test() {
  let tag =
    Tag(id: tag.Id("tag id"), name: "tag name", owner: user.Id("user id"))

  let assert Ok(out) =
    tag |> tag.to_json() |> json.to_string |> json.parse(tag.json_decoder())
  assert out == tag
}
