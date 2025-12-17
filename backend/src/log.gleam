import birl
import context
import gleam/io
import gleam/result
import youid/uuid

pub type Level {
  Info
  Warn
  Err
}

fn level_to_string(level: Level) {
  case level {
    Err -> "ERROR"
    Info -> "INFO"
    Warn -> "WARN"
  }
}

pub fn log(ctx: context.Context, level: Level, message: String) {
  let now = birl.now() |> birl.to_iso8601()
  let id = ctx.id |> uuid.to_string()
  let level = level |> level_to_string()
  let message = "[" <> level <> " " <> now <> " " <> id <> "]: " <> message
  io.println(message)
}

pub fn error(ctx: context.Context, message: String) {
  log(ctx, Err, message)
}

pub fn info(ctx: context.Context, message: String) {
  log(ctx, Info, message)
}

pub fn warn(ctx: context.Context, message: String) {
  log(ctx, Warn, message)
}

pub fn on_error(result: Result(a, b), ctx: context.Context, message: String) {
  result
  |> result.map_error(fn(x) {
    error(ctx, message)
    x
  })
}

pub fn on_errorf(
  result: Result(a, b),
  ctx: context.Context,
  message: fn(b) -> String,
) {
  result
  |> result.map_error(fn(err) {
    err |> message |> error(ctx, _)
    err
  })
}
