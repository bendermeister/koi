import types.{type Context}
import wisp.{type Request}

pub fn handle_request(ctx: Context, req: Request) {
  wisp.ok()
  |> wisp.string_body("Hello World")
}
