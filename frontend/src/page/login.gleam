import component/component
import ffi
import gleam/json
import gleam/option
import gleam/pair
import gleam/result
import lustre
import lustre/attribute as attr
import lustre/effect
import lustre/element
import lustre/element/html
import lustre/event
import modem
import route
import rsvp

pub type Model {
  Model(name: String, password: String, login_failed: Bool)
}

pub type Message {
  UserChangedPassword(password: String)
  UserChangedName(name: String)
  UserSubmitted
  LoginFailed
  LoginSuccessfull
}

fn init(_) {
  Model(name: "", password: "", login_failed: False)
  |> pair.new(effect.none())
}

fn update(model: Model, message: Message) {
  echo message
  case message {
    LoginSuccessfull -> {
      ffi.set_cookie("is_logged_in", "true")

      route.home()
      |> route.to_string()
      |> modem.push(option.None, option.None)
      |> pair.new(model, _)
    }
    UserChangedName(name:) -> Model(..model, name:) |> pair.new(effect.none())
    UserChangedPassword(password:) ->
      Model(..model, password:) |> pair.new(effect.none())
    UserSubmitted -> {
      let rsvp_handler =
        rsvp.expect_ok_response(fn(res) {
          res
          |> result.replace(LoginSuccessfull)
          |> result.unwrap(LoginFailed)
        })

      let body =
        [
          #("name", model.name |> json.string),
          #("password", model.password |> json.string),
        ]
        |> json.object()

      rsvp.post("/api/login", body, rsvp_handler)
      |> pair.new(model, _)
    }
    LoginFailed -> Model(..model, login_failed: True) |> pair.new(effect.none())
  }
}

fn view(model: Model) {
  html.div(
    [
      attr.class("w-screen h-screen flex justify-center items-center p-5"),
    ],
    [
      component.card(
        [attr.class("flex lg:min-w-1/3 md:min-w-1/2 min-w-full flex-col gap-4")],
        [
          html.div(
            [attr.class("w-full flex flex-row justify-start items-center")],
            [
              component.title([], "login"),
            ],
          ),
          component.input("name", [
            attr.type_("text"),
            attr.value(model.name),
            event.on_change(UserChangedName),
          ]),
          component.input("password", [
            attr.type_("password"),
            attr.value(model.password),
            event.on_change(UserChangedPassword),
          ]),
          case model.login_failed {
            True ->
              html.div([attr.class("text-rose")], [html.text("login failed")])
            False -> element.none()
          },
          html.div([attr.class("w-full flex justify-end")], [
            component.button("login", [
              attr.class("w-fit"),
              event.on_click(UserSubmitted),
            ]),
          ]),
        ],
      ),
    ],
  )
}

pub fn register() {
  let component = lustre.component(init, update, view, [])
  lustre.register(component, "koi-page-login")
}

pub fn element() {
  element.element("koi-page-login", [], [])
}
