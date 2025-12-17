import component/component
import gleam/dynamic/decode
import gleam/io
import gleam/list
import gleam/option.{None, Some}
import gleam/string
import icon
import lustre
import lustre/attribute as attr
import lustre/effect
import lustre/element
import lustre/element/html
import lustre/event
import rsvp
import user
import util

type Model {
  Model(
    users: List(user.User),
    current_user: option.Option(user.User),
    query: String,
    new_user: option.Option(user.User),
  )
}

type Message {
  ClientReceivedUsers(users: List(user.User))
  UserDeletedUser(user: user.User)
  NotLoggedIn
  MessageError(message: String)
  MessageInfo(message: String)
  UserCreatedNewUser
  UserChangedQuery(query: String)
  UserSelectedUser(user: user.User)
  UserUpdatedUser(user: user.User)
  UserUpdatedNewUser(user: user.User)
  UserSavedNewUser(user: user.User)
  ClientReceivedNewUser(user: user.User)
  UserResettedToken(user: user.User)
  UserResettedPassword(user: user.User)
}

fn init(_) {
  let handler =
    util.json_handler(
      decode.list(user.json_decoder()),
      ClientReceivedUsers,
      NotLoggedIn,
      MessageError,
    )
  let effect = rsvp.get("/api/user/fetch/all", handler)
  let model = Model(users: [], current_user: None, query: "", new_user: None)

  #(model, effect)
}

fn update(model: Model, message: Message) {
  case message {
    ClientReceivedUsers(users:) -> {
      let users =
        model.users
        |> list.append(users)
        |> list.unique()
        |> list.sort(fn(a, b) { string.compare(a.name, b.name) })

      let model = Model(..model, users:)
      let effect = effect.none()
      #(model, effect)
    }
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
    UserChangedQuery(query:) -> {
      let model = Model(..model, query:)
      let effect = effect.none()
      #(model, effect)
    }
    UserCreatedNewUser -> {
      let new_user =
        user.User(id: user.Id("new"), name: "new user")
        |> Some()
      let model = Model(..model, new_user:, current_user: new_user)
      let effect = effect.none()
      #(model, effect)
    }
    UserSelectedUser(user:) -> {
      let model = Model(..model, current_user: Some(user))
      let effect = effect.none()
      #(model, effect)
    }
    UserUpdatedUser(user:) -> {
      let users =
        model.users
        |> list.map(fn(x) {
          case x.id == user.id {
            True -> user
            False -> x
          }
        })
      let current_user = Some(user)
      let model = Model(..model, users:, current_user:)
      let body = user |> user.to_json
      let effect =
        rsvp.post(
          "/api/user/update",
          body,
          util.ok_handler(
            MessageInfo("user updated"),
            NotLoggedIn,
            MessageError,
          ),
        )
      #(model, effect)
    }
    UserResettedPassword(user:) -> {
      let body = user.id |> user.id_to_json()
      let effect =
        rsvp.post(
          "/api/user/password/reset",
          body,
          util.ok_handler(
            MessageInfo("password reset"),
            NotLoggedIn,
            MessageError,
          ),
        )
      #(model, effect)
    }
    UserResettedToken(user:) -> {
      let body = user.id |> user.id_to_json()
      let effect =
        rsvp.post(
          "/api/user/token/reset",
          body,
          util.ok_handler(MessageInfo("token reset"), NotLoggedIn, MessageError),
        )
      #(model, effect)
    }
    UserUpdatedNewUser(user:) -> {
      let model = Model(..model, new_user: Some(user))
      let effect = effect.none()
      #(model, effect)
    }
    UserSavedNewUser(user:) -> {
      let new_user = None
      let current_user = None

      let body = user |> user.to_json

      let effect =
        rsvp.post(
          "/api/user/new",
          body,
          util.json_handler(
            user.json_decoder(),
            ClientReceivedNewUser,
            NotLoggedIn,
            MessageError,
          ),
        )

      let model = Model(..model, new_user:, current_user:)
      #(model, effect)
    }
    ClientReceivedNewUser(user:) -> {
      let users =
        [user, ..model.users]
        |> list.unique()
        |> list.sort(fn(a, b) { string.compare(a.name, b.name) })
      let model = Model(..model, users:)
      let effect = effect.none()
      #(model, effect)
    }
    UserDeletedUser(user:) -> {
      let effect =
        rsvp.post(
          "/api/user/delete",
          user.id |> user.id_to_json,
          util.ok_handler(
            MessageInfo("user deleted"),
            NotLoggedIn,
            MessageError,
          ),
        )
      let users =
        model.users
        |> list.filter(fn(x) { x != user })
      let current_user = None
      let model = Model(..model, users:, current_user:)
      #(model, effect)
    }
  }
}

fn view(model: Model) {
  let users =
    model.users
    |> list.filter(fn(user) { string.contains(user.name, model.query) })
    |> list.append(
      model.new_user |> option.map(fn(x) { [x] }) |> option.unwrap([]),
    )
    |> list.map(fn(user) {
      html.div(
        [
          event.on_click(UserSelectedUser(user)),
          attr.class("w-full rounded-lg px-1 py-2 clickable"),
          case
            model.current_user
            |> option.map(fn(x) { user.id == x.id })
            |> option.unwrap(False)
          {
            True -> attr.class("clickable-focus")
            False -> attr.none()
          },
        ],
        [
          component.icon_and_text(
            [],
            icon.user([attr.class("size-5")]),
            user.name,
          ),
        ],
      )
    })

  html.div([attr.class("w-full h-full flex grid grid-cols-2 gap-2")], [
    component.card([attr.class("flex flex-col gap-2")], [
      html.div([attr.class("flex flex-row gap-4")], [
        html.div([attr.class("flex-grow")], [
          component.input("search", [
            attr.placeholder("..."),
            event.on_input(UserChangedQuery),
          ]),
        ]),
        html.div([attr.class("w-fit flex justify-start items-end")], [
          component.button(
            [attr.class("w-fit h-fit"), event.on_click(UserCreatedNewUser)],
            [
              component.icon_and_text(
                [],
                icon.user_plus([attr.class("size-5")]),
                "new user",
              ),
            ],
          ),
        ]),
      ]),
      ..users
    ]),
    component.card([], [user_card(model)]),
  ])
}

fn user_unselected() {
  html.div(
    [
      attr.class("flex justify-center items-center text-muted w-full h-full"),
    ],
    [
      html.text("select a user to get started"),
    ],
  )
}

fn user_card(model: Model) {
  case model.current_user, model.new_user {
    Some(current_user), Some(new_user) if current_user == new_user ->
      user_new(model, new_user)
    Some(current_user), _ -> user_edit(model, current_user)
    _, _ -> user_unselected()
  }
}

fn user_edit(_: Model, user: user.User) {
  html.div([attr.class("w-full h-full flex flex-col gap-4")], [
    component.title([], "user edit"),
    component.input("name", [
      attr.type_("text"),
      attr.value(user.name),
      event.on_change(fn(name) { UserUpdatedUser(user.User(..user, name:)) }),
    ]),
    html.div([attr.class("w-full grid grid-cols-3 gap-2")], [
      component.button([event.on_click(UserResettedPassword(user))], [
        html.text("reset password"),
      ]),
      component.button([event.on_click(UserResettedToken(user))], [
        html.text("reset token"),
      ]),
      component.button_alt([event.on_click(UserDeletedUser(user))], [
        html.text("delete"),
      ]),
    ]),
  ])
}

fn user_new(_model, user: user.User) {
  html.div([attr.class("w-full h-full flex flex-col gap-4")], [
    component.title([], "new user"),
    component.input("name", [
      attr.value(user.name),
      event.on_change(fn(name) { UserUpdatedNewUser(user.User(..user, name:)) }),
    ]),
    html.div([attr.class("w-full grid grid-cols-3 gap-2")], [
      html.div([], []),
      html.div([], []),
      component.button([event.on_click(UserSavedNewUser(user))], [
        html.text("save"),
      ]),
    ]),
  ])
}

pub fn register() {
  lustre.component(init, update, view, [])
  |> lustre.register("koi-page-user-overview")
}

pub fn element() {
  element.element("koi-page-user-overview", [], [])
}
