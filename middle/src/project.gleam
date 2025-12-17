import gleam/dynamic/decode
import gleam/json
import user

pub type Id {
  Id(inner: String)
}

pub type Project {
  Project(id: Id, name: String, owner: user.Id)
}

pub fn id_to_json(id: Id) {
  id.inner |> json.string
}

pub fn id_decoder() {
  use id <- decode.then(decode.string)
  id |> Id |> decode.success
}

pub fn to_json(project: Project) {
  [
    #("id", project.id |> id_to_json),
    #("name", project.name |> json.string),
    #("owner", project.owner |> user.id_to_json),
  ]
  |> json.object()
}

pub fn json_decoder() {
  use id <- decode.field("id", id_decoder())
  use name <- decode.field("name", decode.string)
  use owner <- decode.field("owner", user.id_decoder())
  Project(id:, name:, owner:)
  |> decode.success()
}
