import api
import component
import errview
import gleam/option.{None}
import gleam/pair
import lustre/attribute.{class}
import lustre/element
import lustre/event
import middle/token.{type Token}
import modem
import route

import lustre/effect
import lustre/element/html.{div}

pub type Msg {
  PasswordVisibleToggle
  PasswordChanged(password: String)
  EmailChanged(email: String)
  UserLoggedIn
  ErrorMessage(error: String)
  Success(token: Token)
  ErrViewMsg(errview.ErrViewMsg)
  UserChangedRoute(route: route.Route)
}

pub type Model {
  Model(
    email: String,
    password: String,
    password_visible: Bool,
    errors: errview.ErrView,
  )
}

pub fn init(_) {
  #(
    Model(
      email: "",
      password: "",
      password_visible: False,
      errors: errview.new(),
    ),
    effect.none(),
  )
}

pub fn update(model: Model, msg: Msg) -> #(Model, effect.Effect(Msg)) {
  case msg {
    PasswordVisibleToggle -> #(
      Model(..model, password_visible: !model.password_visible),
      effect.none(),
    )
    PasswordChanged(password:) -> #(Model(..model, password:), effect.none())
    EmailChanged(email:) -> #(Model(..model, email:), effect.none())
    UserLoggedIn -> {
      let effect =
        api.login(
          email: model.email,
          password: model.password,
          handler: fn(result) {
            case result {
              Ok(token) -> Success(token)
              Error(error) -> ErrorMessage(error)
            }
          },
        )
      #(model, effect)
    }
    ErrorMessage(error:) -> {
      let #(errors, effect) = errview.add(model.errors, error)
      let effect = effect |> effect.map(ErrViewMsg)
      #(Model(..model, errors:), effect)
    }
    Success(_) -> #(model, effect.none())
    ErrViewMsg(msg) -> {
      let errors = errview.update(model.errors, msg)
      #(Model(..model, errors:), effect.none())
    }
    UserChangedRoute(route:) ->
      route
      |> route.to_string
      |> modem.push(None, None)
      |> pair.new(model, _)
  }
}

pub fn view(model: Model) {
  div([class("relative w-screen h-screen flex justify-center items-center")], [
    div([class("w-64 h-full flex flex-col justify-center items-center gap-4")], [
      div([class("w-full flex flex-row justify-start items-center")], [
        component.logo(),
      ]),
      component.labeled(
        "E-Mail",
        component.input_email(model.email, EmailChanged),
      ),
      component.labeled(
        "Password",
        component.input_password(
          model.password,
          model.password_visible,
          PasswordChanged,
          PasswordVisibleToggle,
        ),
      ),
      div([class("w-full flex flex-row justify-end items-center gap-2")], [
        div(
          [
            class("w-fit text-sm text-gray-2"),
            class("hover:cursor-pointer"),
            event.on_click(UserChangedRoute(route.Register)),
          ],
          [html.text("register")],
        ),
        div([class("w-fit")], [
          component.button("login", UserLoggedIn),
        ]),
      ]),
    ]),
    errview.view(model.errors) |> element.map(ErrViewMsg),
  ])
}
