import gleam/result
import gleam/uri

pub type Route {
  NotFound
  Calendar
  Login
  Agenda
  Inbox
  Archive
}

pub fn from_uri(route: uri.Uri) {
  case uri.path_segments(route.path) {
    ["login"] -> Login
    ["agenda"] -> Agenda
    ["inbox"] -> Inbox
    ["archive"] -> Archive
    ["calendar"] -> Calendar
    _ -> NotFound
  }
}

pub fn from_string(route: String) {
  route |> uri.parse() |> result.map(from_uri) |> result.unwrap(NotFound)
}

pub fn to_string(route: Route) {
  case route {
    NotFound -> "/404"
    Login -> "/login"
    Agenda -> "/agenda"
    Inbox -> "/inbox"
    Archive -> "/archive"
    Calendar -> "/calendar"
  }
}

pub fn home() {
  Agenda
}
