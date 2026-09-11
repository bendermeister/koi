import gleam/erlang/process
import gleam/otp/actor
import gleam/otp/supervision
import gleam/result
import rasa/table
import types.{
  type Cache, type CacheMessage, Cache, CacheClear, CacheDelete, CacheGet,
  CacheSet, CacheStop,
}

pub type Builder(key, value) {
  Builder(name: process.Name(CacheMessage(key, value)))
}

pub fn new(name) {
  Builder(name:)
}

fn table_init() {
  table.new()
  |> table.with_access(table.Public)
  |> table.with_kind(table.Set)
  |> table.build()
}

fn on_message(actor: Cache(key, value), message: CacheMessage(key, value)) {
  case message {
    CacheSet(key:, value:) -> {
      let _ = table.insert(actor.table, key, value)
      actor.continue(actor)
    }
    CacheGet(reply_to:, key:) -> {
      table.lookup(actor.table, key)
      |> actor.send(reply_to, _)

      actor.continue(actor)
    }
    CacheDelete(key:) -> {
      let _ = table.delete(actor.table, key)
      actor.continue(actor)
    }
    CacheClear -> {
      let _ = table.drop(actor.table)

      Cache(table: table_init())
      |> actor.continue()
    }
    CacheStop -> {
      let _ = table.drop(actor.table)
      actor.stop()
    }
  }
}

pub fn start(builder: Builder(key, value)) {
  Cache(table: table_init())
  |> actor.new()
  |> actor.named(builder.name)
  |> actor.on_message(on_message)
  |> actor.start()
}

pub fn supervised(builder) {
  fn() { start(builder) }
  |> supervision.worker()
}

pub fn garbage_collect(actor) {
  process.spawn(fn() {
    process.sleep(24 * 60 * 60 * 1000)
    let _ = garbage_collect(actor)
    clear(actor)
  })
  Nil
}

pub fn get(cache, key) {
  actor.call(cache, 20_000, CacheGet(reply_to: _, key:))
}

pub fn set(cache, key, value) {
  actor.send(cache, CacheSet(key:, value:))
}

pub fn clear(cache) {
  actor.send(cache, CacheClear)
}

pub fn cached(cache, key, handler) {
  let value = get(cache, key)

  case value {
    Ok(value) -> value
    Error(_) -> {
      let value = handler()
      set(cache, key, value)
      value
    }
  }
}

pub fn try_cached(cache, key, handler) {
  let value = get(cache, key)

  case value {
    Ok(value) -> Ok(value)
    Error(_) -> {
      let value = handler()
      let _ = value |> result.map(set(cache, key, _))
      value
    }
  }
}

pub fn delete(cache, key) {
  actor.send(cache, CacheDelete(key:))
}
