import birl
import gleam/bool
import gleam/dynamic/decode
import gleam/int
import gleam/json
import gleam/list
import gleam/order
import gleam/result
import gleam/string

pub type Time {
  Time(hour: Int, minute: Int)
}

pub fn to_string(time: Time) {
  let Time(hour:, minute:) = time
  let hour = hour |> int.to_string |> string.pad_start(2, "0")
  let minute = minute |> int.to_string |> string.pad_start(2, "0")
  hour <> ":" <> minute
}

pub fn from_string(time: String) {
  let time =
    time
    |> string.trim()
    |> string.split(":")
    |> list.map(int.parse)

  let time = case time {
    [Ok(hour), Ok(minute)] -> Ok(#(hour, minute))
    [Ok(hour), Ok(minute), Ok(_)] -> Ok(#(hour, minute))
    _ -> Error(Nil)
  }
  use time <- result.try(time)
  let #(hour, minute) = time

  let is_hour_valid = is_hour_valid(hour)
  let is_minute_valid = is_minute_valid(minute)

  use <- bool.guard(when: !is_hour_valid, return: Error(Nil))
  use <- bool.guard(when: !is_minute_valid, return: Error(Nil))

  Time(hour:, minute:)
  |> Ok
}

fn is_minute_valid(minute: Int) {
  0 <= minute && minute <= 59
}

fn is_hour_valid(hour: Int) {
  0 <= hour && hour <= 23
}

pub fn to_json(time: Time) {
  time |> to_string |> json.string
}

pub fn decoder() {
  use time <- decode.then(decode.string)
  time
  |> from_string()
  |> result.map(decode.success)
  |> result.unwrap(decode.failure(Time(0, 0), "Time"))
}

pub fn from_birl(time: birl.Time) {
  let birl.TimeOfDay(hour:, minute:, second: _, milli_second: _) =
    time |> birl.get_time_of_day()
  Time(hour, minute)
}

pub fn now() {
  birl.now() |> from_birl()
}

pub fn compare(a: Time, b: Time) {
  int.compare(a.hour, b.hour)
  |> order.break_tie(int.compare(a.minute, b.minute))
}
