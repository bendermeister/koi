import gleam/result
import gleam/uri

pub type Route {
  Login
  Logout
  SignUp
  NotFound
}

pub fn to_string(route: Route) -> String {
  case route {
    Login -> "/login"
    Logout -> "/logout"
    SignUp -> "/signup"
    NotFound -> "/notfound"
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
    ["signup"] -> SignUp
    _ -> NotFound
  }
}

pub fn to_uri(route: Route) {
  let assert Ok(uri) = route |> to_string |> uri.parse
  uri
}
