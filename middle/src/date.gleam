import birl
import gleam/bool
import gleam/dynamic/decode
import gleam/int
import gleam/json
import gleam/list
import gleam/result
import gleam/string

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
pub fn parse(date: String) {
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
  |> parse()
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
