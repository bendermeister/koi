import api
import gleam/int
import gleam/uri
import log
import types.{type Context}
import wisp.{type Request, type Response}

pub fn handle_request(ctx: Context, req: Request) {
  use <- log_request(ctx, req)

  case uri.path_segments(req.path) {
    ["api", ..] -> api.api(ctx, req)
    _ -> wisp.not_found()
  }
}

fn log_request(
  ctx: Context,
  req: Request,
  callback: fn() -> Response,
) -> Response {
  log.info(ctx, "request: " <> req.path)
  let response = callback()
  log.info(ctx, "request done: " <> int.to_string(response.status))
  response
}
