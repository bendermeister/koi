import birl
import date
import gleam/dynamic/decode
import gleam/json
import gleam/result
import gleam/string
import time

pub type DateTime {
  DateTime(date: date.Date, time: time.Time)
}

pub fn parse(date_time: String) {
  let date_time = date_time |> string.trim() |> string.split_once(" ")
  use date_time <- result.try(date_time)
  let #(date, time) = date_time
  let date = date |> date.parse()
  use date <- result.try(date)
  let time = time |> time.parse()
  use time <- result.try(time)
  DateTime(date:, time:)
  |> Ok
}

pub fn to_string(date_time: DateTime) {
  let date = date_time.date |> date.to_string
  let time = date_time.time |> time.to_string
  date <> " " <> time
}

pub fn to_json(date_time: DateTime) {
  date_time |> to_string |> json.string()
}

pub fn decoder() {
  use date_time <- decode.then(decode.string)
  date_time
  |> parse()
  |> result.map(decode.success)
  |> result.unwrap(decode.failure(
    DateTime(date.Date(0, date.Jan, 0), time.Time(0, 0, 0)),
    "DateTime",
  ))
}

pub fn from_birl(time: birl.Time) {
  let date = date.from_birl(time)
  let time = time.from_birl(time)
  DateTime(date:, time:)
}

pub fn now() {
  birl.now() |> from_birl()
}
