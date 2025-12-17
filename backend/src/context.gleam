import gleam/option
import pog
import user
import youid/uuid

pub type Context {
  Context(id: uuid.Uuid, db: pog.Connection, user: option.Option(user.User))
}
