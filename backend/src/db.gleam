import beecrypt
import cache
import gleam/dynamic/decode
import gleam/result
import middle/cached
import middle/id.{type ID}
import middle/user.{type User, User}
import pog
import sql
import youid/uuid

fn decode_id() {
  use id <- decode.then(
    decode.one_of(decode.string, [
      {
        use id <- decode.then(decode.bit_array)
        uuid.from_bit_array(id)
        |> result.map(uuid.to_string)
        |> result.map(decode.success)
        |> result.unwrap(decode.failure("", "String"))
      },
    ]),
  )
  id.from_string(id)
  |> decode.success()
}

pub fn user_fetch_by_email(ctx, email) {
  use <- cache.try_cache(
    ctx,
    "db/user_fetch_by_email/" <> email,
    user.to_cached,
    user.from_cached,
  )

  "SELECT id, name FROM users WHERE email = $1 LIMIT 1;"
  |> pog.query()
  |> pog.parameter(pog.text(email))
  |> pog.returning({
    use id <- decode.field(0, decode_id())
    use name <- decode.field(1, decode.string)
    User(id:, name:, email:)
    |> decode.success
  })
  |> sql.fetch_one(ctx)
}

pub fn user_fetch_password(ctx, id: ID(User)) {
  "SELECT password FROM users WHERE id = $1 LIMIT 1;"
  |> pog.query()
  |> pog.parameter(id |> id.to_string() |> pog.text())
  |> pog.returning({
    use password <- decode.field(0, decode.string)
    decode.success(password)
  })
  |> sql.fetch_one(ctx)
}

pub fn user_exists_email(ctx, email) {
  use <- cache.try_cache(
    ctx,
    "db/user_exists_email/" <> email,
    cached.from_bool,
    cached.to_bool,
  )

  "SELECT EXISTS (SELECT 1 FROM users WHERE email = $1 LIMIT 1);"
  |> pog.query()
  |> pog.returning({
    use e <- decode.field(0, decode.bool)
    decode.success(e)
  })
  |> pog.parameter(pog.text(email))
  |> sql.fetch_one(ctx)
}

pub fn user_insert(ctx, user: User, password) {
  cache.delete(ctx, "db/user_fetch_by_email/" <> user.email)
  cache.delete(ctx, "db/user_exists_email/" <> user.email)

  let password = beecrypt.hash(password)
  " INSERT INTO users (id, name, email, password) VALUES($1, $2, $3, $4); "
  |> pog.query()
  |> pog.parameter(user.id |> id.to_string() |> pog.text)
  |> pog.parameter(pog.text(user.name))
  |> pog.parameter(pog.text(user.email))
  |> pog.parameter(pog.text(password))
  |> sql.execute(ctx)
}
