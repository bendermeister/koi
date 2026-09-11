import gleroglero/outline
import lustre/attribute.{class} as attr
import lustre/element/html.{div, input}
import lustre/event

pub fn logo() {
  div([class("font-bold text-2xl")], [
    html.text("koi"),
  ])
}

pub fn labeled(label, item) {
  div([class("w-full flex flex-col gap-1")], [
    div(
      [
        class("text-xs text-gray-2 "),
        class("w-full flex flex-row justify-start items-center"),
      ],
      [
        html.text(label),
      ],
    ),
    div([class("w-full flex flex-row justify-start items-center")], [item]),
  ])
}

pub fn input_password(
  password: String,
  visible: Bool,
  handler: fn(String) -> a,
  visible_change: a,
) {
  let visible = case visible {
    True -> attr.type_("text")
    False -> attr.type_("password")
  }
  div([class("w-full relative")], [
    input([
      class("w-full p-1 rounded border border-gray-2"),
      class("focus:outline-none"),
      class("focus:border-acc-2 focus:ring-1 focus-ring-acc-2"),
      attr.value(password),
      event.on_input(handler),
      visible,
    ]),
    div(
      [
        class("hover:cursor-pointer"),
        class("absolute top-[0.35rem] right-1 z-20 w-6 h-6"),
        event.on_click(visible_change),
      ],
      [outline.eye()],
    ),
  ])
}

pub fn input_text(value: String, handler: fn(String) -> a) {
  div([class("w-full")], [
    input([
      attr.type_("text"),
      class("w-full p-1 rounded border border-gray-2"),
      class("focus:outline-none"),
      class("focus:border-acc-2 focus:ring-1 focus-ring-acc-2"),
      attr.value(value),
      event.on_input(handler),
    ]),
  ])
}

pub fn input_email(value: String, handler: fn(String) -> a) {
  div([class("w-full")], [
    input([
      attr.type_("email"),
      class("w-full p-1 rounded border border-gray-2"),
      class("focus:outline-none"),
      class("focus:border-acc-2 focus:ring-1 focus-ring-acc-2"),
      attr.value(value),
      event.on_input(handler),
    ]),
  ])
}

pub fn button(text: String, msg) {
  div(
    [
      class("w-full p-1 flex justify-center items-center"),
      class("border border-2 rounded border-acc-2"),
      class("border border-2 rounded border-acc-2"),
      class("text-acc-2"),
      class("hover:cursor-pointer"),
      class("hover:bg-acc-2 hover:text-white"),
      class("transition-all transition-50"),
      event.on_click(msg),
    ],
    [
      html.text(text),
    ],
  )
}
