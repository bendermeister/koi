import date_time
import gleam/dynamic/decode
import gleam/json
import gleam/option
import user

pub type Id {
  Id(inner: String)
}

pub type Task {
  Task(
    id: Id,
    owner: user.Id,
    title: String,
    opened: date_time.DateTime,
    closed: option.Option(date_time.DateTime),
    body: String,
  )
}

pub fn id_to_json(id: Id) {
  id.inner |> json.string
}

pub fn id_decoder() {
  use id <- decode.then(decode.string)
  id |> Id |> decode.success()
}

pub fn to_json(task: Task) {
  [
    #("id", task.id |> id_to_json),
    #("owner", task.owner |> user.id_to_json),
    #("title", task.title |> json.string),
    #("opened", task.opened |> date_time.to_json),
    #("closed", task.closed |> json.nullable(date_time.to_json)),
    #("body", task.body |> json.string),
  ]
  |> json.object()
}

pub fn json_decoder() {
  use id <- decode.field("id", id_decoder())
  use owner <- decode.field("owner", user.id_decoder())
  use title <- decode.field("title", decode.string)
  use opened <- decode.field("opened", date_time.decoder())
  use closed <- decode.field("closed", decode.optional(date_time.decoder()))
  use body <- decode.field("body", decode.string)
  Task(id:, owner:, title:, opened:, closed:, body:)
  |> decode.success()
}
