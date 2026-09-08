import gleam/bool
import gleam/dynamic/decode
import gleam/int
import gleam/list
import gleam/result
import log
import pog
import sql
import types.{type Context}

pub fn migrate(ctx: Context) -> Result(Nil, Nil) {
  let level = get_level(ctx)
  use level <- result.try(level)

  pog.transaction(ctx.db, fn(db) {
    let ctx = types.Context(..ctx, db:)
    let result =
      migrations
      |> list.drop(level)
      |> list.index_fold(Ok(Nil), fn(acc, migration, index) {
        acc
        |> result.try(fn(_) {
          let index = int.to_string(index + level)
          log.info(ctx, "running migration: " <> index)
          migration(ctx)
          |> log.error_on_error(ctx, "error while running migration: " <> index)
        })
      })
    use _ <- result.try(result)

    "UPDATE migration SET level = $1;"
    |> pog.query()
    |> pog.parameter(migrations |> list.length() |> pog.int())
    |> sql.execute(ctx)
  })
  |> log.error_on_error_format(ctx, sql.transaction_error_format)
  |> result.replace(Nil)
  |> result.replace_error(Nil)
}

const migrations = [
  migration_0000,
]

pub fn get_level(ctx: Context) -> Result(Int, Nil) {
  // check if migration table even exists

  let exists =
    "SELECT EXISTS (SELECT FROM pg_tables WHERE schemaname = 'public' AND tablename = 'migration');"
    |> pog.query()
    |> pog.returning(decode.field(0, decode.bool, decode.success))
    |> sql.fetch_one(ctx)
  use exists <- result.try(exists)

  use <- bool.guard(when: !exists, return: Ok(0))

  "SELECT level FROM migration LIMIT 1;"
  |> pog.query()
  |> pog.returning(decode.field(0, decode.int, decode.success))
  |> sql.fetch_one(ctx)
}

fn migration_0000(ctx: Context) -> Result(Nil, Nil) {
  let result =
    "
    CREATE TABLE migration (
      level BIGINT NOT NULL
    );
    "
    |> pog.query()
    |> sql.execute(ctx)
  use _ <- result.try(result)

  let result =
    "INSERT INTO migration (level) VALUES(1);"
    |> pog.query()
    |> sql.execute(ctx)
  use _ <- result.try(result)

  Ok(Nil)
}
