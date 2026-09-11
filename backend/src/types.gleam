import birl
import gleam/dict
import gleam/erlang/process
import middle/cached.{type Cached}
import middle/id.{type ID}
import middle/token.{type Token}
import middle/user.{type User}
import pog
import rasa/table
import youid/uuid

pub fn id_new() {
  uuid.v4()
  |> uuid.to_string()
  |> id.from_string()
}

pub fn token_new() {
  uuid.v4()
  |> uuid.to_string()
  |> token.from_string()
}

pub type Context {
  Context(
    id: ID(Context),
    log: process.Subject(LogMessage),
    db: pog.Connection,
    auth: process.Subject(AuthActorMessage),
    cache: process.Subject(CacheActorMessage),
  )
}

pub type LogActorBuilder {
  LogActorBuilder(sink: fn(String) -> Nil, name: process.Name(LogMessage))
}

pub type LogActor {
  LogActor(sink: fn(String) -> Nil)
}

pub type LogMessage {
  LogMessage(ctx: Context, level: String, message: String)
  LogActorStop
}

pub type AuthActor {
  AuthActor(state: dict.Dict(Token, #(User, birl.Time)))
}

pub type AuthActorMessage {
  AuthActorSet(reply_to: process.Subject(Token), user: User)
  AuthActorGet(reply_to: process.Subject(Result(User, Nil)), token: Token)
  AuthActorGarbageCollect
  AuthActorStop
}

pub type CacheActor {
  CacheActor(table: table.Table(String, Cached))
}

pub type CacheActorMessage {
  CacheActorSet(key: String, value: Cached, ctx: Context)
  CacheActorGet(
    reply_to: process.Subject(Result(Cached, Nil)),
    key: String,
    ctx: Context,
  )
  CacheActorDelete(key: String, ctx: Context)
  CacheActorStop
  CacheActorClear
}
