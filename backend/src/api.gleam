import api_spec
import context
import date
import db
import gleam/http
import gleam/int
import gleam/json
import gleam/option.{None, Some}
import gleam/result
import log
import task
import user
import wisp
import youid/uuid

type Handler =
  fn(context.Context, wisp.Request) -> wisp.Response

fn authentication_middleware_(
  ctx: context.Context,
  req: wisp.Request,
  handler: Handler,
) -> Result(wisp.Response, Nil) {
  let token =
    wisp.get_cookie(req, "token", wisp.Signed)
    |> log.on_error(ctx, "could not read 'token' cookie")
  use token <- result.try(token)

  let token =
    uuid.from_string(token)
    |> log.on_error(ctx, "token is not a valid uuid")
  use token <- result.try(token)

  let user =
    db.user_fetch_from_token(ctx, token)
    |> log.on_error(ctx, "could not fetch user from database")
  use user <- result.try(user)

  let ctx = context.Context(..ctx, user: Some(user))
  handler(ctx, req)
  |> wisp.set_cookie(req, "token", uuid.to_string(token), wisp.Signed, 60 * 60)
  |> Ok
}

fn authentication_middleware(ctx: context.Context, req: wisp.Request, handler) {
  let redirect = fn() {
    let scheme = case req.scheme {
      http.Http -> "http://"
      http.Https -> "https://"
    }
    let host = req.host
    let port =
      req.port
      |> option.map(fn(port) { ":" <> int.to_string(port) })
      |> option.unwrap("")
    wisp.redirect(to: scheme <> host <> port <> "/login")
  }

  authentication_middleware_(ctx, req, handler)
  |> log.on_error(ctx, "user is not logged in -> redirected")
  |> result.lazy_unwrap(redirect)
}

fn ctx_user(ctx: context.Context) {
  ctx.user
  |> option.to_result(Nil)
  |> log.on_error(ctx, "user is not logged in")
}

pub fn api(ctx: context.Context, req: wisp.Request, path: List(String)) {
  use ctx, req <- authentication_middleware(ctx, req)
  let path = ["api", ..path]

  {
    let route = api_spec.route_from_path(path)
    case route {
      api_spec.TaskNew -> task_new(ctx, req)
      api_spec.TaskUpdate -> task_update(ctx, req)
      api_spec.TaskDelete -> task_delete(ctx, req)
      api_spec.Inbox -> inbox(ctx, req)
      api_spec.Agenda -> agenda(ctx, req)
      api_spec.Open -> open(ctx, req)
      api_spec.NotFound -> wisp.not_found() |> Ok
    }
  }
  |> result.unwrap(wisp.internal_server_error())
}

fn endpoint_wrapper(
  endpoint: api_spec.Endpoint(parameter, return),
  ctx: context.Context,
  req: wisp.Request,
  handler: fn(user.User, parameter) -> Result(return, Nil),
) -> Result(wisp.Response, Nil) {
  let #(decoder, encoder) = api_spec.receive_request(endpoint)

  let parameter = parse_request_body(ctx, req, decoder())
  use parameter <- result.try(parameter)

  let user = ctx_user(ctx)
  use user <- result.try(user)

  handler(user, parameter)
  |> result.map(encoder)
  |> result.map(response_from_json)
}

fn agenda(ctx, req) {
  use owner, range <- endpoint_wrapper(api_spec.agenda, ctx, req)
  db.task_fetch_agenda(ctx, owner, range)
  |> log.on_error(ctx, "could not fetch agenda")
}

fn response_from_json(json) {
  json
  |> json.to_string
  |> wisp.json_response(200)
}

fn inbox(ctx: context.Context, req: wisp.Request) {
  use owner, _ <- endpoint_wrapper(api_spec.inbox, ctx, req)
  db.task_fetch_inbox(ctx, owner)
  |> log.on_error(ctx, "could not fetch inbox")
}

fn task_new(ctx: context.Context, req: wisp.Request) {
  use owner, _ <- endpoint_wrapper(api_spec.task_new, ctx, req)

  let task =
    task.Task(
      id: uuid.v4() |> uuid.to_string |> task.Id,
      title: "new task",
      body: "",
      opened: date.now(),
      closed: None,
      scheduled: None,
      scheduled_start: None,
      scheduled_end: None,
      deadline: None,
      deadline_time: None,
    )

  let result =
    db.task_insert(ctx, owner, task)
    |> log.on_error(ctx, "could not insert new task")
  use _ <- result.try(result)

  Ok(task)
}

fn parse_request_body(ctx: context.Context, req: wisp.Request, decoder) {
  let body =
    wisp.read_body_bits(req)
    |> log.on_error(ctx, "could not read request body")
  use body <- result.try(body)

  body
  |> json.parse_bits(decoder)
  |> log.on_error(ctx, "could not parse request body")
  |> result.replace_error(Nil)
}

fn task_update(ctx: context.Context, req: wisp.Request) {
  use _, task <- endpoint_wrapper(api_spec.task_update, ctx, req)
  db.task_update(ctx, task)
}

fn task_delete(ctx: context.Context, req: wisp.Request) {
  use _, task <- endpoint_wrapper(api_spec.task_delete, ctx, req)
  db.task_delete(ctx, task)
  |> log.on_error(ctx, "could not delete task")
}

fn open(ctx: context.Context, req: wisp.Request) {
  use owner, _ <- endpoint_wrapper(api_spec.open, ctx, req)
  db.task_fetch_open(ctx, owner)
  |> log.on_error(ctx, "could not fetch open tasks")
}
