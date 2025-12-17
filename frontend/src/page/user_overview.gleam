import gleam/dynamic/decode
import gleam/io
import gleam/list
import gleam/pair
import gleam/result
import gleam/string
import lustre
import lustre/effect
import lustre/element
import lustre/element/html
import rsvp
import user
import util

type Model {
  Model(users: List(user.User))
}

type Message {
  ClientReceivedUsers(users: List(user.User))
  NotLoggedIn
  MessageError(message: String)
  MessageInfo(message: String)
}

fn init(_) {
  let handler =
    util.json_handler(
      decode.list(user.json_decoder()),
      ClientReceivedUsers,
      NotLoggedIn,
      MessageError,
    )
  let handler =
    rsvp.expect_json(decode.list(user.json_decoder()), fn(res) {
      res
      |> result.map_error(fn(x) { echo x })
      |> result.map(ClientReceivedUsers)
      |> result.unwrap(NotLoggedIn)
    })

  let effect = rsvp.get("/api/user/fetch/all", handler)
  let model = Model(users: [])

  #(model, effect)
}

fn update(model: Model, message: Message) {
  case message {
    ClientReceivedUsers(users:) ->
      model.users
      |> list.append(users)
      |> list.unique
      |> list.sort(fn(a, b) { string.compare(a.name, b.name) })
      |> Model(users: _)
      |> pair.new(effect.none())
    NotLoggedIn -> {
      let effect = util.not_logged_in()
      #(model, effect)
    }
    MessageError(message:) -> {
      io.println_error(message)

      #(model, effect.none())
    }
    MessageInfo(message:) -> {
      io.println(message)
      #(model, effect.none())
    }
  }
}

fn view(model) {
  html.div([], [])
}

pub fn register() {
  lustre.component(init, update, view, [])
  |> lustre.register("koi-page-user-overview")
}

pub fn element() {
  element.element("koi-page-user-overview", [], [])
}
