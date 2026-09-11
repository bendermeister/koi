import gleam/pair
import lustre/effect
import model.{Model}
import msg
import page
import page/login
import page/not_found
import page/register
import route

fn load_route(model, init, args, page, msg) {
  let #(p, e) = init(args)
  let p = page(p)
  let e = effect.map(e, msg)
  let model = Model(..model, page: p)
  #(model, e)
}

fn child_update(model, page, msg, update, page_wrapper, msg_wrapper) {
  let #(page, effect) = update(page, msg)
  let page = page_wrapper(page)
  let effect = effect |> effect.map(msg_wrapper)
  let model = Model(..model, page:)
  #(model, effect)
}

pub fn update(model: model.Model, msg: msg.Msg) {
  case msg {
    msg.ClientLoadedRoute(route:) ->
      case route, model.token {
        route.Register, "" ->
          load_route(model, register.init, Nil, page.Register, msg.Register)

        route.Login, "" ->
          load_route(model, login.init, Nil, page.Login, msg.Login)

        _, "" ->
          route.Login
          |> route.to_push_effect()
          |> pair.new(model, _)

        route.Login, _ ->
          load_route(model, login.init, Nil, page.Login, msg.Login)

        route.Register, _ ->
          load_route(model, register.init, Nil, page.Register, msg.Register)

        route.Logout, _ ->
          route.Login
          |> route.to_push_effect()
          |> pair.new(Model(..model, token: ""), _)

        route.NotFound, _ ->
          load_route(
            model,
            not_found.init,
            model.token,
            page.NotFound,
            msg.NotFound,
          )
      }

    msg.Register(msg) ->
      case model.page {
        page.Register(page) ->
          child_update(
            model,
            page,
            msg,
            register.update,
            page.Register,
            msg.Register,
          )
        _ -> #(model, effect.none())
      }

    msg.NotFound(msg) ->
      case model.page {
        page.NotFound(page) ->
          child_update(
            model,
            page,
            msg,
            not_found.update,
            page.NotFound,
            msg.NotFound,
          )
        _ -> #(model, effect.none())
      }

    msg.Login(msg) ->
      case model.page {
        page.Login(page) ->
          child_update(model, page, msg, login.update, page.Login, msg.Login)
        _ -> #(model, effect.none())
      }
  }
}
