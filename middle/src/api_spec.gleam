import date
import gleam/dynamic/decode
import gleam/json
import gleam/result
import task

pub type Route {
  TaskNew
  TaskUpdate
  TaskDelete
  Inbox
  Agenda
  Open
  NotFound
}

pub fn route_to_string(route: Route) {
  case route {
    TaskNew -> "/api/task/new"
    TaskUpdate -> "/api/task/update"
    TaskDelete -> "/api/task/delete"
    Inbox -> "/api/inbox"
    Agenda -> "/api/agenda"
    Open -> "/api/open"
    NotFound -> "/api/404"
  }
}

pub fn route_from_path(path: List(String)) {
  case path {
    ["api", "task", "new"] -> Ok(TaskNew)
    ["api", "task", "update"] -> Ok(TaskUpdate)
    ["api", "task", "delete"] -> Ok(TaskDelete)
    ["api", "inbox"] -> Ok(Inbox)
    ["api", "agenda"] -> Ok(Agenda)
    ["api", "open"] -> Ok(Open)
    _ -> Error(Nil)
  }
  |> result.unwrap(NotFound)
}

pub type Argument(a) {
  Argument(encoder: fn(a) -> json.Json, decoder: fn() -> decode.Decoder(a))
}

pub fn nil_encoder(_) {
  json.null()
}

pub fn nil_decoder() {
  decode.success(Nil)
}

pub const nil_argument = Argument(encoder: nil_encoder, decoder: nil_decoder)

pub const task_argument = Argument(
  encoder: task.to_json,
  decoder: task.json_decoder,
)

pub fn task_list_encoder(list) {
  json.array(list, task.to_json)
}

pub fn task_list_decoder() {
  decode.list(task.json_decoder())
}

pub const task_list_argument = Argument(
  encoder: task_list_encoder,
  decoder: task_list_decoder,
)

pub const date_range_argument = Argument(
  encoder: date.range_to_json,
  decoder: date.range_json_decoder,
)

pub type Endpoint(parameter, return) {
  Endpoint(
    route: Route,
    parameter: Argument(parameter),
    return: Argument(return),
  )
}

pub const task_new = Endpoint(
  route: TaskNew,
  parameter: nil_argument,
  return: task_argument,
)

pub const task_update = Endpoint(
  route: TaskUpdate,
  parameter: task_argument,
  return: nil_argument,
)

pub const task_delete = Endpoint(
  route: TaskDelete,
  parameter: task_argument,
  return: nil_argument,
)

pub const inbox = Endpoint(
  route: Inbox,
  parameter: nil_argument,
  return: task_list_argument,
)

pub const open = Endpoint(
  route: Open,
  parameter: nil_argument,
  return: task_list_argument,
)

pub const agenda = Endpoint(
  route: Open,
  parameter: date_range_argument,
  return: task_list_argument,
)

pub fn make_request(
  endpoint: Endpoint(parameter, return),
) -> #(String, fn(parameter) -> json.Json, fn() -> decode.Decoder(return)) {
  let route = endpoint.route |> route_to_string
  let encoder = endpoint.parameter.encoder
  let decoder = endpoint.return.decoder
  #(route, encoder, decoder)
}

pub fn receive_request(endpoint: Endpoint(parameter, return)) {
  let decoder = endpoint.parameter.decoder
  let encoder = endpoint.return.encoder
  #(decoder, encoder)
}
