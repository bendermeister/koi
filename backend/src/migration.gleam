import beecrypt
import context
import db
import gleam/bool
import gleam/dynamic/decode
import gleam/int
import gleam/list
import gleam/option
import gleam/result
import log
import pog
import youid/uuid

pub fn migrate(ctx: context.Context) -> Result(Nil, Nil) {
  let level = get_level(ctx)
  use level <- result.try(level)

  pog.transaction(ctx.db, fn(db) {
    let ctx = context.Context(id: uuid.v4(), db:, user: option.None)
    let result =
      migrations
      |> list.drop(level)
      |> list.index_fold(Ok(Nil), fn(acc, migration, index) {
        acc
        |> result.try(fn(_) {
          let index = int.to_string(index + level)
          log.info(ctx, "running migration: " <> index)
          migration(ctx)
          |> log.on_error(ctx, "error while running migration: " <> index)
        })
      })
    use _ <- result.try(result)

    "UPDATE migration SET level = $1;"
    |> pog.query()
    |> pog.parameter(migrations |> list.length() |> pog.int())
    |> db.execute(ctx)
  })
  |> log.on_errorf(ctx, db.transaction_error_format)
  |> result.replace(Nil)
  |> result.replace_error(Nil)
}

const migrations = [
  migration_0000,
  migration_0001,
  migration_0002,
  migration_0003,
  migration_0004,
]

pub fn get_level(ctx: context.Context) -> Result(Int, Nil) {
  // check if migration table even exists

  let exists =
    "SELECT EXISTS (SELECT FROM pg_tables WHERE schemaname = 'public' AND tablename = 'migration');"
    |> pog.query()
    |> pog.returning(decode.field(0, decode.bool, decode.success))
    |> db.fetch_one(ctx)
  use exists <- result.try(exists)

  use <- bool.guard(when: !exists, return: Ok(0))

  "SELECT level FROM migration LIMIT 1;"
  |> pog.query()
  |> pog.returning(decode.field(0, decode.int, decode.success))
  |> db.fetch_one(ctx)
}

fn migration_0000(ctx: context.Context) -> Result(Nil, Nil) {
  let result =
    "
    CREATE TABLE migration (
      level BIGINT NOT NULL
    );
    "
    |> pog.query()
    |> db.execute(ctx)
  use _ <- result.try(result)

  let result =
    "INSERT INTO migration (level) VALUES(1);"
    |> pog.query()
    |> db.execute(ctx)
  use _ <- result.try(result)

  Ok(Nil)
}

fn migration_0001(ctx: context.Context) {
  "
  CREATE TABLE users (
    id UUID NOT NULL,
    name VARCHAR(16) NOT NULL UNIQUE,
    password TEXT NOT NULL,
    token UUID NOT NULL,

    PRIMARY KEY(id)
  );
  "
  |> pog.query()
  |> db.execute(ctx)
}

fn migration_0002(ctx: context.Context) {
  let name = "admin"
  let password = beecrypt.hash("admin")
  let token = uuid.v4() |> uuid.to_string
  let id = uuid.v4() |> uuid.to_string
  "
  INSERT INTO users (id, name, password, token) VALUES ($1, $2, $3, $4);
  "
  |> pog.query()
  |> pog.parameter(id |> pog.text)
  |> pog.parameter(name |> pog.text)
  |> pog.parameter(password |> pog.text)
  |> pog.parameter(token |> pog.text)
  |> db.execute(ctx)
}

fn migration_0003(ctx: context.Context) {
  "
  CREATE TABLE tasks (
    id UUID NOT NULL,
    title VARCHAR(32) NOT NULL,
    body TEXT NOT NULL,
    opened DATE NOT NULL,
    closed DATE,
    scheduled Date,
    scheduled_start TIME,
    scheduled_end TIME,
    deadline DATE,
    deadline_time Time,

    PRIMARY KEY(id)
  );
  "
  |> pog.query()
  |> db.execute(ctx)
}

fn migration_0004(ctx: context.Context) {
  "ALTER TABLE tasks ADD COLUMN owner UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE"
  |> pog.query()
  |> db.execute(ctx)
}
