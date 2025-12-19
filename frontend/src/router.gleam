import component
import gleam/dynamic/decode
import gleam/io
import gleam/option.{type Option, None, Some}
import gleam/result
import icon
import lustre/attribute as attr
import lustre/effect
import lustre/element/html
import lustre/event
import modem
import page/inbox
import page/login
import route
import rsvp
import user

pub type SidebarState {
  SidebarOpen
  SidebarClosed
}

pub type Model {
  Model(route: route.Route, me: Option(user.User), sidebar_state: SidebarState)
}

pub type Message {
  UserChangedRoute(route: route.Route)
  UserToggledSidebar
  ClientLoadedRoute(route: route.Route)
  ClientReceivedMe(me: user.User)
}

pub fn view(model: Model) {
  case model.route {
    route.NotFound -> html.text("404") |> layout(model, _)
    route.Login -> login.element()
    route.Agenda -> html.text("agenda") |> layout(model, _)
    route.Inbox -> inbox.element() |> layout(model, _)
    route.Archive -> html.text("archive") |> layout(model, _)
    route.Calendar -> html.text("calendar") |> layout(model, _)
  }
  |> base_view
}

fn base_view(element) {
  html.div(
    [
      attr.class(
        "w-screen h-screen text-text bg-base font-serif border-overlay",
      ),
    ],
    [element],
  )
}

pub fn init(_) {
  let decoder = {
    use is_logged_in <- decode.field("is_logged_in", decode.bool)
    use me <- decode.field("myself", decode.optional(user.json_decoder()))
    #(is_logged_in, me) |> decode.success
  }
  let fetch_myself =
    rsvp.expect_json(decoder, fn(response) {
      response
      |> result.map(fn(response) {
        let #(is_logged_in, me) = response
        case is_logged_in, me {
          True, Some(me) -> ClientReceivedMe(me:)
          _, _ -> UserChangedRoute(route.Login)
        }
      })
      |> result.unwrap(UserChangedRoute(route.Login))
    })
    |> rsvp.get("/api/myself", _)

  let route =
    modem.initial_uri()
    |> result.map(route.from_uri)
    |> result.unwrap(route.NotFound)

  let modem_init =
    modem.init(fn(uri) { uri |> route.from_uri |> ClientLoadedRoute })

  let model = Model(route:, me: None, sidebar_state: SidebarClosed)

  let effect = effect.batch([modem_init, fetch_myself])

  #(model, effect)
}

pub fn update(model: Model, message: Message) {
  case message {
    UserChangedRoute(route:) -> {
      let effect = modem.push(route |> route.to_string, None, None)
      #(model, effect)
    }
    ClientLoadedRoute(route:) -> {
      let model = Model(..model, route:)
      #(model, effect.none())
    }
    ClientReceivedMe(me:) -> {
      let model = Model(..model, me: Some(me))
      #(model, effect.none())
    }
    UserToggledSidebar -> {
      let sidebar_state = case model.sidebar_state {
        SidebarOpen -> SidebarClosed
        SidebarClosed -> SidebarOpen
      }
      let model = Model(..model, sidebar_state:)
      #(model, effect.none())
    }
  }
}

fn layout(model: Model, element) {
  html.div([attr.class("w-screen h-screen flex flex-row")], [
    sidebar(model),
    html.div(
      [
        case model.sidebar_state {
          SidebarOpen -> attr.class("w-[calc(100dvw-9rem)]")
          SidebarClosed -> attr.class("w-[calc(100dvw-3rem)]")
        },

        attr.class("h-screen max-h-screen p-2"),
      ],
      [element],
    ),
  ])
}

fn sidebar(model: Model) {
  case model.sidebar_state {
    SidebarOpen -> sidebar_open(model)
    SidebarClosed -> sidebar_closed(model)
  }
}

fn sidebar_open(model: Model) {
  let class =
    attr.class(
      "p-2 clickable rounded-lg flex flex-row gap-2 justify-start items-center w-full",
    )
  let route = fn(route) {
    let style = case route == model.route {
      True -> attr.class("clickable-focus")
      False -> attr.none()
    }
    let event = event.on_click(UserChangedRoute(route))
    [style, event]
  }
  html.div(
    [
      attr.class(
        "w-36 bg-overlay h-full flex flex-col justify-between items-center p-2",
      ),
    ],
    [
      html.div(
        [attr.class("w-full flex flex-col gap-4 justify-center items-center")],
        [
          html.div(
            [
              event.on_click(UserToggledSidebar),
              attr.class("w-full text-left text-rose text-2xl"),
              attr.class("hover:cursor-pointer"),
            ],
            [
              html.text("koi"),
            ],
          ),
          html.div([class, ..route(route.Agenda)], [
            icon.agenda([]),
            html.text("agenda"),
          ]),
          html.div([class, ..route(route.Inbox)], [
            icon.inbox([]),
            html.text("inbox"),
          ]),
          html.div([class, ..route(route.Calendar)], [
            icon.calendar([]),
            html.text("calendar"),
          ]),
          html.div([class, ..route(route.Archive)], [
            icon.archive([]),
            html.text("archive"),
          ]),
        ],
      ),
    ],
  )
}

fn sidebar_closed(model: Model) {
  let class = attr.class("p-2 clickable rounded-lg")
  let route = fn(route) {
    let style = case route == model.route {
      True -> attr.class("clickable-focus")
      False -> attr.none()
    }
    let event = event.on_click(UserChangedRoute(route))
    [style, event]
  }

  html.div(
    [
      attr.class(
        "w-12 bg-overlay h-full flex flex-col justify-between items-center p-2",
      ),
    ],
    [
      html.div(
        [attr.class("w-full flex flex-col gap-4 justify-center items-center")],
        [
          html.div(
            [
              event.on_click(UserToggledSidebar),
              attr.class("w-full text-center text-rose text-2xl"),
              attr.class("hover:cursor-pointer"),
            ],
            [
              html.text("koi"),
            ],
          ),
          html.div([class, ..route(route.Agenda)], [icon.agenda([])]),
          html.div([class, ..route(route.Inbox)], [icon.inbox([])]),
          html.div([class, ..route(route.Calendar)], [icon.calendar([])]),
          html.div([class, ..route(route.Archive)], [icon.archive([])]),
        ],
      ),
    ],
  )
}
