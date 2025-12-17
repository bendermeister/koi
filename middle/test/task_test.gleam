import date_time
import gleam/json
import gleam/option
import task.{Task}
import user

pub fn to_from_json_test() {
  let task =
    Task(
      id: task.Id("task id"),
      owner: user.Id("user id"),
      title: "Title",
      opened: date_time.now(),
      closed: option.Some(date_time.now()),
      body: "Body",
    )

  let assert Ok(got) =
    task
    |> task.to_json()
    |> json.to_string()
    |> json.parse(task.json_decoder())

  assert got == task
}
