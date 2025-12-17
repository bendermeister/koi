import gleam/result
import gleam/uri

pub type Route {
  NotFound
  Login
  ProjectOverview
  UserOverview
}

pub fn to_string(route: Route) {
  case route {
    Login -> "/login"
    ProjectOverview -> "/project/overview"
    NotFound -> "/not_found"
    UserOverview -> "/user/overview"
  }
}

pub fn from_string_(route: String) {
  case uri.path_segments(route) {
    ["login"] -> Login |> Ok
    ["not_found"] -> NotFound |> Ok
    ["project", "overview"] -> ProjectOverview |> Ok
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
  ProjectOverview
}
