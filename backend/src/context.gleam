import gleam/option.{type Option}
import pog
import user
import youid/uuid

pub type Context {
  Context(id: uuid.Uuid, db: pog.Connection, user: Option(user.User))
}
