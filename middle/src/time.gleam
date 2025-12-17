import birl
import gleam/bool
import gleam/dynamic/decode
import gleam/int
import gleam/json
import gleam/list
import gleam/result
import gleam/string

pub type Time {
  Time(hour: Int, minute: Int, second: Int)
}

pub fn to_string(time: Time) {
  let Time(hour:, minute:, second:) = time
  let hour = hour |> int.to_string |> string.pad_start(2, "0")
  let minute = minute |> int.to_string |> string.pad_start(2, "0")
  let seconds = second |> int.to_string |> string.pad_start(2, "0")
  hour <> ":" <> minute <> ":" <> seconds
}

pub fn parse(time: String) {
  let time =
    time
    |> string.trim()
    |> string.split(":")
    |> list.map(int.parse)

  let time = case time {
    [Ok(hour), Ok(minute), Ok(seconds)] -> Ok(#(hour, minute, seconds))
    _ -> Error(Nil)
  }
  use time <- result.try(time)
  let #(hour, minute, second) = time

  let is_hour_valid = is_hour_valid(hour)
  let is_minute_valid = is_minute_valid(minute)
  let is_second_valid = is_second_valid(second)

  use <- bool.guard(when: !is_hour_valid, return: Error(Nil))
  use <- bool.guard(when: !is_minute_valid, return: Error(Nil))
  use <- bool.guard(when: !is_second_valid, return: Error(Nil))

  Time(hour:, minute:, second:)
  |> Ok
}

fn is_minute_valid(minute: Int) {
  0 <= minute && minute <= 59
}

fn is_second_valid(second: Int) {
  0 <= second && second <= 59
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
  |> parse()
  |> result.map(decode.success)
  |> result.unwrap(decode.failure(Time(0, 0, 0), "Time"))
}

pub fn from_birl(time: birl.Time) {
  let birl.TimeOfDay(hour:, minute:, second:, milli_second: _) =
    time |> birl.get_time_of_day()
  Time(hour, minute, second)
}

pub fn now() {
  birl.now() |> from_birl()
}
