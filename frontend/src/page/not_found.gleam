import lustre/effect
import lustre/element/html

pub type Model {
  Model
}

pub type Msg {
  Msg
}

pub fn init(_) {
  #(Model, effect.none())
}

pub fn update(model: Model, msg: Msg) {
  #(Model, effect.none())
}

pub fn view(model: Model) {
  html.text("Not Found")
}
