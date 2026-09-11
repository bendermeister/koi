import page
import route.{type Route}

pub type Model {
  Model(page: page.Page, token: String, init_route: Route)
}
