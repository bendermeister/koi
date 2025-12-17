import gleam/dynamic/decode
import gleam/json
import user

pub type Id {
  Id(inner: String)
}

pub type Tag {
  Tag(id: Id, name: String, owner: user.Id)
}

pub fn id_to_json(id: Id) {
  id.inner |> json.string
}

pub fn to_json(tag: Tag) {
  [
    #("id", tag.id |> id_to_json),
    #("name", tag.name |> json.string),
    #("owner", tag.owner |> user.id_to_json()),
  ]
  |> json.object()
}

pub fn id_decoder() {
  use id <- decode.then(decode.string)
  id |> Id |> decode.success()
}

pub fn json_decoder() {
  use id <- decode.field("id", id_decoder())
  use name <- decode.field("name", decode.string)
  use owner <- decode.field("owner", user.id_decoder())
  Tag(id:, name:, owner:)
  |> decode.success()
}
