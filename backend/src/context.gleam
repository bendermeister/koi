import id
import types.{type Context, Context}

pub fn new(base: Context) -> Context {
  Context(..base, id: id.new())
}
