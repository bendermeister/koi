import lustre/attribute as attr
import lustre/element/svg

pub fn inbox(attrs) {
  svg.svg(
    [
      attr.attribute("xmlns", "http://www.w3.org/2000/svg"),
      attr.attribute("fill", "none"),
      attr.attribute("viewBox", "0 0 24 24"),
      attr.attribute("stroke-width", "1.5"),
      attr.attribute("stroke", "currentColor"),
      attr.class("size-6"),
      ..attrs
    ],
    [
      svg.path([
        attr.attribute("stroke-linecap", "round"),
        attr.attribute("stroke-linejoin", "round"),
        attr.attribute(
          "d",
          "M9 3.75H6.912a2.25 2.25 0 0 0-2.15 1.588L2.35 13.177a2.25 2.25 0 0 0-.1.661V18a2.25 2.25 0 0 0 2.25 2.25h15A2.25 2.25 0 0 0 21.75 18v-4.162c0-.224-.034-.447-.1-.661L19.24 5.338a2.25 2.25 0 0 0-2.15-1.588H15M2.25 13.5h3.86a2.25 2.25 0 0 1 2.012 1.244l.256.512a2.25 2.25 0 0 0 2.013 1.244h3.218a2.25 2.25 0 0 0 2.013-1.244l.256-.512a2.25 2.25 0 0 1 2.013-1.244h3.859M12 3v8.25m0 0-3-3m3 3 3-3",
        ),
      ]),
    ],
  )
}

pub fn archive(attrs) {
  svg.svg(
    [
      attr.attribute("xmlns", "http://www.w3.org/2000/svg"),
      attr.attribute("fill", "none"),
      attr.attribute("viewBox", "0 0 24 24"),
      attr.attribute("stroke-width", "1.5"),
      attr.attribute("stroke", "currentColor"),
      attr.class("size-6"),
      ..attrs
    ],
    [
      svg.path([
        attr.attribute("stroke-linecap", "round"),
        attr.attribute("stroke-linejoin", "round"),
        attr.attribute(
          "d",
          "m20.25 7.5-.625 10.632a2.25 2.25 0 0 1-2.247 2.118H6.622a2.25 2.25 0 0 1-2.247-2.118L3.75 7.5M10 11.25h4M3.375 7.5h17.25c.621 0 1.125-.504 1.125-1.125v-1.5c0-.621-.504-1.125-1.125-1.125H3.375c-.621 0-1.125.504-1.125 1.125v1.5c0 .621.504 1.125 1.125 1.125Z",
        ),
      ]),
    ],
  )
}

pub fn agenda(attrs) {
  svg.svg(
    [
      attr.attribute("xmlns", "http://www.w3.org/2000/svg"),
      attr.attribute("fill", "none"),
      attr.attribute("viewBox", "0 0 24 24"),
      attr.attribute("stroke-width", "1.5"),
      attr.attribute("stroke", "currentColor"),
      attr.class("size-6"),
      ..attrs
    ],
    [
      svg.path([
        attr.attribute("stroke-linecap", "round"),
        attr.attribute("stroke-linejoin", "round"),
        attr.attribute(
          "d",
          "M6.75 3v2.25M17.25 3v2.25M3 18.75V7.5a2.25 2.25 0 0 1 2.25-2.25h13.5A2.25 2.25 0 0 1 21 7.5v11.25m-18 0A2.25 2.25 0 0 0 5.25 21h13.5A2.25 2.25 0 0 0 21 18.75m-18 0v-7.5A2.25 2.25 0 0 1 5.25 9h13.5A2.25 2.25 0 0 1 21 11.25v7.5",
        ),
      ]),
    ],
  )
}

pub fn calendar(attrs) {
  svg.svg(
    [
      attr.attribute("xmlns", "http://www.w3.org/2000/svg"),
      attr.attribute("fill", "none"),
      attr.attribute("viewBox", "0 0 24 24"),
      attr.attribute("stroke-width", "1.5"),
      attr.attribute("stroke", "currentColor"),
      attr.class("size-6"),
      ..attrs
    ],
    [
      svg.path([
        attr.attribute("stroke-linecap", "round"),
        attr.attribute("stroke-linejoin", "round"),
        attr.attribute(
          "d",
          "M6.75 3v2.25M17.25 3v2.25M3 18.75V7.5a2.25 2.25 0 0 1 2.25-2.25h13.5A2.25 2.25 0 0 1 21 7.5v11.25m-18 0A2.25 2.25 0 0 0 5.25 21h13.5A2.25 2.25 0 0 0 21 18.75m-18 0v-7.5A2.25 2.25 0 0 1 5.25 9h13.5A2.25 2.25 0 0 1 21 11.25v7.5m-9-6h.008v.008H12v-.008ZM12 15h.008v.008H12V15Zm0 2.25h.008v.008H12v-.008ZM9.75 15h.008v.008H9.75V15Zm0 2.25h.008v.008H9.75v-.008ZM7.5 15h.008v.008H7.5V15Zm0 2.25h.008v.008H7.5v-.008Zm6.75-4.5h.008v.008h-.008v-.008Zm0 2.25h.008v.008h-.008V15Zm0 2.25h.008v.008h-.008v-.008Zm2.25-4.5h.008v.008H16.5v-.008Zm0 2.25h.008v.008H16.5V15Z",
        ),
      ]),
    ],
  )
}

pub fn task(attrs) {
  svg.svg(
    [
      attr.attribute("xmlns", "http://www.w3.org/2000/svg"),
      attr.attribute("fill", "none"),
      attr.attribute("viewBox", "0 0 24 24"),
      attr.attribute("stroke-width", "1.5"),
      attr.attribute("stroke", "currentColor"),
      attr.class("size-6"),
      ..attrs
    ],
    [
      svg.path([
        attr.attribute("stroke-linecap", "round"),
        attr.attribute("stroke-linejoin", "round"),
        attr.attribute(
          "d",
          "m16.862 4.487 1.687-1.688a1.875 1.875 0 1 1 2.652 2.652L10.582 16.07a4.5 4.5 0 0 1-1.897 1.13L6 18l.8-2.685a4.5 4.5 0 0 1 1.13-1.897l8.932-8.931Zm0 0L19.5 7.125M18 14v4.75A2.25 2.25 0 0 1 15.75 21H5.25A2.25 2.25 0 0 1 3 18.75V8.25A2.25 2.25 0 0 1 5.25 6H10",
        ),
      ]),
    ],
  )
}

pub fn open(attrs) {
  svg.svg(
    [
      attr.attribute("xmlns", "http://www.w3.org/2000/svg"),
      attr.attribute("fill", "none"),
      attr.attribute("viewBox", "0 0 24 24"),
      attr.attribute("stroke-width", "1.5"),
      attr.attribute("stroke", "currentColor"),
      attr.class("size-6"),
      ..attrs
    ],
    [
      svg.path([
        attr.attribute("stroke-linecap", "round"),
        attr.attribute("stroke-linejoin", "round"),
        attr.attribute(
          "d",
          "M2.25 13.5h3.86a2.25 2.25 0 0 1 2.012 1.244l.256.512a2.25 2.25 0 0 0 2.013 1.244h3.218a2.25 2.25 0 0 0 2.013-1.244l.256-.512a2.25 2.25 0 0 1 2.013-1.244h3.859m-19.5.338V18a2.25 2.25 0 0 0 2.25 2.25h15A2.25 2.25 0 0 0 21.75 18v-4.162c0-.224-.034-.447-.1-.661L19.24 5.338a2.25 2.25 0 0 0-2.15-1.588H6.911a2.25 2.25 0 0 0-2.15 1.588L2.35 13.177a2.25 2.25 0 0 0-.1.661Z",
        ),
      ]),
    ],
  )
}
