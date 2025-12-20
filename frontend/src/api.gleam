import api_spec
import date
import gleam/result
import lustre/effect
import rsvp
import task

fn endpoint_wrapper(
  endpoint: api_spec.Endpoint(parameter, return),
  parameter: parameter,
  ok: fn(return) -> message,
  error: message,
) -> effect.Effect(message) {
  let #(route, encoder, decoder) = api_spec.make_request(endpoint)

  rsvp.expect_json(decoder(), fn(response) {
    response
    |> result.map(ok)
    |> result.unwrap(error)
  })
  |> rsvp.post(route, encoder(parameter), _)
}

pub fn agenda(
  date_range: date.Range,
  ok: fn(List(task.Task)) -> message,
  error: fn(String) -> message,
) -> effect.Effect(message) {
  endpoint_wrapper(
    api_spec.agenda,
    date_range,
    ok,
    error("could not load agenda"),
  )
}

pub fn inbox(
  ok: fn(List(task.Task)) -> a,
  error: fn(String) -> a,
) -> effect.Effect(a) {
  endpoint_wrapper(api_spec.inbox, Nil, ok, error("could not load inbox"))
}

pub fn open(
  ok: fn(List(task.Task)) -> a,
  error: fn(String) -> a,
) -> effect.Effect(a) {
  endpoint_wrapper(api_spec.open, Nil, ok, error("could not load open"))
}

pub fn task_new(
  ok: fn(task.Task) -> a,
  error: fn(String) -> a,
) -> effect.Effect(a) {
  endpoint_wrapper(
    api_spec.task_new,
    Nil,
    ok,
    error("could not create new task"),
  )
}

pub fn task_update(task, ok, error) {
  let ok = fn(_) { ok("task updated") }
  let error = error("could not update task")
  endpoint_wrapper(api_spec.task_update, task, ok, error)
}

pub fn task_delete(task, ok, error) {
  let ok = fn(_) { ok("task deleted") }
  let error = error("could not delete task")
  endpoint_wrapper(api_spec.task_delete, task, ok, error)
}
