import gleam/option.{None}
import gleam/result
import gleam/uri
import modem

pub type Route {
  Login
  Logout
  Register
  NotFound
}

pub fn to_string(route: Route) -> String {
  case route {
    Login -> "/login"
    Logout -> "/logout"
    NotFound -> "/notfound"
    Register -> "/register"
  }
}

pub fn from_string(route: String) -> Result(Route, Nil) {
  route
  |> uri.parse()
  |> result.map(from_uri)
}

pub fn from_uri(route: uri.Uri) -> Route {
  case uri.path_segments(route.path) {
    ["login"] -> Login
    ["logout"] -> Logout
    ["register"] -> Register
    _ -> NotFound
  }
}

pub fn to_uri(route: Route) {
  let assert Ok(uri) = route |> to_string |> uri.parse
  uri
}

pub fn to_push_effect(route: Route) {
  route
  |> to_string
  |> modem.push(None, None)
}
