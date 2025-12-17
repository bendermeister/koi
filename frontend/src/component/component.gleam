import lustre/attribute as attr
import lustre/element
import lustre/element/html

pub fn card(attrs: List(attr.Attribute(a)), children: List(element.Element(a))) {
  html.div([attr.class("rounded-lg border border-text p-5"), ..attrs], children)
}

pub fn title(attrs: List(attr.Attribute(a)), text: String) {
  html.div([attr.class("text-xl text-foam"), ..attrs], [
    html.text(text),
  ])
}

pub fn subtitle(attrs: List(attr.Attribute(a)), text: String) {
  html.div([attr.class("text-lg text-rose"), ..attrs], [
    html.text(text),
  ])
}

pub fn input(label, attrs) {
  html.div(
    [attr.class("w-full gap-1 flex flex-col justify-start items-start")],
    [
      html.text(label),
      html.input([
        attr.class("w-full border border-muted rounded-lg py-1 px-2"),
        attr.class("outline-none"),
        ..attrs
      ]),
    ],
  )
}

pub fn button(attrs, children) {
  html.div(
    [
      attr.class("border border-foam px-2 py-1 rounded-lg bg-foam text-base"),
      attr.class("hover:bg-transparent hover:text-text"),
      attr.class("hover:cursor-pointer"),
      attr.class("transition-colors duration-150"),
      ..attrs
    ],
    children,
  )
}

pub fn button_alt(attrs, children) {
  html.div(
    [
      attr.class("border border-love px-2 py-1 rounded-lg bg-love text-base"),
      attr.class("hover:bg-transparent hover:text-text"),
      attr.class("hover:cursor-pointer"),
      attr.class("transition-colors duration-150"),
      ..attrs
    ],
    children,
  )
}

pub fn icon_and_text(attrs, icon, text) {
  html.div(
    [attr.class("flex flex-row justify-start items-center gap-2"), ..attrs],
    [icon, html.div([attr.class("overflow-ellipsis")], [html.text(text)])],
  )
}

pub fn clickable(attrs, children) {
  html.div(
    [
      attr.class("hover:cursor-pointer"),
      attr.class("hover:bg-foam hover:text-base"),
      attr.class("transition-colors duration-150"),
      ..attrs
    ],
    children,
  )
}
