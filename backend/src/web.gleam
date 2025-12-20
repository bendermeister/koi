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
import user
import wisp
import youid/uuid

type Handler =
  fn(context.Context, wisp.Request) -> wisp.Response

pub fn handle_request(ctx: context.Context, req: wisp.Request) {
  use ctx, req <- middleware(ctx, req)

  case wisp.path_segments(req) {
    ["api", "myself"] -> myself(ctx, req)
    ["api", "login"] -> login(ctx, req)
    ["api", ..tail] -> api.api(ctx, req, tail)
    _ -> wisp.not_found()
  }
}

fn login(ctx, req) {
  {
    let body =
      wisp.read_body_bits(req)
      |> log.on_error(ctx, "could not read request body")
    use body <- result.try(body)

    let body =
      body
      |> json.parse_bits({
        use name <- decode.field("name", decode.string)
        use password <- decode.field("password", decode.string)
        #(name, password) |> decode.success
      })
      |> log.on_error(ctx, "could not parse request body")
      |> result.replace_error(Nil)
    use body <- result.try(body)
    let #(name, password) = body

    let login_data =
      db.user_fetch_login_data_from_name(ctx, name)
      |> log.on_error(ctx, "could not fetch user password hash")
    use login_data <- result.try(login_data)
    let #(hash, token) = login_data

    let is_same = beecrypt.verify(password, hash)
    use <- bool.guard(when: !is_same, return: Error(Nil))

    wisp.ok()
    |> wisp.set_cookie(req, "token", token, wisp.Signed, 60 * 60)
    |> Ok
  }
  |> result.unwrap(wisp.response(401))
}

fn myself_(ctx, req) {
  let token = wisp.get_cookie(req, "token", wisp.Signed)
  use token <- result.try(token)
  let token = uuid.from_string(token)
  use token <- result.try(token)
  let user = db.user_fetch_from_token(ctx, token)
  use user <- result.try(user)

  [#("is_logged_in", json.bool(True)), #("myself", user |> user.to_json)]
  |> json.object()
  |> Ok
}

fn myself(ctx, req) {
  myself_(ctx, req)
  |> result.lazy_unwrap(fn() {
    [#("is_logged_in", json.bool(False)), #("myself", json.null())]
    |> json.object()
  })
  |> json.to_string()
  |> wisp.json_response(200)
}

fn middleware(ctx: context.Context, req: wisp.Request, handler: Handler) {
  log.info(ctx, "request: " <> req.path)
  // use ctx, req <- authentication_middleware(ctx, req)
  let response = handler(ctx, req)
  log.info(ctx, "response: " <> int.to_string(response.status))
  response
}
