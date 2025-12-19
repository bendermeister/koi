import date.{Dec, Feb, Jan, Mar}
import gleam/json
import gleam/option.{Some}
import task
import time

pub fn to_from_json_test() {
  let task =
    task.Task(
      id: task.Id("task id"),
      title: "title",
      body: "body",
      opened: date.Date(2025, Dec, 2),
      closed: Some(date.Date(2026, Mar, 4)),
      scheduled: Some(date.Date(2027, Feb, 5)),
      scheduled_start: Some(time.Time(1, 2)),
      scheduled_end: Some(time.Time(3, 4)),
      deadline: Some(date.Date(2028, Jan, 8)),
      deadline_time: Some(time.Time(6, 7)),
    )
  let assert Ok(out) =
    task
    |> task.to_json()
    |> json.to_string
    |> json.parse(task.json_decoder())
  assert out == task
}
