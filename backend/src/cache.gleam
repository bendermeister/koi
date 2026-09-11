import gleam/erlang/process
import gleam/otp/actor
import gleam/otp/supervision
import gleam/result
import log
import rasa/table
import types.{
  type CacheActor, type CacheActorMessage, type Context, CacheActor,
  CacheActorClear, CacheActorDelete, CacheActorGet, CacheActorSet,
  CacheActorStop,
}

pub type Builder {
  Builder(name: process.Name(CacheActorMessage))
}

pub fn new(name) {
  Builder(name:)
}

fn on_message(actor: CacheActor, msg: CacheActorMessage) {
  case msg {
    CacheActorSet(key:, value:, ctx:) -> {
      log.info(ctx, "cache/set " <> key)
      let _ = table.insert(actor.table, key, value)
      actor.continue(actor)
    }
    CacheActorGet(reply_to:, key:, ctx:) -> {
      let value =
        table.lookup(actor.table, key)
        |> log.info_on_ok(ctx, "cache/get " <> key <> " hit")
        |> log.info_on_error(ctx, "cache/get " <> key <> " miss")
      actor.send(reply_to, value)
      actor.continue(actor)
    }
    CacheActorDelete(key:, ctx:) -> {
      log.info(ctx, "cache/delete " <> key)
      let _ = table.delete(actor.table, key)
      actor.continue(actor)
    }
    CacheActorStop -> {
      let _ = table.drop(actor.table)
      actor.stop()
    }
    CacheActorClear -> {
      let _ = table.drop(actor.table)

      let table =
        table.new()
        |> table.with_kind(table.Set)
        |> table.with_access(table.Public)
        |> table.build()

      CacheActor(table:)
      |> actor.continue()
    }
  }
}

pub fn start(builder: Builder) {
  table.new()
  |> table.with_kind(table.Set)
  |> table.with_access(table.Public)
  |> table.build()
  |> CacheActor
  |> actor.new()
  |> actor.on_message(on_message)
  |> actor.named(builder.name)
  |> actor.start()
}

pub fn supervised(builder: Builder) {
  fn() { start(builder) }
  |> supervision.worker()
}

pub fn get(ctx: Context, key: String, handler) {
  let value =
    actor.call(ctx.cache, 20_000, CacheActorGet(reply_to: _, key:, ctx:))
  value
  |> result.try(handler)
}

pub fn set(ctx: Context, key, value) {
  actor.send(ctx.cache, CacheActorSet(key:, value:, ctx:))
}

pub fn cache(ctx: Context, key, to_cached, from_cached, callback) {
  case get(ctx, key, from_cached) {
    Ok(value) -> value
    Error(_) -> {
      let value = callback()
      set(ctx, key, to_cached(value))
      value
    }
  }
}

pub fn try_cache(
  ctx: Context,
  key,
  to_cached,
  from_cached,
  callback: fn() -> Result(a, Nil),
) {
  case get(ctx, key, from_cached) {
    Ok(value) -> Ok(value)
    Error(_) -> {
      let value = callback()
      case value {
        Ok(value) -> set(ctx, key, to_cached(value))
        Error(_) -> Nil
      }
      value
    }
  }
}

pub fn garbage_collect(ctx: Context) {
  process.spawn(fn() {
    process.sleep(24 * 60 * 60 * 1000)
    let _ = garbage_collect(ctx)
    actor.send(ctx.cache, CacheActorClear)
  })
  Nil
}

pub fn delete(ctx: Context, key) {
  actor.send(ctx.cache, CacheActorDelete(key:, ctx:))
}
