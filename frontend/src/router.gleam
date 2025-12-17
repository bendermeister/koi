import component/component
import ffi
import gleam/io
import gleam/list
import gleam/option
import gleam/pair
import gleam/result
import icon
import lustre/attribute as attr
import lustre/effect
import lustre/element
import lustre/element/html
import modem
import page/login
import page/not_found
import page/project_overview
import page/user_overview
import route
import rsvp
import user
import util

pub type Model {
  Model(route: route.Route, user: option.Option(user.User))
}

pub type Message {
  ClientLoadedUri(route: route.Route)
  ClientReceivedUser(user: user.User)
  MessageError(message: String)
  NotLoggedIn
}

pub fn init(_) {
  let assert Ok(uri) = modem.initial_uri()
  let route = uri |> route.from_uri()

  let is_logged_in =
    ffi.get_cookies()
    |> list.key_find("is_logged_in")
    |> result.map(fn(x) { x == "true" })
    |> result.unwrap(False)

  let route = case is_logged_in {
    True -> route
    False -> route.Login
  }

  let model = Model(route:, user: option.None)

  let get_myself =
    util.json_handler(
      user.json_decoder(),
      ClientReceivedUser,
      NotLoggedIn,
      MessageError,
    )
    |> rsvp.get("/api/myself", _)

  let effect =
    modem.init(fn(uri) { uri |> route.from_uri() |> ClientLoadedUri })

  let effect = effect.batch([get_myself, effect])
  #(model, effect)
}

pub fn update(model: Model, message: Message) {
  echo model
  case message {
    ClientLoadedUri(route:) -> #(Model(..model, route:), effect.none())
    ClientReceivedUser(user:) ->
      Model(..model, user: option.Some(user)) |> pair.new(effect.none())
    MessageError(message:) -> {
      io.println_error(message)
      #(model, effect.none())
    }
    NotLoggedIn -> {
      util.not_logged_in()
      |> pair.new(model, _)
    }
  }
}

fn header(model: Model) {
  let selected = fn(route) {
    case model.route == route {
      False -> attr.none()
      True -> attr.class("bg-foam rounded-lg text-overlay")
    }
  }

  let when_admin = fn(element) {
    let is_admin =
      model.user
      |> option.map(fn(user) { user.name == "admin" })
      |> option.unwrap(False)
    case is_admin {
      False -> element.none()
      True -> element
    }
  }

  html.div(
    [
      attr.class(
        "w-full h-[3rem] bg-overlay flex flex-row justify-between items-center p-2",
      ),
    ],
    [
      html.div([attr.class("text-2xl text-rose font-extrabold")], [
        html.text("koi"),
      ]),
      html.div([attr.class("flex flex-row gap-4 justify-end items-center")], [
        component.icon_and_text(
          [
            attr.class("p-2 hover:cursor-pointer"),
          ],
          icon.calendar([attr.class("size-5")]),
          "calendar",
        ),
        component.icon_and_text(
          [
            attr.class("p-2 hover:cursor-pointer"),
          ],
          icon.task([attr.class("size-5")]),
          "tasks",
        ),
        component.icon_and_text(
          [
            attr.class("p-2 hover:cursor-pointer"),
            selected(route.ProjectOverview),
          ],
          icon.project([attr.class("size-5")]),
          "projects",
        ),
        component.icon_and_text(
          [attr.class("p-2 hover:cursor-pointer"), selected(route.UserOverview)],
          icon.users([attr.class("size-5")]),
          "users",
        )
          |> when_admin(),
      ]),
    ],
  )
}

fn layout(child, model) {
  html.div([attr.class("h-screen w-screen flex flex-col")], [
    header(model),
    html.div([attr.class("w-full h-[calc(100dvh-3rem)] p-2 overflow-scroll")], [
      child,
    ]),
  ])
}

fn base(child) {
  html.div([attr.class("w-screen h-screen text-text bg-base")], [child])
}

pub fn view(model: Model) {
  case model.route {
    route.Login -> login.element()
    route.NotFound -> not_found.element() |> layout(model)
    route.ProjectOverview -> project_overview.element() |> layout(model)
    route.UserOverview -> user_overview.element() |> layout(model)
  }
  |> base()
}
