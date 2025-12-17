import component/component
import gleam/bool
import gleam/dynamic/decode
import gleam/io
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/string
import icon
import lustre
import lustre/attribute as attr
import lustre/effect
import lustre/element
import lustre/element/html
import lustre/event
import rsvp
import tag
import user
import util

type Model {
  Model(
    tags: List(tag.Tag),
    current_tag: Option(tag.Tag),
    new_tag: Option(tag.Tag),
    query: String,
  )
}

type Message {
  UserCreatedNewTag
  UserUpdatedNewTag(tag: tag.Tag)
  UserSavedNewTag(tag: tag.Tag)
  ClientReceivedTags(tags: List(tag.Tag))
  ClientReceivedTag(tag: tag.Tag)
  UserUpdatedTag(tag: tag.Tag)
  UserSelectedTag(tag: tag.Tag)
  UserUpdatedQuery(query: String)
  UserDeletedTag(tag: tag.Tag)
  NotLoggedIn
  MessageError(message: String)
  MessageInfo(message: String)
}

fn init(_) {
  let effect =
    util.json_handler(
      decode.list(tag.json_decoder()),
      ClientReceivedTags,
      NotLoggedIn,
      MessageError,
    )
    |> rsvp.get("/api/tag/fetch/all", _)
  let model = Model(tags: [], current_tag: None, new_tag: None, query: "")

  #(model, effect)
}

fn update(model: Model, message: Message) {
  case message {
    UserCreatedNewTag -> {
      use <- bool.guard(when: option.is_some(model.new_tag), return: #(
        model,
        effect.none(),
      ))
      let new_tag =
        tag.Tag(id: tag.Id("new"), name: "new tag", owner: user.Id("me"))
        |> Some()

      let model = Model(..model, new_tag:, current_tag: new_tag)
      #(model, effect.none())
    }
    UserUpdatedNewTag(tag:) -> {
      let new_tag = Some(tag)
      let current_tag = new_tag
      let model = Model(..model, new_tag:, current_tag:)
      #(model, effect.none())
    }
    UserSavedNewTag(tag:) -> {
      let effect =
        util.json_handler(
          tag.json_decoder(),
          ClientReceivedTag,
          NotLoggedIn,
          MessageError,
        )
        |> rsvp.post("/api/tag/new", tag.to_json(tag), _)
      let model = Model(..model, current_tag: None, new_tag: None)
      #(model, effect)
    }
    ClientReceivedTags(tags:) -> {
      let tags =
        model.tags
        |> list.append(tags)
        |> list.unique()
        |> list.sort(fn(a, b) { string.compare(a.name, b.name) })
      let model = Model(..model, tags:)
      #(model, effect.none())
    }
    ClientReceivedTag(tag:) -> {
      let tags =
        [tag, ..model.tags]
        |> list.unique()
        |> list.sort(fn(a, b) { string.compare(a.name, b.name) })
      let model = Model(..model, tags:)
      #(model, effect.none())
    }
    UserUpdatedTag(tag:) -> {
      let effect =
        util.ok_handler(MessageInfo("tag updated"), NotLoggedIn, MessageError)
        |> rsvp.post("/api/tag/update", tag.to_json(tag), _)

      let tags =
        model.tags
        |> list.map(fn(x) {
          case x.id == tag.id {
            True -> tag
            False -> x
          }
        })

      let model = Model(..model, tags:, current_tag: Some(tag))
      #(model, effect)
    }
    UserSelectedTag(tag:) -> {
      let current_tag = Some(tag)
      let model = Model(..model, current_tag:)
      #(model, effect.none())
    }
    UserUpdatedQuery(query:) -> {
      let model = Model(..model, query:)
      #(model, effect.none())
    }
    UserDeletedTag(tag:) -> {
      let effect =
        util.ok_handler(MessageInfo("tag deleted"), NotLoggedIn, MessageError)
        |> rsvp.post("/api/tag/delete", tag.id |> tag.id_to_json(), _)
      let tags =
        model.tags
        |> list.filter(fn(x) { x != tag })
      let model = Model(..model, tags:, current_tag: None)
      #(model, effect)
    }
    NotLoggedIn -> {
      let effect = util.not_logged_in()
      #(model, effect)
    }
    MessageError(message:) -> {
      io.println_error(message)
      #(model, effect.none())
    }
    MessageInfo(message:) -> {
      io.println(message)
      #(model, effect.none())
    }
  }
}

fn view(model: Model) {
  let tags =
    model.tags
    |> list.append(
      model.new_tag |> option.map(fn(x) { [x] }) |> option.unwrap([]),
    )
    |> list.filter(fn(tag) { string.contains(tag.name, model.query) })
    |> list.map(fn(tag) {
      html.div(
        [
          attr.class("w-full px-1 py-2 rounded-lg clickable"),
          event.on_click(UserSelectedTag(tag)),
          case Some(tag) == model.current_tag {
            True -> attr.class("clickable-focus")
            False -> attr.none()
          },
        ],
        [
          component.icon_and_text(
            [],
            icon.tag([attr.class("size-5")]),
            tag.name,
          ),
        ],
      )
    })

  html.div([attr.class("w-full h-full grid grid-cols-2 gap-2")], [
    component.card(
      [attr.class("w-full h-full overflow-scroll flex flex-col gap-2")],
      [
        html.div([attr.class("flex flex-row gap-4")], [
          html.div([attr.class("flex-grow")], [
            component.input("search", [
              attr.value(model.query),
              attr.placeholder("..."),
              event.on_input(UserUpdatedQuery),
            ]),
          ]),
          html.div([attr.class("w-fit flex justify-start items-end")], [
            component.button(
              [attr.class("w-fit h-fit"), event.on_click(UserCreatedNewTag)],
              [
                component.icon_and_text(
                  [],
                  icon.tag([attr.class("size-5")]),
                  "new tag",
                ),
              ],
            ),
          ]),
        ]),
        ..tags
      ],
    ),
    component.card([attr.class("w-full h-full overflow-scroll")], [
      tag_card(model),
    ]),
  ])
}

fn tag_card(model: Model) -> element.Element(Message) {
  case model.current_tag, model.new_tag {
    Some(current_tag), Some(new_tag) if current_tag == new_tag ->
      tag_new_edit(new_tag)
    Some(tag), _ -> tag_edit(tag)
    _, _ -> tag_unselected()
  }
}

fn tag_new_edit(tag: tag.Tag) {
  html.div([attr.class("w-full h-full flex flex-col gap-2")], [
    component.title([], "new tag"),
    component.input("name", [
      attr.value(tag.name),
      event.on_change(fn(name) { tag.Tag(..tag, name:) |> UserUpdatedNewTag }),
    ]),
    html.div([attr.class("w-full flex flex-row justify-end items-center")], [
      component.button([event.on_click(UserSavedNewTag(tag))], [
        html.text("save"),
      ]),
    ]),
  ])
}

fn tag_edit(tag: tag.Tag) {
  html.div([attr.class("w-full h-full flex flex-col gap-2")], [
    component.title([], "tag edit"),
    component.input("name", [
      attr.value(tag.name),
      event.on_change(fn(name) { tag.Tag(..tag, name:) |> UserUpdatedTag }),
    ]),
    html.div([attr.class("w-full flex flex-row justify-end items-center")], [
      component.button_alt([event.on_click(UserDeletedTag(tag))], [
        html.text("delete"),
      ]),
    ]),
  ])
}

fn tag_unselected() {
  html.div(
    [attr.class("w-full h-full flex justify-center items-center text-muted")],
    [html.text("select a tag to get started")],
  )
}

pub fn register() {
  lustre.component(init, update, view, [])
  |> lustre.register("koi-page-tag")
}

pub fn element() {
  element.element("koi-page-tag", [], [])
}
