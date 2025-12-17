import gleam/json
import project
import user

pub fn to_from_json_test() {
  let project =
    project.Project(
      id: project.Id("project id"),
      name: "project name",
      owner: user.Id("user id"),
    )

  let assert Ok(out) =
    project
    |> project.to_json()
    |> json.to_string
    |> json.parse(project.json_decoder())

  assert out == project
}
