import context
import dot_env
import dot_env/env
import gleam/erlang/process
import gleam/option.{Some}
import gleam/otp/static_supervisor as supervisor
import id
import log
import migration
import mist
import pog
import types.{Context, ID}
import web
import wisp
import wisp/wisp_mist

pub fn start_application_supervisor(
  name pool_name: process.Name(pog.Message),
  host host: String,
  port port: Int,
  user user: String,
  password password: String,
  database database: String,
) {
  pog.default_config(pool_name)
  |> pog.host(host)
  |> pog.port(port)
  |> pog.password(Some(password))
  |> pog.user(user)
  |> pog.database(database)
  |> pog.pool_size(16)
  |> pog.supervised()
}

pub fn main() -> Nil {
  // TODO: integrate our logger with thhe erlang logger
  wisp.configure_logger()

  // setup dot_env
  dot_env.new()
  |> dot_env.set_path("./.env")
  |> dot_env.set_debug(False)
  |> dot_env.load()

  // http server environment variables
  let assert Ok(server_host) = env.get_string("KOI_HOST")
  let assert Ok(server_port) = env.get_int("KOI_PORT")
  let assert Ok(server_cookie_secret) = env.get_string("KOI_COOKIE_SECRET")

  // database environment variables 
  let assert Ok(db_host) = env.get_string("KOI_DB_HOST")
  let assert Ok(db_port) = env.get_int("KOI_DB_PORT")
  let assert Ok(db_user) = env.get_string("KOI_DB_USER")
  let assert Ok(db_password) = env.get_string("KOI_DB_PASSWORD")
  let assert Ok(db_database) = env.get_string("KOI_DB_DATABASE")

  // start postgres connection under a supervisor
  let db_name = process.new_name("db")
  let db_spec =
    start_application_supervisor(
      name: db_name,
      host: db_host,
      port: db_port,
      user: db_user,
      password: db_password,
      database: db_database,
    )

  let log_actor_name = process.new_name("log_actor")

  let log_actor_spec =
    log.new(log_actor_name)
    |> log.sink(log.sink_io)
    |> log.supervised

  let assert Ok(_) =
    supervisor.new(supervisor.OneForOne)
    |> supervisor.add(log_actor_spec)
    |> supervisor.add(db_spec)
    |> supervisor.start()

  let log = process.named_subject(log_actor_name)
  let db = pog.named_connection(db_name)

  let context_base = Context(id: ID("base"), log: log, db:)

  let request_handler = fn(req) {
    context_base
    |> context.new()
    |> web.handle_request(req)
  }

  let assert Ok(_) = migration.migrate(context_base)

  let assert Ok(_) =
    wisp_mist.handler(request_handler, server_cookie_secret)
    |> mist.new()
    |> mist.port(server_port)
    |> mist.bind(server_host)
    |> mist.start()

  process.sleep_forever()
}
