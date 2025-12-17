import context
import dot_env
import dot_env/env
import gleam/erlang/process
import gleam/option
import gleam/otp/static_supervisor as supervisor
import migration
import mist
import pog
import web
import wisp
import wisp/wisp_mist
import youid/uuid

fn start_application_supervisor(
  name pool_name: process.Name(pog.Message),
  host host: String,
  port port: Int,
  user user: String,
  password password: String,
  database database: String,
) {
  // postgres configuration
  let pool_child =
    pog.default_config(pool_name)
    |> pog.host(host)
    |> pog.port(port)
    |> pog.password(option.Some(password))
    |> pog.user(user)
    |> pog.database(database)
    |> pog.pool_size(16)
    |> pog.supervised()

  // supervisor for postgres connection pool
  supervisor.new(supervisor.RestForOne)
  |> supervisor.add(pool_child)
  |> supervisor.start
}

pub fn main() -> Nil {
  // setup dot_env
  dot_env.new()
  |> dot_env.set_path("./.env")
  |> dot_env.set_debug(False)
  |> dot_env.load()

  // read environment variables

  // DB ENV variables
  let assert Ok(db_host) = env.get_string("KOI_DB_HOST")
  let assert Ok(db_port) = env.get_int("KOI_DB_PORT")
  let assert Ok(db_user) = env.get_string("KOI_DB_USER")
  let assert Ok(db_password) = env.get_string("KOI_DB_PASSWORD")
  let assert Ok(db_database) = env.get_string("KOI_DB_DATABASE")

  // Server ENV variables
  let assert Ok(server_port) = env.get_int("KOI_PORT")
  let assert Ok(server_host) = env.get_string("KOI_HOST")
  let assert Ok(cookie_secret) = env.get_string("KOI_COOKIE_SECRET")

  // start postgres connection under a supervisor
  let db = process.new_name("db")
  let assert Ok(_) =
    start_application_supervisor(
      name: db,
      host: db_host,
      port: db_port,
      user: db_user,
      password: db_password,
      database: db_database,
    )

  wisp.configure_logger()

  // run migrations on database
  let assert Ok(_) =
    db
    |> pog.named_connection()
    |> context.Context(id: uuid.v4(), db: _, user: option.None)
    |> migration.migrate()

  // TODO: replace this with our logger
  wisp.configure_logger()

  // request handler for each incoming request
  // - a context gets created with a new UUID and a database connection
  let request_handler = fn(req: wisp.Request) {
    let db = pog.named_connection(db)
    let ctx = context.Context(id: uuid.v4(), db:, user: option.None)
    web.handle_request(ctx, req)
  }

  // start the web server
  let assert Ok(_) =
    wisp_mist.handler(request_handler, cookie_secret)
    |> mist.new()
    |> mist.port(server_port)
    |> mist.bind(server_host)
    |> mist.start()

  process.sleep_forever()
}
