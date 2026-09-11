import birl
import gleam/dict
import gleam/erlang/process
import middle/id.{type ID}
import middle/token.{type Token}
import middle/user.{type User}
import pog
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
