import cache
import gleam/result
import log
import types.{type Context}

pub fn set(ctx, key, value) {
  log.info(ctx, "kv/set " <> key)
  cache.set(ctx.kv, key, value)
}

pub fn get(ctx: Context, key, from_cached) {
  cache.get(ctx.kv, key)
  |> result.map(from_cached)
  |> log.info_on_ok(ctx, "kv/get " <> key <> " hit")
  |> log.info_on_error(ctx, "kv/get " <> key <> " miss")
}

pub fn cached(ctx: Context, key, to_cached, from_cached, handler) {
  let value = get(ctx, key, from_cached)

  case value {
    Ok(value) -> value
    Error(_) -> {
      let value = handler()
      set(ctx, key, to_cached(value))
      value
    }
  }
}

pub fn try_cached(ctx: Context, key, to_cached, from_cached, handler) {
  let value = get(ctx, key, from_cached)

  case value {
    Ok(value) -> value
    Error(_) -> {
      let value = handler()
      let _ =
        value
        |> result.map(to_cached)
        |> result.map(set(ctx, key, _))
      value
    }
  }
}

pub fn delete(ctx: Context, key) {
  log.info(ctx, "kv/delete " <> key)
  cache.delete(ctx.kv, key)
}
