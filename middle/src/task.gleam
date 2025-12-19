import gleam/dynamic/decode
import gleam/json

pub type Id {
  Id(inner: String)
}

pub type Task {
  Task(id: Id, title: String, body: String)
}

pub fn id_to_json(id: Id) {
  id.inner |> json.string
}

pub fn id_json_decoder() {
  use id <- decode.then(decode.string)
  id |> Id |> decode.success
}

pub fn to_json(task: Task) {
  [
    #("id", task.id |> id_to_json),
    #("title", task.title |> json.string),
    #("body", task.body |> json.string),
  ]
  |> json.object()
}

pub fn json_decoder() {
  use id <- decode.field("id", id_json_decoder())
  use title <- decode.field("title", decode.string)
  use body <- decode.field("body", decode.string)
  Task(id:, title:, body:) |> decode.success
}
