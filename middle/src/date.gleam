import birl
import gleam/bool
import gleam/dynamic/decode
import gleam/int
import gleam/json
import gleam/list
import gleam/order
import gleam/result
import gleam/string

pub type Weekday {
  Mon
  Tue
  Wed
  Thu
  Fri
  Sat
  Sun
}

pub fn weekday_to_string(weekday: Weekday) {
  case weekday {
    Mon -> "monday"
    Tue -> "tuesday"
    Wed -> "wednesday"
    Thu -> "thursday"
    Fri -> "friday"
    Sat -> "saturday"
    Sun -> "sunday"
  }
}

pub fn to_string_pretty(date: Date) {
  let month = case date.month {
    Jan -> "january"
    Feb -> "february"
    Mar -> "march"
    Apr -> "april"
    May -> "may"
    Jun -> "june"
    Jul -> "july"
    Aug -> "august"
    Sep -> "september"
    Oct -> "october"
    Nov -> "november"
    Dec -> "december"
  }
  let year = date.year |> int.to_string |> string.pad_start(4, "0")
  let day = date.day |> int.to_string |> string.pad_start(2, "0")

  day <> ". " <> month <> " " <> year
}

pub fn weekday(date: Date) -> Weekday {
  let birl =
    birl.now()
    |> birl.set_day(birl.Day(date.year, date.month |> month_to_int(), date.day))
    |> birl.weekday()

  case birl {
    birl.Mon -> Mon
    birl.Tue -> Tue
    birl.Wed -> Wed
    birl.Thu -> Thu
    birl.Fri -> Fri
    birl.Sat -> Sat
    birl.Sun -> Sun
  }
}

pub type Month {
  Jan
  Feb
  Mar
  Apr
  May
  Jun
  Jul
  Aug
  Sep
  Oct
  Nov
  Dec
}

pub type Range {
  Range(start: Date, end: Date)
}

pub fn range_new(start: Date, end: Date) {
  let #(start, end) = case compare(start, end) {
    order.Lt -> #(start, end)
    order.Eq -> #(start, end)
    order.Gt -> #(end, start)
  }
  Range(start:, end:)
}

fn range_to_list_(start: Date, end: Date) {
  use <- bool.guard(when: compare(start, end) == order.Gt, return: [])
  [start, ..range_to_list_(add_days(start, 1), end)]
}

pub fn range_to_list(range: Range) {
  let range = range_new(range.start, range.end)
  range_to_list_(range.start, range.end)
}

pub fn range_to_json(range: Range) {
  [#("start", range.start |> to_json), #("end", range.end |> to_json)]
  |> json.object()
}

pub fn range_json_decoder() {
  use start <- decode.field("start", decoder())
  use end <- decode.field("end", decoder())
  range_new(start, end)
  |> decode.success
}

pub fn add_days(date: Date, days: Int) {
  date_resolver(date.year, month_to_int(date.month), date.day + days)
}

fn date_resolver(year: Int, month: Int, day: Int) {
  use <- bool.lazy_guard(when: month < 1, return: fn() {
    date_resolver(year - 1, month + 12, day)
  })
  use <- bool.lazy_guard(when: month > 12, return: fn() {
    date_resolver(year + 1, month - 12, day)
  })
  let assert Ok(month) = month_from_int(month)
  use <- bool.lazy_guard(when: day < 1, return: fn() {
    let #(prev_year, prev_month) = prev_month(year, month)
    let prev_month_length = month_length_(prev_year, prev_month)
    let prev_month = month_to_int(prev_month)
    date_resolver(prev_year, prev_month, day + prev_month_length)
  })
  let month_length = month_length_(year, month)
  use <- bool.lazy_guard(when: month_length < day, return: fn() {
    date_resolver(year, month_to_int(month) + 1, day - month_length)
  })

  Date(year:, month:, day:)
}

fn prev_month(year: Int, month: Month) {
  case month {
    Jan -> #(year - 1, Dec)
    Feb -> #(year, Jan)
    Mar -> #(year, Feb)
    Apr -> #(year, Mar)
    May -> #(year, Apr)
    Jun -> #(year, May)
    Jul -> #(year, Jun)
    Aug -> #(year, Jul)
    Sep -> #(year, Aug)
    Oct -> #(year, Sep)
    Nov -> #(year, Oct)
    Dec -> #(year, Nov)
  }
}

pub type Date {
  Date(year: Int, month: Month, day: Int)
}

/// checks if the given year is a leap year
pub fn is_leap_year(year: Int) {
  case year % 400, year % 100, year % 4 {
    0, _, _ -> True
    _, 0, _ -> False
    _, _, 0 -> True
    _, _, _ -> False
  }
}

fn month_length_(year: Int, month: Month) {
  let is_leap_year = is_leap_year(year)

  case month, is_leap_year {
    Jan, _ -> 31
    Feb, True -> 29
    Feb, False -> 28
    Mar, _ -> 31
    Apr, _ -> 30
    May, _ -> 31
    Jun, _ -> 30
    Jul, _ -> 31
    Aug, _ -> 31
    Sep, _ -> 30
    Oct, _ -> 31
    Nov, _ -> 30
    Dec, _ -> 31
  }
}

/// returns the month length of `date`
pub fn month_length(date date: Date) {
  month_length_(date.year, date.month)
}

/// parses a date string in the format: `YYYY-MM-DD` into a date object
pub fn from_string(date: String) {
  let date = date |> string.trim() |> string.split("-") |> list.map(int.parse)

  let date = case date {
    [Ok(year), Ok(month), Ok(day)] -> #(year, month, day) |> Ok
    _ -> Error(Nil)
  }
  use date <- result.try(date)
  let #(year, month, day) = date

  let month = month_from_int(month)
  use month <- result.try(month)

  let month_length = month_length_(year, month)
  let is_day_in_range = 1 <= day && day <= month_length
  use <- bool.guard(when: !is_day_in_range, return: Error(Nil))

  Date(year:, month:, day:)
  |> Ok
}

fn month_from_int(month: Int) {
  case month {
    1 -> Jan |> Ok
    2 -> Feb |> Ok
    3 -> Mar |> Ok
    4 -> Apr |> Ok
    5 -> May |> Ok
    6 -> Jun |> Ok
    7 -> Jul |> Ok
    8 -> Aug |> Ok
    9 -> Sep |> Ok
    10 -> Oct |> Ok
    11 -> Nov |> Ok
    12 -> Dec |> Ok
    _ -> Error(Nil)
  }
}

pub fn month_to_int(month: Month) {
  case month {
    Jan -> 1
    Feb -> 2
    Mar -> 3
    Apr -> 4
    May -> 5
    Jun -> 6
    Jul -> 7
    Aug -> 8
    Sep -> 9
    Oct -> 10
    Nov -> 11
    Dec -> 12
  }
}

pub fn to_string(date: Date) {
  let Date(year:, month:, day:) = date
  let year = year |> int.to_string |> string.pad_start(4, "0")
  let month = month |> month_to_int |> int.to_string |> string.pad_start(2, "0")
  let day = day |> int.to_string |> string.pad_start(2, "0")
  year <> "-" <> month <> "-" <> day
}

pub fn to_json(date: Date) {
  date |> to_string |> json.string
}

pub fn decoder() {
  use date <- decode.then(decode.string)
  date
  |> from_string()
  |> result.map(decode.success)
  |> result.unwrap(decode.failure(Date(2025, Jan, 1), "Date"))
}

pub fn from_birl(time: birl.Time) {
  let birl.Day(year:, month:, date:) = time |> birl.get_day()
  let assert Ok(month) = month_from_int(month)
  Date(year:, month:, day: date)
}

pub fn now() {
  birl.now()
  |> from_birl
}

pub fn compare(a: Date, b: Date) {
  let a_month = month_to_int(a.month)
  let b_month = month_to_int(b.month)
  int.compare(a.year, b.year)
  |> order.break_tie(int.compare(a_month, b_month))
  |> order.break_tie(int.compare(a.day, b.day))
}
