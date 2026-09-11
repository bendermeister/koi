import birl.{type Time}
import gleam/dynamic/decode
import gleam/json
import gleam/option.{type Option}
import gleam/result
import middle/cached
import middle/id
import middle/tag.{type Tag}

pub type Task {
  Task(
    id: id.ID(Task),
    title: String,
    body: String,
    tags: List(Tag),
    opened: Time,
    closed: Option(Time),
  )
}

pub fn to_json(task: Task) {
  [
    #("id", id.to_json(task.id)),
    #("title", json.string(task.title)),
    #("body", json.string(task.body)),
    #("tags", json.array(task.tags, tag.to_json)),
    #("opened", json.int(birl.to_unix(task.opened))),
    #(
      "closed",
      json.nullable(task.closed, fn(x) {
        x
        |> birl.to_unix
        |> json.int
      }),
    ),
  ]
  |> json.object()
}

pub fn decode_json() {
  use id <- decode.field("id", id.decode())
  use title <- decode.field("title", decode.string)
  use body <- decode.field("body", decode.string)
  use tags <- decode.field("tags", decode.list(tag.decode_json()))
  use opened <- decode.field("opened", {
    use x <- decode.then(decode.int)
    x
    |> birl.from_unix()
    |> decode.success()
  })
  use closed <- decode.field(
    "closed",
    decode.optional({
      use x <- decode.then(decode.int)
      x
      |> birl.from_unix
      |> decode.success
    }),
  )
  Task(id:, title:, body:, tags:, opened:, closed:)
  |> decode.success
}

pub fn to_cached(t) {
  t
  |> to_json
  |> json.to_string
  |> cached.from_string
}

pub fn from_cached(t) {
  t
  |> cached.to_string()
  |> json.parse(decode_json())
  |> result.replace_error(Nil)
}
