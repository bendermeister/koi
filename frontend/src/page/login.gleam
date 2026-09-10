import api
import component
import errview
import lustre/attribute.{class}
import lustre/element

import lustre/effect
import lustre/element/html.{div}

pub type Msg {
  PasswordVisibleToggle
  PasswordChanged(password: String)
  EmailChanged(email: String)
  UserLoggedIn
  ErrorMessage(error: String)
  Success(token: String)
  ErrViewMsg(errview.ErrViewMsg)
}

pub type Model {
  Model(
    email: String,
    password: String,
    password_visible: Bool,
    errors: errview.ErrView,
  )
}

pub fn init() {
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
  }
}

pub fn view(model: Model) {
  div([class("relative w-screen h-screen flex justify-center items-center")], [
    div([class("w-64 h-full flex flex-col justify-center items-center gap-4")], [
      div([class("w-full flex flex-row justify-start items-center")], [
        component.logo(),
      ]),
      component.labeld(
        "E-Mail",
        component.input_email(model.email, EmailChanged),
      ),
      component.labeld(
        "Password",
        component.input_password(
          model.password,
          model.password_visible,
          PasswordChanged,
          PasswordVisibleToggle,
        ),
      ),
      div([class("w-full flex flex-row justify-end items-center")], [
        div([class("w-fit")], [
          component.button("login", UserLoggedIn),
        ]),
      ]),
    ]),
    errview.view(model.errors) |> element.map(ErrViewMsg),
  ])
}
