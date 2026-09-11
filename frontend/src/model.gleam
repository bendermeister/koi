import middle/token.{type Token}
import page
import route.{type Route}

pub type Model {
  Model(page: page.Page, token: Token, init_route: Route)
}
