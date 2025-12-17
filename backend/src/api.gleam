import context
import db
import gleam/bool
import gleam/dynamic/decode
import gleam/json
import gleam/option.{Some}
import gleam/result
import log
import project
import tag
import task
import user
import wisp

fn login_middleware_(
  ctx: context.Context,
  req: wisp.Request,
  callback: fn(context.Context, wisp.Request) -> Result(wisp.Response, Nil),
) -> Result(wisp.Response, Nil) {
  let token = req |> wisp.get_cookie("login", wisp.Signed)
  use token <- result.try(token)
  let user = db.user_fetch_from_token(ctx, token)
  use user <- result.try(user)
  let ctx = context.Context(..ctx, user: Some(user))
  callback(ctx, req)
  |> result.map(wisp.set_cookie(_, req, "login", token, wisp.Signed, 60 * 60))
}

pub fn login_middleware(
  ctx: context.Context,
  req: wisp.Request,
  callback: fn(context.Context, wisp.Request) -> Result(wisp.Response, Nil),
) -> Result(wisp.Response, Nil) {
  login_middleware_(ctx, req, callback)
  |> log.on_error(ctx, "user is not logged in")
  |> result.unwrap(wisp.response(401))
  |> Ok
}

pub fn admin_middleware(
  ctx: context.Context,
  callback: fn() -> Result(wisp.Response, Nil),
) {
  let is_admin =
    ctx.user
    |> option.to_result(Nil)
    |> log.on_error(ctx, "user is not logged in")
    |> result.map(fn(user) { user.name == "admin" })
    |> result.unwrap(False)

  log.info(ctx, "user is admin: " <> bool.to_string(is_admin))

  case is_admin {
    True -> callback()
    False -> wisp.response(401) |> Ok
  }
}

pub fn api(
  ctx: context.Context,
  req: wisp.Request,
  path: List(String),
) -> Result(wisp.Response, Nil) {
  use ctx, req <- login_middleware(ctx, req)
  log.info(ctx, "api request")

  case path {
    ["myself"] -> myself(ctx)
    // Project
    ["project", "fetch", "all"] -> project_fetch_all(ctx, req)
    ["project", "new"] -> project_new(ctx, req)
    ["project", "update"] -> project_update(ctx, req)
    ["project", "delete"] -> project_delete(ctx, req)

    // Tag
    ["tag", "fetch", "all"] -> tag_fetch_all(ctx, req)
    ["tag", "new"] -> tag_new(ctx, req)
    ["tag", "update"] -> tag_update(ctx, req)
    ["tag", "delete"] -> tag_delete(ctx, req)

    // Task
    ["task", "fetch", "all"] -> task_fetch_all(ctx, req)
    ["task", "new"] -> task_new(ctx, req)
    ["task", "update"] -> task_update(ctx, req)
    ["task", "delete"] -> task_delete(ctx, req)

    // User
    ["user", "fetch", "all"] -> user_fetch_all(ctx, req)
    ["user", "new"] -> user_new(ctx, req)
    ["user", "update"] -> user_update(ctx, req)
    ["user", "delete"] -> user_delete(ctx, req)
    _ -> wisp.not_found() |> Ok
  }
}

fn myself(ctx: context.Context) -> Result(wisp.Response, Nil) {
  ctx.user
  |> option.to_result(Nil)
  |> log.on_error(ctx, "user is not logged in")
  |> result.map(user.to_json)
  |> result.map(response_from_json)
}

fn response_from_json(json: json.Json) -> wisp.Response {
  json
  |> json.to_string
  |> wisp.json_response(200)
}

fn user_delete(
  ctx: context.Context,
  req: wisp.Request,
) -> Result(wisp.Response, Nil) {
  use <- admin_middleware(ctx)
  todo
}

fn user_update(
  ctx: context.Context,
  req: wisp.Request,
) -> Result(wisp.Response, Nil) {
  use <- admin_middleware(ctx)
  todo
}

fn user_new(
  ctx: context.Context,
  req: wisp.Request,
) -> Result(wisp.Response, Nil) {
  use <- admin_middleware(ctx)
  todo
}

fn user_fetch_all(
  ctx: context.Context,
  _: wisp.Request,
) -> Result(wisp.Response, Nil) {
  db.user_fetch_all(ctx)
  |> log.on_error(ctx, "could not fetch all users")
  |> result.map(json.array(_, user.to_json))
  |> result.map(response_from_json)
}

fn parse_request_body(
  ctx: context.Context,
  req: wisp.Request,
  decoder: decode.Decoder(a),
) -> Result(a, Nil) {
  let body =
    req
    |> wisp.read_body_bits()
    |> log.on_error(ctx, "could not read request body")
  use body <- result.try(body)

  body
  |> json.parse_bits(decoder)
  |> result.replace_error(Nil)
  |> log.on_error(ctx, "could not parse request body")
}

fn task_delete(
  ctx: context.Context,
  req: wisp.Request,
) -> Result(wisp.Response, Nil) {
  parse_request_body(ctx, req, task.id_decoder())
  |> result.map(db.task_delete(ctx, _))
  |> result.replace(wisp.ok())
}

fn task_update(
  ctx: context.Context,
  req: wisp.Request,
) -> Result(wisp.Response, Nil) {
  parse_request_body(ctx, req, task.json_decoder())
  |> result.map(db.task_update(ctx, _))
  |> log.on_error(ctx, "could not update task")
  |> result.replace(wisp.ok())
}

fn task_new(
  ctx: context.Context,
  req: wisp.Request,
) -> Result(wisp.Response, Nil) {
  parse_request_body(ctx, req, task.json_decoder())
  |> result.try(db.task_insert(ctx, _))
  |> result.map(task.to_json)
  |> result.map(response_from_json)
  |> log.on_error(ctx, "could not create new task")
}

fn task_fetch_all(
  ctx: context.Context,
  _: wisp.Request,
) -> Result(wisp.Response, Nil) {
  ctx.user
  |> option.to_result(Nil)
  |> log.on_error(ctx, "no logged in user present")
  |> result.map(fn(user) { user.id })
  |> result.try(db.task_fetch_all_for_user(ctx, _))
  |> result.map(json.array(_, task.to_json))
  |> result.map(response_from_json)
  |> log.on_error(ctx, "could not fetch tasks")
}

fn tag_delete(
  ctx: context.Context,
  req: wisp.Request,
) -> Result(wisp.Response, Nil) {
  parse_request_body(ctx, req, tag.id_decoder())
  |> result.try(db.tag_delete(ctx, _))
  |> log.on_error(ctx, "could not delete tag")
  |> result.replace(wisp.ok())
}

fn tag_update(
  ctx: context.Context,
  req: wisp.Request,
) -> Result(wisp.Response, Nil) {
  parse_request_body(ctx, req, tag.json_decoder())
  |> result.try(db.tag_update(ctx, _))
  |> log.on_error(ctx, "could not update tag")
  |> result.replace(wisp.ok())
}

fn tag_new(
  ctx: context.Context,
  req: wisp.Request,
) -> Result(wisp.Response, Nil) {
  parse_request_body(ctx, req, tag.json_decoder())
  |> result.try(db.tag_insert(ctx, _))
  |> result.map(tag.to_json)
  |> result.map(response_from_json)
  |> log.on_error(ctx, "could not create new tag")
}

fn tag_fetch_all(
  ctx: context.Context,
  _: wisp.Request,
) -> Result(wisp.Response, Nil) {
  ctx.user
  |> option.to_result(Nil)
  |> log.on_error(ctx, "user not logged in")
  |> result.map(fn(user) { user.id })
  |> result.try(db.tag_fetch_all(ctx, _))
  |> result.map(json.array(_, tag.to_json))
  |> result.map(response_from_json)
  |> log.on_error(ctx, "could not fetch all tags")
}

fn project_delete(
  ctx: context.Context,
  req: wisp.Request,
) -> Result(wisp.Response, Nil) {
  parse_request_body(ctx, req, project.id_decoder())
  |> result.try(db.project_delete(ctx, _))
  |> result.replace(wisp.ok())
  |> log.on_error(ctx, "could not delete project")
}

fn project_update(
  ctx: context.Context,
  req: wisp.Request,
) -> Result(wisp.Response, Nil) {
  parse_request_body(ctx, req, project.json_decoder())
  |> result.try(db.project_update(ctx, _))
  |> result.replace(wisp.ok())
  |> log.on_error(ctx, "could not update project")
}

fn project_new(
  ctx: context.Context,
  req: wisp.Request,
) -> Result(wisp.Response, Nil) {
  parse_request_body(ctx, req, project.json_decoder())
  |> result.try(db.project_insert(ctx, _))
  |> result.map(project.to_json)
  |> result.map(response_from_json)
  |> log.on_error(ctx, "could not create new project")
}

fn project_fetch_all(
  ctx: context.Context,
  _: wisp.Request,
) -> Result(wisp.Response, Nil) {
  ctx.user
  |> option.to_result(Nil)
  |> result.map(fn(user) { user.id })
  |> result.try(db.project_fetch_all_for_user(ctx, _))
  |> result.map(json.array(_, project.to_json))
  |> result.map(response_from_json)
  |> log.on_error(ctx, "could not fetch all projects")
}
