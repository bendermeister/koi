import auth_actor
import beecrypt
import db
import gleam/dynamic/decode
import gleam/json
import gleam/result
import gleam/string
import gleam/uri
import log
import middle/token
import middle/user.{User}
import types.{type Context}
import wisp.{type Request}

pub fn api(ctx: Context, req: Request) {
  case uri.path_segments(req.path) {
    ["api", "login"] -> login(ctx, req)
    ["api", "register"] -> register(ctx, req)
    _ -> Ok(wisp.not_found())
  }
  |> result.unwrap(wisp.internal_server_error())
}

fn login(ctx: Context, req: Request) {
  let body =
    parse_body(ctx, req, {
      use email <- decode.field("email", decode.string)
      use password <- decode.field("password", decode.string)
      #(email, password)
      |> decode.success()
    })
  use body <- result.try(body)
  let #(email, password) = body

  let user =
    db.user_fetch_by_email(ctx, email)
    |> result.replace_error("incorrect email or password")
  use user <- forward_error(user)

  let password_hash =
    db.user_fetch_password(ctx, user.id)
    |> log.error_on_error(ctx, "could not fetch password from database")
  use password_hash <- result.try(password_hash)

  let password = case beecrypt.verify(password, password_hash) {
    True -> Ok(Nil)
    False -> Error("incorrect email or password")
  }
  use _ <- forward_error(password)

  let token = auth_actor.set(ctx, user)

  log.info(ctx, "login successfull issueing token: " <> token.to_string(token))

  [#("success", token.to_json(token))]
  |> json.object()
  |> json.to_string()
  |> wisp.json_response(200)
  |> Ok
}

fn register(ctx, req) {
  let body =
    parse_body(ctx, req, {
      use user <- decode.field("user", user.decode_json())
      use password <- decode.field("password", decode.string)
      use password_repeat <- decode.field("password_repeat", decode.string)
      #(user, password, password_repeat)
      |> decode.success
    })

  use body <- result.try(body)
  let #(user, password, password_repeat) = body
  let user = User(..user, id: types.id_new())

  let email_exists = db.user_exists_email(ctx, user.email)
  use email_exists <- result.try(email_exists)
  let email_exists = case email_exists {
    True -> Error("email is already in use")
    False -> Ok(Nil)
  }
  use _ <- forward_error(email_exists)

  let is_password_match = case password == password_repeat {
    True -> Ok(Nil)
    False -> Error("passwords must match")
  }
  use _ <- forward_error(is_password_match)

  let is_name_empty = case string.is_empty(user.name) {
    True -> Error("name cannot be empty")
    False -> Ok(Nil)
  }
  use _ <- forward_error(is_name_empty)

  let is_email_empty = case string.is_empty(user.email) {
    True -> Error("email cannot be empty")
    False -> Ok(Nil)
  }
  use _ <- forward_error(is_email_empty)

  let result =
    db.user_insert(ctx, user, password)
    |> log.error_on_error(ctx, "could not insert user into database")
  use _ <- result.try(result)

  let token = auth_actor.set(ctx, user)

  log.info(ctx, "register successfull issue token: " <> token.to_string(token))

  [#("success", json.string(token.to_string(token)))]
  |> json.object()
  |> json.to_string
  |> wisp.json_response(200)
  |> Ok
}

fn parse_body(ctx, req, dec) {
  let body =
    wisp.read_body_bits(req)
    |> log.error_on_error(ctx, "could not read request body")
  use body <- result.try(body)

  body
  |> json.parse_bits(dec)
  |> log.error_on_error(ctx, "could not parse request body")
  |> result.replace_error(Nil)
}

fn forward_error(result: Result(a, String), handler) {
  case result {
    Ok(x) -> handler(x)
    Error(error) ->
      [#("error", json.string(error))]
      |> json.object()
      |> json.to_string()
      |> wisp.json_response(200)
      |> Ok
  }
}
