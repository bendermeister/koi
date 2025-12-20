import context
import date
import gleam/dynamic/decode
import gleam/int
import gleam/list
import gleam/option.{type Option}
import gleam/result
import gleam/string
import gleam/time/calendar
import log
import pog
import task
import time
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
  decode.one_of(uuid_decoder_string(wrapper), [
    uuid_decoder_bit_array(wrapper),
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

pub fn user_fetch_from_token(ctx: context.Context, token: uuid.Uuid) {
  "
  SELECT id, name FROM users WHERE token = $1 LIMIT 1;
  "
  |> pog.query()
  |> pog.parameter(token |> uuid.to_string |> pog.text)
  |> pog.returning({
    use id <- decode.field(0, uuid_decoder(user.Id))
    use name <- decode.field(1, decode.string)
    user.User(id:, name:) |> decode.success
  })
  |> fetch_one(ctx)
}

pub fn user_fetch_login_data_from_name(ctx: context.Context, name: String) {
  "SELECT password,token FROM users WHERE name = $1 LIMIT 1;"
  |> pog.query()
  |> pog.parameter(name |> pog.text)
  |> pog.returning({
    use password <- decode.field(0, decode.string)
    use token <- decode.field(1, uuid_decoder(fn(x) { x }))
    #(password, token) |> decode.success
  })
  |> fetch_one(ctx)
}

pub fn task_decoder() {
  // id
  // title
  // body
  // opened
  // closed
  // scheduled
  // scheduled_start
  // scheduled_end
  // deadline
  // deadline_time

  use id <- decode.field(0, uuid_decoder(task.Id))
  use title <- decode.field(1, decode.string)
  use body <- decode.field(2, decode.string)
  use opened <- decode.field(3, date_decoder())
  use closed <- decode.field(4, decode.optional(date_decoder()))
  use scheduled <- decode.field(5, decode.optional(date_decoder()))
  use scheduled_start <- decode.field(6, decode.optional(time_decoder()))
  use scheduled_end <- decode.field(7, decode.optional(time_decoder()))
  use deadline <- decode.field(8, decode.optional(date_decoder()))
  use deadline_time <- decode.field(9, decode.optional(time_decoder()))
  task.Task(
    id:,
    title:,
    body:,
    opened:,
    closed:,
    scheduled:,
    scheduled_start:,
    scheduled_end:,
    deadline:,
    deadline_time:,
  )
  |> decode.success()
}

pub fn task_fetch_inbox(ctx: context.Context, user: user.User) {
  "
  SELECT
    id,
    title,
    body,
    opened,
    closed,
    scheduled,
    scheduled_start,
    scheduled_end,
    deadline,
    deadline_time
  FROM tasks WHERE 
    owner = $1 AND 
    closed IS NULL AND
    scheduled IS NULL AND
    deadline IS NULL
  "
  |> pog.query()
  |> pog.parameter(user.id.inner |> pog.text)
  |> pog.returning(task_decoder())
  |> fetch(ctx)
}

fn date_to_value(date: date.Date) {
  let date.Date(year:, month:, day:) = date

  let month = case month {
    date.Jan -> calendar.January
    date.Feb -> calendar.February
    date.Mar -> calendar.March
    date.Apr -> calendar.April
    date.May -> calendar.May
    date.Jun -> calendar.June
    date.Jul -> calendar.July
    date.Aug -> calendar.August
    date.Sep -> calendar.September
    date.Oct -> calendar.October
    date.Nov -> calendar.November
    date.Dec -> calendar.December
  }

  let date = calendar.Date(year:, month:, day:)

  date
  |> pog.calendar_date
}

fn date_opt_to_value(date: Option(date.Date)) {
  date
  |> pog.nullable(date_to_value, _)
}

fn time_to_value(time: time.Time) {
  let time.Time(hour:, minute:) = time

  let time =
    calendar.TimeOfDay(hours: hour, minutes: minute, seconds: 0, nanoseconds: 0)

  time
  |> pog.calendar_time_of_day()
}

fn time_opt_to_value(time: Option(time.Time)) {
  time
  |> pog.nullable(time_to_value, _)
}

fn time_decoder() {
  pog.calendar_time_of_day_decoder()
  |> decode.map(fn(time) { time.Time(hour: time.hours, minute: time.minutes) })
}

fn date_decoder() {
  pog.calendar_date_decoder()
  |> decode.map(fn(date) {
    let month = case date.month {
      calendar.January -> date.Jan
      calendar.February -> date.Feb
      calendar.March -> date.Mar
      calendar.April -> date.Apr
      calendar.May -> date.May
      calendar.June -> date.Jun
      calendar.July -> date.Jul
      calendar.August -> date.Aug
      calendar.September -> date.Sep
      calendar.October -> date.Oct
      calendar.November -> date.Nov
      calendar.December -> date.Dec
    }

    date.Date(year: date.year, month:, day: date.day)
  })
}

pub fn task_insert(ctx: context.Context, user: user.User, task: task.Task) {
  "INSERT INTO tasks (
    id,
    title,
    body,
    opened,
    closed,
    scheduled,
    scheduled_start,
    scheduled_end,
    deadline,
    deadline_time,
    owner
  ) VALUES (
    $1,
    $2,
    $3,
    $4,
    $5,
    $6,
    $7,
    $8,
    $9,
    $10,
    $11
  );"
  |> pog.query()
  |> pog.parameter(task.id.inner |> pog.text())
  |> pog.parameter(task.title |> pog.text())
  |> pog.parameter(task.body |> pog.text())
  |> pog.parameter(task.opened |> date_to_value)
  |> pog.parameter(task.closed |> date_opt_to_value)
  |> pog.parameter(task.scheduled |> date_opt_to_value)
  |> pog.parameter(task.scheduled_start |> time_opt_to_value)
  |> pog.parameter(task.scheduled_end |> time_opt_to_value)
  |> pog.parameter(task.deadline |> date_opt_to_value)
  |> pog.parameter(task.deadline_time |> time_opt_to_value)
  |> pog.parameter(user.id.inner |> pog.text)
  |> execute(ctx)
}

pub fn task_update(ctx: context.Context, task: task.Task) {
  "
  UPDATE tasks SET
    title = $2,
    body = $3,
    opened = $4,
    closed = $5,
    scheduled = $6,
    scheduled_start = $7,
    scheduled_end = $8,
    deadline = $9,
    deadline_time = $10
  WHERE id = $1;
  "
  |> pog.query()
  |> pog.parameter(task.id.inner |> pog.text)
  |> pog.parameter(task.title |> pog.text)
  |> pog.parameter(task.body |> pog.text)
  |> pog.parameter(task.opened |> date_to_value)
  |> pog.parameter(task.closed |> date_opt_to_value)
  |> pog.parameter(task.scheduled |> date_opt_to_value)
  |> pog.parameter(task.scheduled_start |> time_opt_to_value)
  |> pog.parameter(task.scheduled_end |> time_opt_to_value)
  |> pog.parameter(task.deadline |> date_opt_to_value)
  |> pog.parameter(task.deadline_time |> time_opt_to_value)
  |> execute(ctx)
}

pub fn task_delete(ctx: context.Context, task: task.Task) {
  "DELETE FROM tasks WHERE id = $1"
  |> pog.query()
  |> pog.parameter(task.id.inner |> pog.text)
  |> execute(ctx)
}

pub fn task_fetch_agenda(
  ctx: context.Context,
  owner: user.User,
  range: date.Range,
) {
  "
  SELECT
    id,
    title,
    body,
    opened,
    closed,
    scheduled,
    scheduled_start,
    scheduled_end,
    deadline,
    deadline_time
  FROM tasks WHERE
    owner = $1 AND
    (
      (scheduled IS NOT NULL AND $2 <= scheduled AND scheduled <= $3) OR
      (deadline IS NOT NULL AND $2 <= deadline AND deadline <= $3) OR
      (scheduled IS NOT NULL AND scheduled < $4) OR
      (deadline IS NOT NULL AND deadline < $4)
    ) AND
    closed IS NULL
  "
  |> pog.query()
  |> pog.parameter(owner.id.inner |> pog.text())
  |> pog.parameter(range.start |> date_to_value)
  |> pog.parameter(range.end |> date_to_value)
  |> pog.parameter(date.now() |> date_to_value)
  |> pog.returning(task_decoder())
  |> fetch(ctx)
}

pub fn task_fetch_open(ctx: context.Context, owner: user.User) {
  "
  SELECT
    id,
    title,
    body,
    opened,
    closed,
    scheduled,
    scheduled_start,
    scheduled_end,
    deadline,
    deadline_time
  FROM tasks WHERE
    owner = $1 AND closed IS NULL
  "
  |> pog.query()
  |> pog.parameter(owner.id.inner |> pog.text)
  |> pog.returning(task_decoder())
  |> fetch(ctx)
}
