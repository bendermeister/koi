import gleam/erlang/process
import pog

pub type ID(a) {
  ID(inner: String)
}

pub type Context {
  Context(id: ID(Context), log: process.Subject(LogMessage), db: pog.Connection)
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
