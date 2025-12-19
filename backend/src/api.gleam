import context
import date
import db
import gleam/dynamic/decode
import gleam/http
import gleam/int
import gleam/json
import gleam/option.{None, Some}
import gleam/result
import log
import task
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
  {
    case path {
      ["inbox"] -> inbox(ctx, req)
      ["task", "new"] -> task_new(ctx, req)
      ["task", "update"] -> task_update(ctx, req)
      ["task", "delete"] -> task_delete(ctx, req)
      ["agenda"] -> agenda(ctx, req)
      _ -> wisp.not_found() |> Ok
    }
  }
  |> result.unwrap(wisp.internal_server_error())
}

fn agenda(ctx, req) {
  let user = ctx_user(ctx)
  use user <- result.try(user)

  let range = parse_request_body(ctx, req, date.range_json_decoder())
  use range <- result.try(range)

  let agenda =
    db.task_fetch_agenda(ctx, user, range)
    |> log.on_error(ctx, "could not fetch agenda")
  use agenda <- result.try(agenda)

  agenda
  |> json.array(task.to_json)
  |> response_from_json()
  |> Ok
}

fn response_from_json(json) {
  json
  |> json.to_string
  |> wisp.json_response(200)
}

fn inbox(ctx: context.Context, _: wisp.Request) {
  let user = ctx_user(ctx)
  use user <- result.try(user)

  db.task_fetch_inbox(ctx, user)
  |> log.on_error(ctx, "could not fetch inbox")
  |> result.map(json.array(_, task.to_json))
  |> result.map(response_from_json)
}

fn task_new(ctx: context.Context, _: wisp.Request) {
  let user = ctx_user(ctx)
  use user <- result.try(user)
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
    db.task_insert(ctx, user, task)
    |> log.on_error(ctx, "could not insert new task")
  use _ <- result.try(result)

  log.info(ctx, "new task created")

  task
  |> task.to_json
  |> response_from_json()
  |> Ok
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
  let task = parse_request_body(ctx, req, task.json_decoder())
  use task <- result.try(task)

  let result =
    db.task_update(ctx, task)
    |> log.on_error(ctx, "could not update task")

  use _ <- result.try(result)

  wisp.ok()
  |> Ok()
}

fn task_delete(ctx: context.Context, req: wisp.Request) {
  let task = parse_request_body(ctx, req, task.json_decoder())
  use task <- result.try(task)

  let result =
    db.task_delete(ctx, task)
    |> log.on_error(ctx, "could not delete task")
  use _ <- result.try(result)

  wisp.ok()
  |> Ok
}
