import gleam/list
import gleam/pair
import gleroglero/outline
import gleroglero/solid
import lustre/attribute.{class}
import lustre/effect
import lustre/element/html.{div}
import lustre/event
import plinth/javascript/global as js

pub type ErrView {
  ErrView(current: Int, errors: List(#(Int, String)))
}

pub type ErrViewMsg {
  Remove(Int)
}

pub fn new() {
  ErrView(current: 0, errors: [])
}

pub fn update(model: ErrView, msg: ErrViewMsg) {
  case msg {
    Remove(id) -> {
      let errors =
        model.errors
        |> list.filter(fn(x) { x.0 != id })
      ErrView(..model, errors:)
    }
  }
}

pub fn add(m: ErrView, error: String) {
  let current = m.current + 1
  let errors = [#(m.current, error), ..m.errors]
  let model = ErrView(current:, errors:)
  let effect =
    effect.from(fn(dispatch) {
      let _ = js.set_timeout(10_000, fn() { dispatch(Remove(m.current)) })
      Nil
    })
  #(model, effect)
}

fn view_error(err: #(Int, String)) {
  div(
    [
      class(
        "relative overflow-hidden w-64 p-2 border rounded border-error bg-white",
      ),
    ],
    [
      html.text(err.1),
      div(
        [
          event.on_click(Remove(err.0)),
          class("text-black absolute top-1 right-1 z-60 w-4 h-4"),
          class("hover:cursor-pointer"),
          class("hover:font-bold"),
        ],
        [solid.x_mark()],
      ),
    ],
  )
}

pub fn view(m: ErrView) {
  let errors =
    m.errors
    |> list.map(view_error)

  div(
    [
      class(
        "h-[90%] absolute overflow-hidden top-2 right-2 flex flex-col gap-4 z-40",
      ),
    ],
    errors,
  )
}
