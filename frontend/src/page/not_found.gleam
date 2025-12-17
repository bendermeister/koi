import lustre/attribute as attr
import lustre/element/html

pub fn element() {
  html.div([attr.class("w-screen h-screen flex justify-center items-center")], [
    html.text("not found"),
  ])
}
