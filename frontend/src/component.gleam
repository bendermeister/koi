import date
import gleam/option.{type Option}
import lustre/attribute as attr
import lustre/element/html
import lustre/event
import task
import time

pub fn card(attrs, elements) {
  html.div(
    [attr.class("border border-overlay rounded-lg p-5"), ..attrs],
    elements,
  )
}

pub fn input(attrs) {
  html.input([
    attr.class("w-full focus:outline-none p-2 border-muted border rounded-lg"),
    ..attrs
  ])
}

pub fn labeled_input(attrs, label) {
  html.div([attr.class("w-full flex flex-col gap-2 items-start")], [
    html.div([], [html.text(label)]),
    input(attrs),
  ])
}

pub fn labeled_time_input(attrs, label, value, handler) {
  html.div([attr.class("w-full flex flex-col gap-2 items-start")], [
    html.div([], [html.text(label)]),
    time_input(attrs, value, handler),
  ])
}

pub fn time_input(attrs, value: Option(time.Time), handler) {
  let value = value |> option.map(time.to_string) |> option.unwrap("")
  let handler = fn(date) {
    date |> time.from_string() |> option.from_result() |> handler
  }
  input([
    attr.type_("time"),
    attr.value(value),
    event.on_change(handler),
    ..attrs
  ])
}

pub fn date_input(attrs, value: Option(date.Date), handler) {
  let value = value |> option.map(date.to_string) |> option.unwrap("")
  let handler = fn(date) {
    date |> date.from_string() |> option.from_result() |> handler
  }
  input([
    attr.type_("date"),
    attr.value(value),
    event.on_change(handler),
    ..attrs
  ])
}

pub fn labeled_date_input(attrs, label, value, handler) {
  html.div([attr.class("w-full flex flex-col gap-2 items-start")], [
    html.div([], [html.text(label)]),
    date_input(attrs, value, handler),
  ])
}

pub fn button_bad(attrs, elements) {
  html.div(
    [
      attr.class("p-2 bg-love border-love border rounded-lg text-base"),
      attr.class("hover:bg-transparent hover:text-love hover:cursor-pointer"),
      attr.class("transition-color duration-100"),
      ..attrs
    ],
    elements,
  )
}

pub fn button(attrs, elements) {
  html.div(
    [
      attr.class("p-2 bg-foam border-foam border rounded-lg text-base"),
      attr.class("hover:bg-transparent hover:text-foam hover:cursor-pointer"),
      attr.class("transition-color duration-100"),
      ..attrs
    ],
    elements,
  )
}

pub fn title(attrs, title) {
  html.div([attr.class("text-2xl font-serif text-foam"), ..attrs], [
    html.text(title),
  ])
}

pub fn subtitle(attrs, title) {
  html.div([attr.class("text-xl font-serif text-rose"), ..attrs], [
    html.text(title),
  ])
}

pub fn hr(attrs) {
  html.div([attr.class("bg-overlay w-full h-[1px]"), ..attrs], [])
}

pub fn label_textarea(attrs, label, value) {
  html.div([attr.class("w-full flex flex-col gap-2 items-start")], [
    html.div([], [html.text(label)]),
    html.textarea(
      [
        attr.class(
          "w-full focus:outline-none p-2 border-muted border rounded-lg",
        ),
        ..attrs
      ],
      value,
    ),
  ])
}

pub fn task_edit(task: task.Task, task_update, task_delete) {
  html.div([attr.class("w-full h-full flex flex-col gap-2")], [
    html.div([attr.class("w-full flex flex-row justify-between items-center")], [
      title([], task.title),
      html.div([attr.class("text-muted")], [
        html.text("opened: " <> task.opened |> date.to_string),
      ]),
    ]),
    labeled_input(
      [
        attr.value(task.title),
        event.on_change(fn(title) { task.Task(..task, title:) |> task_update }),
      ],
      "title",
    ),
    label_textarea(
      [
        event.on_change(fn(body) { task.Task(..task, body:) |> task_update }),
      ],
      "body",
      task.body,
    ),
    subtitle([], "scheduled"),
    html.div([attr.class("grid grid-cols-3 gap-2")], [
      labeled_date_input([], "date", task.scheduled, fn(scheduled) {
        task.Task(..task, scheduled:) |> task_update
      }),
      labeled_time_input([], "start", task.scheduled_start, fn(scheduled_start) {
        task.Task(..task, scheduled_start:) |> task_update
      }),
      labeled_time_input([], "end", task.scheduled_end, fn(scheduled_end) {
        task.Task(..task, scheduled_end:) |> task_update
      }),
    ]),
    subtitle([], "deadline"),
    html.div([attr.class("grid grid-cols-2 gap-2")], [
      labeled_date_input([], "date", task.deadline, fn(deadline) {
        task.Task(..task, deadline:) |> task_update
      }),
      labeled_time_input([], "time", task.deadline_time, fn(deadline_time) {
        task.Task(..task, deadline_time:) |> task_update
      }),
    ]),
    html.div(
      [attr.class("w-full pt-2 flex flex-row justify-end gap-2 items-center")],
      [
        button([attr.class("w-24 text-center")], [html.text("close")]),
        button_bad(
          [attr.class("w-24 text-center"), event.on_click(task_delete(task))],
          [
            html.text("delete"),
          ],
        ),
      ],
    ),
  ])
}
