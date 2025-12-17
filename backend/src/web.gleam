import api
import beecrypt
import context
import db
import gleam/bool
import gleam/dynamic/decode
import gleam/int
import gleam/json
import gleam/result
import log
import wisp

pub fn handle_request(ctx: context.Context, req: wisp.Request) {
  use ctx, req <- middleware(ctx, req)
  case wisp.path_segments(req) {
    ["api", "login"] -> login(ctx, req)
    ["api", ..tail] -> api.api(ctx, req, tail)
    _ -> wisp.not_found() |> Ok
  }
  |> result.unwrap(wisp.internal_server_error())
}

fn login(ctx: context.Context, req: wisp.Request) -> Result(wisp.Response, Nil) {
  let body =
    req
    |> wisp.read_body_bits()
    |> log.on_error(ctx, "could not read request body")
  use body <- result.try(body)

  let body =
    body
    |> json.parse_bits({
      use name <- decode.field("name", decode.string)
      use password <- decode.field("password", decode.string)
      #(name, password)
      |> decode.success()
    })
    |> result.replace_error(Nil)
    |> log.on_error(ctx, "could not parse request body")

  use body <- result.try(body)
  let #(name, password) = body

  let login_data =
    db.user_fetch_login_data_from_name(ctx, name)
    |> log.on_error(ctx, "could not fetch login data")
  use login_data <- result.try(login_data)
  let #(hash, token) = login_data

  let is_verified = beecrypt.verify(password, hash)
  use <- bool.guard(when: !is_verified, return: Error(Nil))

  wisp.ok()
  |> wisp.set_cookie(req, "login", token, wisp.Signed, 60 * 60)
  |> Ok
}

fn middleware(
  ctx: context.Context,
  req: wisp.Request,
  callback: fn(context.Context, wisp.Request) -> wisp.Response,
) -> wisp.Response {
  log.info(ctx, "requets: " <> req.path)

  let response = callback(ctx, req)
  log.info(ctx, "request completed: " <> int.to_string(response.status))
  response
}
