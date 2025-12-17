import gleam/result
import gleam/uri

pub type Route {
  NotFound
  Login
  UserOverview
  Task
  Tag
}

pub fn to_string(route: Route) {
  case route {
    Login -> "/login"
    NotFound -> "/not_found"
    UserOverview -> "/user/overview"
    Task -> "/task"
    Tag -> "/tag"
  }
}

pub fn from_string_(route: String) {
  case uri.path_segments(route) {
    ["login"] -> Login |> Ok
    ["not_found"] -> NotFound |> Ok
    ["task"] -> Task |> Ok
    ["tag"] -> Tag |> Ok
    ["user", "overview"] -> UserOverview |> Ok
    _ -> Error(Nil)
  }
}

pub fn from_string(route: String) {
  from_string_(route) |> result.unwrap(NotFound)
}

pub fn from_uri(uri: uri.Uri) {
  from_string(uri.path)
}

pub fn to_uri(route: Route) {
  let assert Ok(uri) =
    route
    |> to_string()
    |> uri.parse()

  uri
}

pub fn home() {
  NotFound
}
