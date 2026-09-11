import cache
import gleam/option.{None}
import gleam/result
import lustre
import lustre/effect
import lustre/element
import middle/token.{Token}
import model.{type Model, Model}
import modem
import msg
import page
import page/login
import page/not_found
import page/register
import route
import update

fn init(_) {
  let init_route =
    modem.initial_uri()
    |> result.map(route.from_uri)
    |> result.unwrap(route.NotFound)

  let modem_init =
    modem.init(fn(uri) {
      uri
      |> route.from_uri
      |> msg.ClientLoadedRoute
    })

  let token = cache.get("auth/token", token.from_cached)

  let login_effect = modem.push(route.Login |> route.to_string, None, None)
  let #(page, page_effect) = login.init(Nil)
  let page_effect = page_effect |> effect.map(msg.Login)
  let page = page.Login(page)

  case token {
    Ok(token) -> {
      let #(page, _) = not_found.init(token)
      let page = page.NotFound(page)
      let model = Model(page:, token:, init_route:)
      let #(model, effect) =
        update.update(model, msg.ClientLoadedRoute(init_route))
      let effect = effect.batch([modem_init, effect])
      #(model, effect)
    }
    Error(_) -> {
      let effect =
        [login_effect, page_effect, modem_init]
        |> effect.batch()

      let model = Model(page:, token: Token(""), init_route:)

      #(model, effect)
    }
  }
}

fn view(model: Model) {
  case model.page {
    page.Login(page) -> login.view(page) |> element.map(msg.Login)
    page.NotFound(page) -> not_found.view(page) |> element.map(msg.NotFound)
    page.Register(page) -> register.view(page) |> element.map(msg.Register)
  }
}

pub fn main() -> Nil {
  let app = lustre.application(init, update.update, view)
  let assert Ok(_) = lustre.start(app, "#app", Nil)
  Nil
}
