import gleam/json
import task

pub fn to_from_json_test() {
  let task = task.Task(id: task.Id("task id"), title: "title", body: "body")
  let assert Ok(out) =
    task
    |> task.to_json()
    |> json.to_string
    |> json.parse(task.json_decoder())
  assert out == task
}
