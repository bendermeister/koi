import api
import component
import date
import gleam/io
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/order
import icon
import lustre
import lustre/attribute as attr
import lustre/effect
import lustre/element
import lustre/element/html
import lustre/event
import task

type Model {
  Model(tasks: List(task.Task), focus: Option(task.Task))
}

type Message {
  UserDeletedTask(task: task.Task)
  UserCreatedNewTask
  ErrorMessage(message: String)
  ClientReceivedTasks(tasks: List(task.Task))
  UserFocusedTask(task: task.Task)
  ClientReceivedNewTask(task: task.Task)
  UserUpdatedTask(task: task.Task)
  Message(message: String)
}

fn init(_) {
  let model = Model(tasks: [], focus: None)

  let effect = api.inbox(ClientReceivedTasks, ErrorMessage)

  #(model, effect)
}

fn update(model: Model, message: Message) {
  case message {
    UserCreatedNewTask -> {
      let effect = api.task_new(ClientReceivedNewTask, ErrorMessage)

      #(model, effect)
    }
    ErrorMessage(message:) -> {
      io.println_error(message)
      #(model, effect.none())
    }
    ClientReceivedTasks(tasks:) -> {
      let tasks =
        list.append(model.tasks, tasks)
        |> list.unique()
        |> list.sort(fn(a, b) {
          date.compare(a.opened, b.opened) |> order.negate()
        })

      let focus = tasks |> list.first() |> option.from_result()

      let focus = case model.focus {
        Some(focus) -> Some(focus)
        None -> focus
      }

      let model = Model(tasks:, focus:)
      #(model, effect.none())
    }
    ClientReceivedNewTask(task:) -> {
      let tasks =
        [task, ..model.tasks]
        |> list.unique()
        |> list.sort(fn(a, b) {
          date.compare(a.opened, b.opened) |> order.negate()
        })

      let focus = Some(task)
      let model = Model(tasks:, focus:)
      #(model, effect.none())
    }
    UserFocusedTask(task:) -> {
      let model = Model(..model, focus: Some(task))
      #(model, effect.none())
    }
    UserUpdatedTask(task:) -> {
      let focus = Some(task)
      let tasks =
        model.tasks
        |> list.map(fn(x) {
          case x.id == task.id {
            True -> task
            False -> x
          }
        })

      let effect = api.task_update(task, Message, ErrorMessage)

      let model = Model(tasks:, focus:)
      #(model, effect)
    }
    Message(message:) -> {
      io.println(message)
      #(model, effect.none())
    }
    UserDeletedTask(task:) -> {
      let focus = None
      let tasks =
        model.tasks
        |> list.filter(fn(x) { x != task })
      let model = Model(tasks:, focus:)

      let effect = api.task_delete(task, Message, ErrorMessage)
      #(model, effect)
    }
  }
}

fn task(model: Model, task: task.Task) {
  html.div(
    [
      attr.class("w-full clickable p-2 flex flex-row gap-2 rounded-lg"),
      case model.focus == Some(task) {
        True -> attr.class("clickable-focus")
        False -> attr.none()
      },
      event.on_click(UserFocusedTask(task)),
    ],
    [
      icon.task([attr.class("text-rose")]),
      html.text(task.title),
    ],
  )
}

fn view(model: Model) {
  let tasks =
    model.tasks
    |> list.map(task(model, _))
    |> list.intersperse(html.hr([attr.class("text-overlay")]))

  html.div([attr.class("w-full h-full flex flex-col gap-2 font-serif")], [
    component.title([], "inbox"),
    html.div([attr.class("grid grid-cols-5 gap-2 w-full h-[calc(100%-3rem)]")], [
      html.div(
        [
          attr.class(
            "flex flex-col h-full w-full col-span-2 overflow-scroll no-scrollbar",
          ),
        ],
        [
          html.div(
            [
              attr.class(
                "h-[3rem] w-full flex flex-row items-center justify-end",
              ),
            ],
            [
              component.button(
                [
                  event.on_click(UserCreatedNewTask),
                  attr.class("flex flex-row gap-2 justify-start items-center"),
                ],
                [icon.task([]), html.text("new task")],
              ),
            ],
          ),
          html.div(
            [
              attr.class("h-[calc(100%-3rem)] w-full"),
              attr.class("flex flex-col gap-2 py-4"),
            ],
            tasks,
          ),
        ],
      ),

      component.card([attr.class("w-full col-span-3 h-full overflow-scroll")], [
        case model.focus {
          Some(task) ->
            component.task_edit(task, UserUpdatedTask, UserDeletedTask)
          None ->
            html.div(
              [
                attr.class(
                  "w-full h-full flex justify-center items-center text-muted",
                ),
              ],
              [html.text("select a task")],
            )
        },
      ]),
    ]),
  ])
}

pub fn register() {
  lustre.component(init, update, view, [])
  |> lustre.register("koi-page-inbox")
}

pub fn element() {
  element.element("koi-page-inbox", [], [])
}
