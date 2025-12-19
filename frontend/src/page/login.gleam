import component
import gleam/json
import gleam/option.{None}
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

type Model {
  Model(name: String, password: String, is_error: Bool)
}

type Message {
  UserUpdatedName(name: String)
  UserUpdatedPassword(password: String)
  UserSubmitted
  ClientReceivedOk
  ClientReceivedError
}

fn view(model: Model) {
  html.div(
    [attr.class("w-screen h-screen flex justify-center items-center p-5")],
    [
      html.div([attr.class("w-1/3 flex flex-col gap-2")], [
        component.labeled_input(
          [
            attr.value(model.name),
            attr.type_("text"),
            event.on_change(UserUpdatedName),
          ],
          "name",
        ),
        component.labeled_input(
          [
            attr.value(model.password),
            attr.type_("password"),
            event.on_change(UserUpdatedPassword),
          ],
          "password",
        ),
        html.div([attr.class("w-full flex flex-row justify-end")], [
          component.button(
            [event.on_click(UserSubmitted), attr.class("w-24 text-center")],
            [
              html.text("login"),
            ],
          ),
        ]),
        case model.is_error {
          True ->
            html.div([attr.class("text-love")], [html.text("login failed")])
          False -> element.none()
        },
      ]),
    ],
  )
}

fn update(model: Model, message: Message) {
  case message {
    UserUpdatedName(name:) -> {
      let model = Model(..model, name:)
      #(model, effect.none())
    }
    UserUpdatedPassword(password:) -> {
      let model = Model(..model, password:)
      #(model, effect.none())
    }
    UserSubmitted -> {
      let body =
        [
          #("name", model.name |> json.string),
          #("password", model.password |> json.string),
        ]
        |> json.object

      let effect =
        rsvp.expect_ok_response(fn(response) {
          response
          |> result.replace(ClientReceivedOk)
          |> result.unwrap(ClientReceivedError)
        })
        |> rsvp.post("/api/login", body, _)
      #(model, effect)
    }
    ClientReceivedOk -> {
      let effect = modem.push(route.home() |> route.to_string(), None, None)
      #(model, effect)
    }
    ClientReceivedError -> {
      let model = Model(..model, is_error: False)
      #(model, effect.none())
    }
  }
}

fn init(_) {
  let model = Model(name: "", password: "", is_error: False)
  #(model, effect.none())
}

pub fn register() {
  lustre.component(init, update, view, [])
  |> lustre.register("koi-page-login")
}

pub fn element() {
  element.element("koi-page-login", [], [])
}
