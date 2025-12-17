import beecrypt
import context
import date_time
import gleam/dynamic/decode
import gleam/int
import gleam/list
import gleam/option
import gleam/result
import gleam/string
import log
import pog
import tag
import task
import user
import youid/uuid

fn uuid_decoder_string(wrapper: fn(String) -> a) {
  use uuid <- decode.then(decode.string)
  uuid
  |> uuid.from_string()
  |> result.map(uuid.to_string)
  |> result.map(wrapper)
  |> result.map(decode.success)
  |> result.unwrap(decode.failure(wrapper(""), "UUID"))
}

fn uuid_decoder_bit_array(wrapper: fn(String) -> a) {
  use uuid <- decode.then(decode.bit_array)
  uuid
  |> uuid.from_bit_array()
  |> result.map(uuid.to_string)
  |> result.map(wrapper)
  |> result.map(decode.success)
  |> result.unwrap(decode.failure(wrapper(""), "UUID"))
}

fn uuid_decoder(wrapper: fn(String) -> a) -> decode.Decoder(a) {
  decode.one_of(uuid_decoder_bit_array(wrapper), [
    uuid_decoder_bit_array(wrapper),
    uuid_decoder_string(wrapper),
  ])
}

pub fn query_error_format(err: pog.QueryError) {
  let message = case err {
    pog.ConnectionUnavailable -> "connection unavailable"
    pog.ConstraintViolated(message:, constraint:, detail:) -> {
      "constraint violated: message: "
      <> message
      <> " constraint: "
      <> constraint
      <> " detail: "
      <> detail
    }
    pog.PostgresqlError(code:, name:, message:) -> {
      "sql error: code: "
      <> code
      <> " name: "
      <> name
      <> " message: "
      <> message
    }
    pog.QueryTimeout -> "query timeout"
    pog.UnexpectedArgumentCount(expected:, got:) -> {
      let expected = expected |> int.to_string()
      let got = got |> int.to_string()
      "unexpected argument count: expected: " <> expected <> " got: " <> got
    }
    pog.UnexpectedArgumentType(expected:, got:) -> {
      "unexpected argument type: expected: " <> expected <> " got: " <> got
    }
    pog.UnexpectedResultType(err) -> {
      err
      |> list.map(fn(err) {
        case err {
          decode.DecodeError(expected:, found:, path:) -> {
            let path = path |> string.join("/")
            "decode: expected: "
            <> expected
            <> " found: "
            <> found
            <> " path: "
            <> path
          }
        }
      })
      |> string.join(", ")
    }
  }
  "db: " <> message
}

pub fn transaction_error_format(err: pog.TransactionError(_)) {
  case err {
    pog.TransactionQueryError(err) -> {
      let err = err |> query_error_format()
      "transaction: " <> err
    }
    pog.TransactionRolledBack(_) -> {
      "db: transaction rolled back"
    }
  }
}

pub fn fetch(query: pog.Query(a), ctx: context.Context) -> Result(List(a), Nil) {
  query
  |> pog.execute(ctx.db)
  |> log.on_errorf(ctx, query_error_format)
  |> result.replace_error(Nil)
  |> result.map(fn(rows) { rows.rows })
}

pub fn fetch_one(query: pog.Query(a), ctx: context.Context) -> Result(a, Nil) {
  let result = fetch(query, ctx)
  case result {
    Error(_) -> Error(Nil)
    Ok([]) -> {
      log.error(ctx, "db: expected one row got none")
      Error(Nil)
    }
    Ok([a]) -> Ok(a)
    Ok(_) -> {
      log.error(ctx, "db: expected one row got many")
      Error(Nil)
    }
  }
}

pub fn execute(query: pog.Query(a), ctx: context.Context) -> Result(Nil, Nil) {
  fetch(query, ctx)
  |> result.replace(Nil)
}

// ===========================Tag===============================================

pub fn tag_insert(ctx: context.Context, tag: tag.Tag) -> Result(tag.Tag, Nil) {
  let id = tag.Id(uuid.v4() |> uuid.to_string)
  let tag = tag.Tag(..tag, id:)
  "
  INSERT INTO tag (id, name, owner) VALUES($1, $2, $3);
  "
  |> pog.query()
  |> pog.parameter(tag.id.inner |> pog.text)
  |> pog.parameter(tag.name |> pog.text)
  |> pog.parameter(tag.owner.inner |> pog.text)
  |> execute(ctx)
  |> result.replace(tag)
}

pub fn tag_update(ctx: context.Context, tag: tag.Tag) {
  "
  UPDATE tag SET
    name = $2,
    owner = $3
  WHERE id = $1;
  "
  |> pog.query()
  |> pog.parameter(tag.id.inner |> pog.text)
  |> pog.parameter(tag.name |> pog.text)
  |> pog.parameter(tag.owner.inner |> pog.text)
  |> execute(ctx)
}

pub fn tag_delete(ctx: context.Context, tag: tag.Id) {
  "DELETE FROM tag WHERE id = $1;"
  |> pog.query()
  |> pog.parameter(tag.inner |> pog.text)
  |> execute(ctx)
}

pub fn tag_fetch_all(ctx: context.Context, user: user.Id) {
  "
  SELECT id, name, owner FROM tag WHERE owner = $1;
  "
  |> pog.query()
  |> pog.parameter(user.inner |> pog.text)
  |> pog.returning({
    use id <- decode.field(0, uuid_decoder(tag.Id))
    use name <- decode.field(1, decode.string)
    use owner <- decode.field(2, uuid_decoder(user.Id))
    tag.Tag(id:, name:, owner:)
    |> decode.success()
  })
  |> fetch(ctx)
}

// ===========================Task==============================================

pub fn task_insert(ctx: context.Context, task: task.Task) {
  let id = uuid.v4() |> uuid.to_string |> task.Id
  let task = task.Task(..task, id:)
  "
  INSERT INTO task (
    id,
    owner,
    title,
    opened,
    closed,
    body
  ) VALUES (
    $1,
    $2,
    $3,
    $4,
    $5,
    $6
  )
  "
  |> pog.query()
  |> pog.parameter(task.id.inner |> pog.text)
  |> pog.parameter(task.owner.inner |> pog.text)
  |> pog.parameter(task.title |> pog.text)
  |> pog.parameter(task.opened |> date_time.to_string |> pog.text)
  |> pog.parameter(
    task.closed |> option.map(date_time.to_string) |> pog.nullable(pog.text, _),
  )
  |> pog.parameter(task.body |> pog.text)
  |> execute(ctx)
  |> result.replace(task)
}

pub fn task_update(ctx: context.Context, task: task.Task) {
  "
  UPDATE TASK SET
    owner = $2,
    title = $3,
    opened = $4,
    closed = $5,
    body = $6
  WHERE id = $1;
  "
  |> pog.query()
  |> pog.parameter(task.id.inner |> pog.text)
  |> pog.parameter(task.title |> pog.text)
  |> pog.parameter(task.opened |> date_time.to_string |> pog.text)
  |> pog.parameter(
    task.closed |> pog.nullable(fn(x) { date_time.to_string(x) |> pog.text }, _),
  )
  |> execute(ctx)
}

pub fn task_delete(ctx: context.Context, task: task.Id) {
  "DELETE FROM task WHERE id = $1;"
  |> pog.query()
  |> pog.parameter(task.inner |> pog.text)
  |> execute(ctx)
}

pub fn task_fetch_all_for_user(ctx: context.Context, user: user.Id) {
  "
  SELECT id, owner, title, opened, closed, body
  FROM task WHERE owner = $1;
  "
  |> pog.query()
  |> pog.parameter(user.inner |> pog.text)
  |> pog.returning({
    use id <- decode.field(0, uuid_decoder(task.Id))
    use owner <- decode.field(1, uuid_decoder(user.Id))
    use title <- decode.field(2, decode.string)
    use opened <- decode.field(3, date_time.decoder())
    use closed <- decode.field(4, decode.optional(date_time.decoder()))
    use body <- decode.field(5, decode.string)
    task.Task(id:, owner:, title:, opened:, closed:, body:)
    |> decode.success()
  })
  |> fetch(ctx)
}

// ===========================User==============================================

pub fn user_token_reset(ctx: context.Context, user: user.Id) {
  "UPDATE users SET token = $2 WHERE id = $1;"
  |> pog.query()
  |> pog.parameter(user.inner |> pog.text)
  |> pog.parameter(uuid.v4() |> uuid.to_string |> pog.text)
  |> execute(ctx)
}

pub fn user_password_reset(ctx: context.Context, user: user.Id) {
  "UPDATE users SET password = $2 WHERE id = $1;"
  |> pog.query()
  |> pog.parameter(user.inner |> pog.text)
  |> pog.parameter(beecrypt.hash("password") |> pog.text)
  |> execute(ctx)
}

pub fn user_fetch(ctx: context.Context, user: user.Id) {
  "SELECT id, name FROM users WHERE id = $1 LIMIT 1;"
  |> pog.query()
  |> pog.parameter(user.inner |> pog.text())
  |> pog.returning({
    use id <- decode.field(0, uuid_decoder(user.Id))
    use name <- decode.field(1, decode.string)
    user.User(id:, name:) |> decode.success
  })
  |> fetch_one(ctx)
}

pub fn user_insert(ctx: context.Context, user: user.User) {
  let id = uuid.v4() |> uuid.to_string |> user.Id
  let user = user.User(..user, id:)
  let password = beecrypt.hash("password")
  let token = uuid.v4() |> uuid.to_string
  "
  INSERT INTO users (id, name, password, token) VALUES($1, $2, $3, $4);
  "
  |> pog.query()
  |> pog.parameter(user.id.inner |> pog.text)
  |> pog.parameter(user.name |> pog.text)
  |> pog.parameter(password |> pog.text)
  |> pog.parameter(token |> pog.text)
  |> execute(ctx)
  |> result.replace(user)
}

pub fn user_update(ctx: context.Context, user: user.User) {
  "
  UPDATE users SET
    name = $2
  WHERE id = $1;
  "
  |> pog.query()
  |> pog.parameter(user.id.inner |> pog.text)
  |> pog.parameter(user.name |> pog.text)
  |> execute(ctx)
}

pub fn user_delete(ctx: context.Context, user: user.Id) {
  "DELETE FROM users WHERE id = $1"
  |> pog.query()
  |> pog.parameter(user.inner |> pog.text)
  |> execute(ctx)
}

pub fn user_fetch_all(ctx: context.Context) {
  "
  SELECT id, name FROM users;
  "
  |> pog.query()
  |> pog.returning({
    use id <- decode.field(0, uuid_decoder(user.Id))
    use name <- decode.field(1, decode.string)
    user.User(id:, name:)
    |> decode.success()
  })
  |> fetch(ctx)
}

pub fn user_fetch_from_token(ctx: context.Context, token: String) {
  "
  SELECT id, name FROM users WHERE token = $1 LIMIT 1;
  "
  |> pog.query()
  |> pog.parameter(token |> pog.text)
  |> pog.returning({
    use id <- decode.field(0, uuid_decoder(user.Id))
    use name <- decode.field(1, decode.string)
    user.User(id:, name:)
    |> decode.success()
  })
  |> fetch_one(ctx)
}

pub fn user_fetch_login_data_from_name(ctx: context.Context, name: String) {
  echo "here"
  "
  SELECT password, token FROM users WHERE name = $1;
  "
  |> pog.query()
  |> pog.parameter(name |> pog.text)
  |> pog.returning({
    use password <- decode.field(0, decode.string)
    use token <- decode.field(1, uuid_decoder(fn(a) { a }))
    #(password, token) |> decode.success()
  })
  |> fetch_one(ctx)
}
