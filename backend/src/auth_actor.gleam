import birl
import gleam/dict
import gleam/erlang/process
import gleam/list
import gleam/otp/actor
import gleam/otp/supervision
import gleam/result
import middle/token.{type Token}
import middle/user.{type User}
import types.{
  type AuthActor, type AuthActorMessage, type Context, AuthActor,
  AuthActorGarbageCollect, AuthActorGet, AuthActorSet, AuthActorStop,
}

pub type Builder {
  Builder(name: process.Name(AuthActorMessage))
}

pub fn new(name) {
  Builder(name:)
}

const time_limit = 28_800

fn on_message(actor: AuthActor, msg: AuthActorMessage) {
  case msg {
    AuthActorSet(reply_to:, user:) -> {
      let time = birl.now()
      let token = types.token_new()
      let state =
        actor.state
        |> dict.insert(token, #(user, time))

      actor.send(reply_to, token)

      AuthActor(state:)
      |> actor.continue()
    }

    AuthActorGet(reply_to:, token:) -> {
      actor.state
      |> dict.get(token)
      |> result.try(fn(x) {
        let #(user, time) = x
        let now = birl.now() |> birl.to_unix()
        let time = birl.to_unix(time)
        case now - time < time_limit {
          True -> Ok(user)
          False -> Error(Nil)
        }
      })
      |> actor.send(reply_to, _)

      actor.continue(actor)
    }

    AuthActorGarbageCollect -> {
      let now = birl.now() |> birl.to_unix()

      let state =
        actor.state
        |> dict.to_list()
        |> list.filter(fn(x) {
          let #(_, #(_, time)) = x
          let time = birl.to_unix(time)
          now - time < time_limit
        })
        |> dict.from_list()

      AuthActor(state:)
      |> actor.continue()
    }

    AuthActorStop -> actor.stop()
  }
}

pub fn start(builder: Builder) {
  dict.new()
  |> AuthActor
  |> actor.new()
  |> actor.named(builder.name)
  |> actor.on_message(on_message)
  |> actor.start()
}

pub fn supervised(builder: Builder) {
  fn() { builder |> start }
  |> supervision.worker()
}

pub fn set(ctx: Context, user: User) -> Token {
  actor.call(ctx.auth, 20_000, AuthActorSet(reply_to: _, user:))
}

pub fn get(ctx: Context, token: Token) {
  actor.call(ctx.auth, 20_000, AuthActorGet(reply_to: _, token:))
}

pub fn garbage_collect(ctx: Context) {
  process.spawn(fn() {
    process.sleep(24 * 60 * 60 * 1000)
    let _ = garbage_collect(ctx)
    actor.send(ctx.auth, AuthActorGarbageCollect)
  })
  Nil
}
