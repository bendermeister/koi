import lustre/effect
import model.{Model}
import msg
import page
import page/login
import route

pub fn update(model: model.Model, msg: msg.Msg) {
  case msg {
    msg.Login(msg) ->
      case model.page {
        page.Login(page) -> {
          let #(page, effect) = login.update(page, msg)
          let effect = effect |> effect.map(msg.Login)
          let page = page.Login(page)
          #(Model(page:), effect)
        }
        page.SignUp -> todo
        page.NotFound -> todo
      }
    msg.SignUp -> todo
    msg.ClientLoadedRoute(route:) ->
      case route {
        route.Login -> {
          let #(page, effect) = login.init()
          let page = page.Login(page)
          let effect = effect |> effect.map(msg.Login)
          #(Model(page:), effect)
        }
        route.Logout -> todo
        route.SignUp -> todo
        route.NotFound -> todo
      }
  }
}
