import component/component
import gleam/pair
import lustre
import lustre/effect
import lustre/element
import lustre/element/html
import project
import route

type Model {
  Model(projects: List(project.Project))
}

type Message {
  UserChangedUrl(route: route.Route)
}

fn init(_) {
  Model([])
  |> pair.new(effect.none())
}

fn update(model, message) {
  todo
}

fn view(model) {
  html.div([], [])
}

pub fn register() {
  let component = lustre.component(init, update, view, [])
  lustre.register(component, "koi-page-project-overview")
}

pub fn element() {
  element.element("koi-page-project-overview", [], [])
}
