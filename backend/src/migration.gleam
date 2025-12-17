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
  migration_0005,
  migration_0006,
  migration_0007,
  migration_0008,
  migration_0009,
  migration_0010,
  migration_0011,
  migration_0012,
  migration_0013,
  migration_0014,
  migration_0015,
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
    name TEXT NOT NULL,
    password TEXT NOT NULL,
    token TEXT NOT NULL,

    PRIMARY KEY(id)
  );
  "
  |> pog.query()
  |> db.execute(ctx)
}

fn migration_0002(ctx: context.Context) {
  "
  CREATE TABLE tag (
    id UUID NOT NULL,
    name TEXT NOT NULL,
    owner UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,

    PRIMARY KEY(id)
  );
  "
  |> pog.query()
  |> db.execute(ctx)
}

fn migration_0003(ctx: context.Context) {
  "
  CREATE TABLE task (
    id UUID NOT NULL,
    owner UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE, 
    title TEXT NOT NULL,
    opened TIMESTAMP NOT NULL,
    closed TIMESTAMP,
    body TEXT NOT NULL,

    PRIMARY KEY(id)
  );
  "
  |> pog.query()
  |> db.execute(ctx)
}

fn migration_0004(ctx: context.Context) {
  "
  CREATE TABLE  task_tag (
    task UUID NOT NULL REFERENCES task(id) ON DELETE CASCADE,
    tag UUID NOT NULL REFERENCES tag(id) ON DELETE CASCADE,

    PRIMARY KEY(task, tag)
  );
  "
  |> pog.query()
  |> db.execute(ctx)
}

fn migration_0005(ctx: context.Context) {
  "
  CREATE TABLE project (
    id UUID NOT NULL,
    owner UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    name TEXT NOT NULL,

    PRIMARY KEY(id)
  );
  "
  |> pog.query()
  |> db.execute(ctx)
}

fn migration_0006(ctx: context.Context) {
  "
  ALTER TABLE tag DROP COLUMN owner;
  "
  |> pog.query()
  |> db.execute(ctx)
}

fn migration_0007(ctx: context.Context) {
  "
  ALTER TABLE tag ADD COLUMN owner UUID NOT NULL REFERENCES project(id) ON DELETE CASCADE;
  "
  |> pog.query()
  |> db.execute(ctx)
}

fn migration_0008(ctx: context.Context) {
  "ALTER TABLE task DROP COLUMN owner;"
  |> pog.query()
  |> db.execute(ctx)
}

fn migration_0009(ctx: context.Context) {
  "ALTER TABLE task ADD COLUMN owner UUID NOT NULL REFERENCES project(id) ON DELETE CASCADE"
  |> pog.query()
  |> db.execute(ctx)
}

fn migration_0010(ctx: context.Context) {
  "INSERT INTO users (id, name, password, token) VALUES($1, $2, $3, $4)"
  |> pog.query()
  |> pog.parameter(uuid.v4() |> uuid.to_string |> pog.text)
  |> pog.parameter("admin" |> pog.text())
  |> pog.parameter("admin" |> beecrypt.hash() |> pog.text)
  |> pog.parameter(uuid.v4() |> uuid.to_string |> pog.text)
  |> db.execute(ctx)
}

fn migration_0011(ctx: context.Context) {
  "ALTER TABLE tag DROP COLUMN owner;"
  |> pog.query()
  |> db.execute(ctx)
}

fn migration_0012(ctx: context.Context) {
  "ALTER TABLE tag ADD COLUMN owner UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE"
  |> pog.query()
  |> db.execute(ctx)
}

fn migration_0013(ctx: context.Context) {
  "ALTER TABLE task DROP COLUMN owner;"
  |> pog.query()
  |> db.execute(ctx)
}

fn migration_0014(ctx: context.Context) {
  "ALTER TABLE task ADD COLUMN owner UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE"
  |> pog.query()
  |> db.execute(ctx)
}

fn migration_0015(ctx: context.Context) {
  "DROP TABLE project;"
  |> pog.query()
  |> db.execute(ctx)
}
