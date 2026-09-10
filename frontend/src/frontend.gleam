import gleam/io
import gleam/result
import lustre
import lustre/effect
import lustre/element
import lustre/element/html
import model.{type Model}
import modem
import msg
import page
import page/login
import route.{type Route}
import update

fn init(_) {
  let initial_route =
    modem.initial_uri()
    |> result.map(route.from_uri)
    |> result.unwrap(route.NotFound)
    |> msg.ClientLoadedRoute

  let #(model, effect) =
    model.Model(page: page.NotFound)
    |> update.update(initial_route)
}

fn view(model: Model) {
  case model.page {
    page.Login(page) -> login.view(page) |> element.map(msg.Login)
    page.SignUp -> todo
    page.NotFound -> html.text("404 not found")
  }
}

pub fn main() -> Nil {
  let app = lustre.application(init, update.update, view)
  let assert Ok(_) = lustre.start(app, "#app", Nil)
  Nil
}
