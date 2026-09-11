import api
import component
import errview
import gleam/bool
import gleam/pair
import lustre/attribute.{class}
import lustre/effect
import lustre/element
import lustre/element/html.{div}
import lustre/event
import middle/id
import middle/token.{type Token}
import middle/user
import route

pub type Model {
  Model(
    email: String,
    password: String,
    password_repeat: String,
    password_visible: Bool,
    errors: errview.ErrView,
    name: String,
  )
}

pub type Msg {
  NameChanged(name: String)
  PasswordChanged(password: String)
  PasswordRepeatChanged(password_repeat: String)
  EmailChanged(email: String)
  PasswordVisibleToggle
  Success(token: Token)
  UserChangedRoute(route: route.Route)
  UserRegistered
  ErrorMsg(error: String)
  ErrViewMsg(errview.ErrViewMsg)
}

pub fn init(_) {
  #(
    Model(
      name: "",
      email: "",
      password: "",
      password_repeat: "",
      password_visible: False,
      errors: errview.new(),
    ),
    effect.none(),
  )
}

pub fn update(model: Model, msg: Msg) {
  case msg {
    PasswordChanged(password:) -> #(Model(..model, password:), effect.none())
    PasswordRepeatChanged(password_repeat:) -> #(
      Model(..model, password_repeat:),
      effect.none(),
    )
    EmailChanged(email:) -> #(Model(..model, email:), effect.none())
    PasswordVisibleToggle -> #(
      Model(..model, password_visible: !model.password_visible),
      effect.none(),
    )
    UserChangedRoute(route:) ->
      route
      |> route.to_push_effect
      |> pair.new(model, _)
    UserRegistered ->
      api.register(
        user: user.User(id: id.ID("temp"), name: model.name, email: model.email),
        password: model.password,
        password_repeat: model.password_repeat,
        handler: fn(result) {
          case result {
            Ok(token) -> Success(token)
            Error(error) -> ErrorMsg(error)
          }
        },
      )
      |> pair.new(model, _)

    ErrorMsg(error:) -> {
      let #(errors, effect) = errview.add(model.errors, error)
      let model = Model(..model, errors:)
      let effect = effect |> effect.map(ErrViewMsg)
      #(model, effect)
    }

    ErrViewMsg(msg) -> {
      let errors = errview.update(model.errors, msg)
      #(Model(..model, errors:), effect.none())
    }
    Success(token: _) -> #(model, effect.none())
    NameChanged(name:) -> #(Model(..model, name:), effect.none())
  }
}

pub fn view(model: Model) {
  div([class("relative w-screen h-screen flex justify-center items-center")], [
    div([class("w-64 h-full flex flex-col justify-center items-center gap-4")], [
      div([class("w-full flex flex-row justify-start items-center")], [
        component.logo(),
      ]),
      component.labeled("Name", component.input_text(model.name, NameChanged)),
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
      component.labeled(
        "Repeat Password",
        component.input_password(
          model.password_repeat,
          model.password_visible,
          PasswordRepeatChanged,
          PasswordVisibleToggle,
        ),
      ),
      div([class("w-full flex flex-row justify-end items-center gap-2")], [
        div(
          [
            class("w-fit text-sm text-gray-2"),
            class("hover:cursor-pointer"),
            event.on_click(UserChangedRoute(route.Login)),
          ],
          [html.text("login")],
        ),
        div([class("w-fit")], [
          component.button("register", UserRegistered),
        ]),
      ]),
    ]),
    errview.view(model.errors) |> element.map(ErrViewMsg),
  ])
}
