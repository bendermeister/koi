import date
import gleam/dynamic/decode
import gleam/json
import gleam/option
import time

pub type Id {
  Id(inner: String)
}

pub type Task {
  Task(
    id: Id,
    title: String,
    body: String,
    opened: date.Date,
    closed: option.Option(date.Date),
    scheduled: option.Option(date.Date),
    scheduled_start: option.Option(time.Time),
    scheduled_end: option.Option(time.Time),
    deadline: option.Option(date.Date),
    deadline_time: option.Option(time.Time),
  )
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
    #("opened", task.opened |> date.to_json),
    #("closed", task.closed |> json.nullable(date.to_json)),
    #("scheduled", task.scheduled |> json.nullable(date.to_json)),
    #("scheduled_start", task.scheduled_start |> json.nullable(time.to_json)),
    #("scheduled_end", task.scheduled_end |> json.nullable(time.to_json)),
    #("deadline", task.deadline |> json.nullable(date.to_json)),
    #("deadline_time", task.deadline_time |> json.nullable(time.to_json)),
  ]
  |> json.object()
}

pub fn json_decoder() {
  use id <- decode.field("id", id_json_decoder())
  use title <- decode.field("title", decode.string)
  use body <- decode.field("body", decode.string)

  use opened <- decode.field("opened", date.decoder())
  use closed <- decode.field("closed", decode.optional(date.decoder()))
  use scheduled <- decode.field("scheduled", decode.optional(date.decoder()))
  use scheduled_start <- decode.field(
    "scheduled_start",
    decode.optional(time.decoder()),
  )
  use scheduled_end <- decode.field(
    "scheduled_end",
    decode.optional(time.decoder()),
  )
  use deadline <- decode.field("deadline", decode.optional(date.decoder()))
  use deadline_time <- decode.field(
    "deadline_time",
    decode.optional(time.decoder()),
  )
  Task(
    id:,
    title:,
    body:,
    opened:,
    closed:,
    scheduled:,
    scheduled_start:,
    scheduled_end:,
    deadline:,
    deadline_time:,
  )
  |> decode.success
}
