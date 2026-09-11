import birl
import gleam/json
import gleam/option.{Some}
import middle/id.{ID}
import middle/tag
import middle/task.{Task}

fn now_unix() {
  birl.now()
  |> birl.to_unix()
  |> birl.from_unix()
}

pub fn to_from_json_test() {
  let task =
    Task(
      id: ID("someid"),
      title: "title",
      body: "body",
      opened: now_unix(),
      tags: [
        tag.Tag(id: ID("someid2"), name: "tag1"),
        tag.Tag(id: ID("someid3"), name: "tag2"),
      ],
      closed: Some(now_unix()),
    )

  let assert Ok(out) =
    task |> task.to_json |> json.to_string |> json.parse(task.decode_json())
  assert out == task
}

pub fn to_from_cached_test() {
  let task =
    Task(
      id: ID("someid"),
      title: "title",
      body: "body",
      opened: now_unix(),
      tags: [
        tag.Tag(id: ID("someid2"), name: "tag1"),
        tag.Tag(id: ID("someid3"), name: "tag2"),
      ],
      closed: Some(now_unix()),
    )

  let assert Ok(out) =
    task
    |> task.to_cached
    |> task.from_cached
  assert out == task
}
