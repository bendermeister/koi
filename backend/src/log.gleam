import birl
import gleam/io
import gleam/otp/actor
import gleam/otp/supervision
import middle/id
import types.{
  type Context, type LogActor, type LogActorBuilder, type LogMessage, LogActor,
  LogActorBuilder, LogMessage,
}

pub fn sink_io(message: String) -> Nil {
  io.println(message)
}

pub fn sink_nil(_: a) -> Nil {
  Nil
}

fn format(ctx: Context, level: String, message: String) {
  let time = birl.now() |> birl.to_iso8601()
  let id = ctx.id |> id.to_string()
  "[ " <> level <> " " <> time <> " " <> id <> "] " <> message
}

pub fn new(name name) -> LogActorBuilder {
  LogActorBuilder(name:, sink: sink_nil)
}

pub fn sink(
  builder: LogActorBuilder,
  sink: fn(String) -> Nil,
) -> LogActorBuilder {
  LogActorBuilder(..builder, sink:)
}

fn on_message(state: LogActor, msg: LogMessage) {
  case msg {
    types.LogMessage(ctx:, level:, message:) -> {
      format(ctx, level, message)
      |> state.sink

      actor.continue(state)
    }

    types.LogActorStop -> actor.stop()
  }
}

pub fn start(builder: LogActorBuilder) {
  LogActor(sink: builder.sink)
  |> actor.new()
  |> actor.named(builder.name)
  |> actor.on_message(on_message)
  |> actor.start()
}

pub fn supervised(builder: LogActorBuilder) {
  fn() { start(builder) }
  |> supervision.worker()
}

pub fn info(ctx: Context, message: String) -> Nil {
  actor.send(ctx.log, LogMessage(ctx:, level: "Info", message:))
}

pub fn info_on_ok(r: Result(a, b), ctx: Context, message: String) {
  case r {
    Ok(ok) -> {
      info(ctx, message)
      Ok(ok)
    }
    Error(err) -> Error(err)
  }
}

pub fn info_on_error(r: Result(a, b), ctx: Context, message: String) {
  case r {
    Ok(ok) -> Ok(ok)
    Error(err) -> {
      info(ctx, message)
      Error(err)
    }
  }
}

pub fn warn(ctx: Context, message: String) -> Nil {
  actor.send(ctx.log, LogMessage(ctx:, message:, level: "Warn"))
}

pub fn error(ctx: Context, message: String) -> Nil {
  actor.send(ctx.log, LogMessage(ctx:, message:, level: "Error"))
}

pub fn error_on_error(
  r: Result(a, b),
  ctx: Context,
  message: String,
) -> Result(a, b) {
  case r {
    Ok(_) -> Nil
    Error(_) -> error(ctx, message)
  }

  r
}

pub fn error_on_error_format(
  r: Result(a, b),
  ctx: Context,
  format: fn(b) -> String,
) -> Result(a, b) {
  case r {
    Ok(_) -> Nil
    Error(err) -> format(err) |> error(ctx, _)
  }

  r
}
