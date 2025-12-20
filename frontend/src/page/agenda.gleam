import api
import component
import date
import gleam/dict
import gleam/io
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/order
import gleam/result
import icon
import lustre
import lustre/attribute as attr
import lustre/effect
import lustre/element
import lustre/element/html
import lustre/event
import task
import time

type Model {
  Model(
    range: date.Range,
    overdue: List(#(date.Date, EntryKind, task.Task)),
    tasks: List(task.Task),
    days: dict.Dict(date.Date, List(#(EntryKind, task.Task))),
    focus: Option(task.Task),
  )
}

type Message {
  ErrorMessage(message: String)
  ClientReceivedTasks(tasks: List(task.Task))
  UserUpdatedStart(start: date.Date)
  UserUpdatedEnd(end: date.Date)
  UserFocusedTask(task: task.Task)
  UserUpdatedTask(task: task.Task)
  UserDeletedTask(task: task.Task)
  Message(message: String)
}

fn init(_) {
  let range = date.range_new(date.now(), date.now() |> date.add_days(6))

  let model =
    Model(range:, days: dict.new(), focus: None, overdue: [], tasks: [])

  let effect = api.agenda(range, ClientReceivedTasks, ErrorMessage)

  #(model, effect)
}

fn tasks_process(
  range: date.Range,
  tasks: List(task.Task),
) -> #(
  List(#(date.Date, EntryKind, task.Task)),
  dict.Dict(date.Date, List(#(EntryKind, task.Task))),
) {
  let #(overdue, rest) =
    tasks
    |> list.flat_map(fn(task) {
      case task.scheduled, task.deadline {
        Some(scheduled), Some(deadline) -> [
          #(scheduled, Scheduled, task),
          #(deadline, Deadline, task),
        ]
        Some(scheduled), None -> [#(scheduled, Scheduled, task)]
        None, Some(deadline) -> [#(deadline, Deadline, task)]
        None, None -> []
      }
    })
    |> list.partition(fn(x) { date.compare(x.0, range.start) == order.Lt })

  let now = date.now()

  let overdue =
    overdue
    |> list.sort(fn(a, b) { date.compare(a.0, b.0) })
    |> list.filter(fn(x) { date.compare(x.0, now) == order.Lt })

  let rest =
    rest
    |> list.group(fn(x) { x.0 })
    |> dict.map_values(fn(_, value) {
      value
      |> list.map(fn(x) { #(x.1, x.2) })
      |> list.sort(fn(a, b) {
        let a = case a.0 {
          Deadline -> { a.1 }.deadline_time
          Scheduled -> { a.1 }.scheduled_start
        }
        let b = case b.0 {
          Deadline -> { b.1 }.deadline_time
          Scheduled -> { b.1 }.scheduled_start
        }

        case a, b {
          Some(a), Some(b) -> time.compare(a, b)
          Some(_), None -> order.Gt
          None, Some(_) -> order.Lt
          None, None -> order.Eq
        }
      })
    })

  #(overdue, rest)
}

fn update(model: Model, message: Message) {
  case message {
    ErrorMessage(message:) -> {
      io.println_error(message)
      #(model, effect.none())
    }
    ClientReceivedTasks(tasks:) -> {
      let #(overdue, days) =
        tasks_process(model.range, tasks)
        |> echo
      let model = Model(..model, overdue:, days:, tasks:)
      #(model, effect.none())
    }
    UserUpdatedStart(start:) -> {
      let end = model.range.end
      let range = date.range_new(start, end)
      let days = dict.new()
      let overdue = []
      let model = Model(range:, overdue:, days:, focus: None, tasks: [])
      let effect = api.agenda(range, ClientReceivedTasks, ErrorMessage)

      #(model, effect)
    }
    UserUpdatedEnd(end:) -> {
      let start = model.range.start
      let range = date.range_new(start, end)
      let days = dict.new()
      let overdue = []
      let model = Model(range:, overdue:, days:, focus: None, tasks: [])
      let effect = api.agenda(range, ClientReceivedTasks, ErrorMessage)

      #(model, effect)
    }
    UserFocusedTask(task:) -> {
      let focus = Some(task)
      let model = Model(..model, focus:)
      #(model, effect.none())
    }
    UserUpdatedTask(task:) -> {
      let effect = api.task_update(task, Message, ErrorMessage)

      let focus = Some(task)

      let tasks =
        model.tasks
        |> list.map(fn(x) {
          case x.id == task.id {
            True -> task
            False -> x
          }
        })

      let #(overdue, days) = tasks_process(model.range, tasks)

      let model = Model(..model, tasks:, overdue:, days:, focus:)
      #(model, effect)
    }
    UserDeletedTask(task:) -> {
      let effect = api.task_delete(task, Message, ErrorMessage)

      let tasks =
        model.tasks
        |> list.filter(fn(x) { x != task })
      let #(overdue, days) = tasks_process(model.range, tasks)

      let model = Model(..model, tasks:, overdue:, days:, focus: None)
      #(model, effect)
    }
    Message(message:) -> {
      io.println(message)
      #(model, effect.none())
    }
  }
}

type EntryKind {
  Scheduled
  Deadline
}

fn controls(model: Model) {
  html.div(
    [attr.class("w-full h-full flex flex-row gap-2 justify-end items-center")],
    [
      component.date_input([], model.range.start |> Some, fn(start) {
        start
        |> option.unwrap(model.range.start)
        |> UserUpdatedStart
      }),
      component.date_input([], model.range.end |> Some, fn(end) {
        end
        |> option.unwrap(model.range.end)
        |> UserUpdatedEnd
      }),
    ],
  )
}

fn view(model: Model) {
  let overdue =
    model.overdue
    |> list.group(fn(x) { x.0 })

  let date_render = fn(date) {
    html.div(
      [attr.class("w-full flex flex-row gap-2 justify-start items-center")],
      [
        html.div([attr.class("border border-iris rounded-full size-4")], []),
        html.div([attr.class("font-bold text-iris w-24")], [
          html.text(date |> date.weekday() |> date.weekday_to_string()),
        ]),
        html.div([attr.class("font-bold text-iris")], [
          html.text(date |> date.to_string_pretty),
        ]),
      ],
    )
  }

  let task_render = fn(kind: EntryKind, task: task.Task) {
    let time = case kind {
      Scheduled ->
        case task.scheduled_start, task.scheduled_end {
          Some(start), Some(end) -> {
            time.to_string(start) <> " - " <> time.to_string(end)
          }
          Some(start), None -> {
            time.to_string(start)
          }
          None, Some(end) -> {
            time.to_string(end)
          }
          None, None -> ""
        }
        |> fn(time) { html.div([], [html.text(time)]) }
      Deadline ->
        task.deadline_time
        |> option.map(time.to_string)
        |> option.unwrap("")
        |> fn(time) { html.div([attr.class("text-love")], [html.text(time)]) }
    }

    html.div(
      [
        attr.class("w-full pl-6 p-2 clickable rounded-lg"),
        attr.class("flex flex-row justify-between items-center"),
        case Some(task) == model.focus {
          True -> attr.class("clickable-focus")
          False -> attr.none()
        },
        event.on_click(UserFocusedTask(task)),
      ],
      [
        html.div(
          [attr.class("flex flex-row gap-2 justify-start items-center")],
          [icon.task([attr.class("text-rose")]), html.text(task.title)],
        ),
        time,
      ],
    )
  }

  let day_render = fn(date, tasks: List(#(EntryKind, task.Task))) {
    let tasks =
      tasks
      |> list.map(fn(task) { task_render(task.0, task.1) })

    html.div([attr.class("w-full flex flex-col gap-2")], [
      date_render(date),
      ..tasks
    ])
  }

  let agenda =
    model.range
    |> date.range_to_list()
    |> list.map(fn(date) {
      let tasks = model.days |> dict.get(date) |> result.unwrap([])

      day_render(date, tasks)
    })

  let overdue =
    model.overdue
    |> list.map(fn(x) { x.0 })
    |> list.unique()
    |> list.map(fn(date) {
      let tasks =
        overdue
        |> dict.get(date)
        |> result.unwrap([])
        |> list.map(fn(x) { #(x.1, x.2) })

      day_render(date, tasks)
    })

  html.div([attr.class("w-full font-serif h-full flex flex-col")], [
    component.title([attr.class("w-full h-[2rem]")], "agenda"),
    html.div([attr.class("w-full h-[calc(100%-2rem)] grid grid-cols-5 gap-2")], [
      html.div(
        [
          attr.class("col-span-2 flex flex-col gap-8"),
          attr.class("w-full h-full overflow-scroll no-scrollbar"),
        ],
        [
          html.div([], [controls(model)]),
          html.div([attr.class("w-full flex flex-col gap-4")], [
            component.subtitle([], "overdue"),
            ..overdue
          ]),
          html.div([attr.class("w-full flex flex-col gap-4")], [
            component.subtitle([], "agenda"),
            ..agenda
          ]),
        ],
      ),
      html.div(
        [
          attr.class("col-span-3 flex flex-col gap-8"),
          attr.class("w-full h-full overflow-scroll"),
        ],
        [
          case model.focus {
            Some(task) ->
              component.task_edit(task, UserUpdatedTask, UserDeletedTask)
            None -> element.none()
          },
        ],
      ),
    ]),
  ])
}

pub fn register() {
  lustre.component(init, update, view, [])
  |> lustre.register("koi-page-agenda")
}

pub fn element() {
  element.element("koi-page-agenda", [], [])
}
