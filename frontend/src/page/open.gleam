import component
import date
import gleam/dynamic/decode
import gleam/io
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/result
import gleam/string
import icon
import lustre
import lustre/attribute as attr
import lustre/effect
import lustre/element
import lustre/element/html
import lustre/event
import rsvp
import task

type Model {
  Model(tasks: List(task.Task), focus: Option(task.Task), query: String)
}

type Message {
  Message(message: String)
  ErrorMessage(message: String)
  ClientReceivedTasks(tasks: List(task.Task))
  UserUpdatedQuery(query: String)
  UserFocusedTask(task: task.Task)
  UserUpdatedTask(task: task.Task)
  UserDeletedTask(task: task.Task)
}

fn init(_) {
  let effect =
    rsvp.expect_json(decode.list(task.json_decoder()), fn(response) {
      response
      |> result.map(ClientReceivedTasks)
      |> result.unwrap(ErrorMessage("could not load open tasks"))
    })
    |> rsvp.get("/api/open", _)

  let model = Model(tasks: [], focus: None, query: "")

  #(model, effect)
}

fn update(model: Model, message: Message) {
  case message {
    Message(message:) -> {
      io.println(message)
      #(model, effect.none())
    }
    ErrorMessage(message:) -> {
      io.println_error(message)
      #(model, effect.none())
    }
    ClientReceivedTasks(tasks:) -> {
      let tasks =
        model.tasks
        |> list.append(tasks)
        |> list.unique()
        |> list.sort(fn(a, b) { date.compare(a.opened, b.opened) })
      let model = Model(..model, tasks:)
      #(model, effect.none())
    }
    UserUpdatedQuery(query:) -> {
      let model = Model(..model, query:)
      #(model, effect.none())
    }
    UserFocusedTask(task:) -> {
      let focus = Some(task)
      let model = Model(..model, focus:)
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

      let effect =
        rsvp.expect_ok_response(fn(response) {
          response
          |> result.replace(Message("task updated"))
          |> result.unwrap(ErrorMessage("task could not be updated"))
        })
        |> rsvp.post("/api/task/update", task.to_json(task), _)

      let model = Model(..model, tasks:, focus:)
      #(model, effect)
    }
    UserDeletedTask(task:) -> {
      let tasks =
        model.tasks
        |> list.filter(fn(x) { x != task })
      let focus = None
      let effect =
        rsvp.expect_ok_response(fn(response) {
          response
          |> result.replace(Message("task deleted"))
          |> result.unwrap(ErrorMessage("task could not be deleted"))
        })
        |> rsvp.post("/api/task/delete", task.to_json(task), _)

      let model = Model(..model, focus:, tasks:)
      #(model, effect)
    }
  }
}

fn view(model: Model) {
  html.div([attr.class("w-full h-full font-serif flex flex-col")], [
    component.title([], "open"),
    html.div(
      [
        attr.class("w-full h-[calc(100%-2rem)]"),
        attr.class("grid grid-cols-5 gap-2"),
      ],
      [
        html.div(
          [attr.class("col-span-2 w-full h-full overflow-scroll no-scrollbar")],
          [
            controls(model),
          ],
        ),
        html.div(
          [attr.class("col-span-3 w-full h-full overflow-scroll no-scrollbar")],
          [
            case model.focus {
              Some(task) ->
                component.task_edit(task, UserUpdatedTask, UserDeletedTask)
              None -> element.none()
            },
          ],
        ),
      ],
    ),
  ])
}

fn controls(model: Model) {
  let tasks =
    model.tasks
    |> list.filter(fn(task) { string.contains(task.title, model.query) })
    |> list.map(fn(task) {
      html.div(
        [
          attr.class("w-full p-2 clickable rounded-lg"),
          case model.focus == Some(task) {
            True -> attr.class("clickable-focus")
            False -> attr.none()
          },
          event.on_click(UserFocusedTask(task)),
          attr.class("flex flex-row justify-between items-center"),
        ],
        [
          html.div(
            [attr.class("flex flex-row gap-2 justify-start items-center")],
            [icon.task([attr.class("text-rose")]), html.text(task.title)],
          ),
          html.div(
            [attr.class("flex flex-row gap-2 justify-end items-center")],
            [
              task.scheduled
                |> option.map(fn(scheduled) {
                  html.div([], [
                    html.text(scheduled |> date.to_string),
                  ])
                })
                |> option.unwrap(element.none()),
              task.deadline
                |> option.map(fn(deadline) {
                  html.div([attr.class("text-love")], [
                    html.text(deadline |> date.to_string),
                  ])
                })
                |> option.unwrap(element.none()),
            ],
          ),
        ],
      )
    })

  html.div([attr.class("w-full h-full flex flex-col gap-2")], [
    html.div([attr.class("w-full flex flex-row gap-2")], [
      component.input([
        event.on_input(UserUpdatedQuery),
        attr.value(model.query),
        attr.class("flex-grow"),
        attr.placeholder("search..."),
      ]),
      component.button([attr.class("w-24 text-center")], [html.text("new task")]),
    ]),
    ..tasks
  ])
}

pub fn register() {
  lustre.component(init, update, view, [])
  |> lustre.register("koi-page-open")
}

pub fn element() {
  element.element("koi-page-open", [], [])
}
