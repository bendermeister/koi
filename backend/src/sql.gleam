import gleam/dynamic/decode
import gleam/int
import gleam/list
import gleam/result
import gleam/string
import log
import pog
import types.{type Context}

pub fn error_format(err: pog.QueryError) -> String {
  let err = case err {
    pog.ConstraintViolated(message:, constraint:, detail:) ->
      "ConstraintViolated(message: "
      <> message
      <> ", constraint: "
      <> constraint
      <> ", detail: "
      <> detail
      <> ")"
    pog.PostgresqlError(code:, name:, message:) ->
      "SqlError(code: "
      <> code
      <> ", name: "
      <> name
      <> " , message: "
      <> message
      <> ")"
    pog.UnexpectedArgumentCount(expected:, got:) -> {
      let expected = int.to_string(expected)
      let got = int.to_string(got)

      "UnexpectedArgumentCount(expected: "
      <> expected
      <> ", got: "
      <> got
      <> ")"
    }
    pog.UnexpectedArgumentType(expected:, got:) ->
      "UnexpectedArgumentType(expected: " <> expected <> ", got:" <> got <> " )"
    pog.UnexpectedResultType(errs) -> {
      let errs =
        errs
        |> list.map(fn(err) {
          let decode.DecodeError(expected:, found:, path:) = err
          let path = path |> string.join("/")
          "DecodeError(expected: "
          <> expected
          <> ", found: "
          <> found
          <> ", path: "
          <> path
          <> ")"
        })
        |> string.join(", ")
      let errs = "[" <> errs <> "]"

      "UnexpectedResultType(errors: " <> errs <> ")"
    }
    pog.QueryTimeout -> "QueryTimeout"
    pog.ConnectionUnavailable -> "ConnectionUnavailable"
  }

  "DB ERROR: " <> err
}

pub fn execute(q: pog.Query(a), ctx: Context) -> Result(Nil, Nil) {
  fetch(q, ctx)
  |> result.replace(Nil)
}

pub fn fetch(query: pog.Query(a), ctx: Context) -> Result(List(a), Nil) {
  query
  |> pog.execute(ctx.db)
  |> log.error_on_error_format(ctx, error_format)
  |> result.replace_error(Nil)
  |> result.map(fn(x) { x.rows })
}

pub fn fetch_one(q: pog.Query(a), ctx: Context) -> Result(a, Nil) {
  fetch(q, ctx)
  |> result.try(fn(r) {
    r |> list.first() |> log.error_on_error(ctx, "expected 1 got none")
  })
}

pub fn transaction_error_format(err: pog.TransactionError(a)) -> String {
  case err {
    pog.TransactionQueryError(err) -> error_format(err)
    pog.TransactionRolledBack(_) -> "TransactionRolledBack"
  }
}
