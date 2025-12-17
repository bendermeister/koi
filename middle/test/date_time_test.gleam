import birl
import date.{Date, Dec, Jan}
import date_time.{DateTime}
import gleam/json
import time.{Time}

pub fn parse_00_test() {
  let expected = DateTime(Date(2025, Jan, 2), Time(3, 4, 0))
  let assert Ok(out) = date_time.parse("2025-01-02 03:04:00")
  assert out == expected
}

pub fn parse_01_test() {
  assert Error(Nil) == date_time.parse("")
}

pub fn parse_02_test() {
  assert Error(Nil) == date_time.parse("2025-01-02")
}

pub fn parse_03_test() {
  assert Error(Nil) == date_time.parse("00:00:00")
}

pub fn to_string_test() {
  let date = DateTime(Date(2025, Jan, 2), Time(3, 4, 5))
  assert "2025-01-02 03:04:05" == date_time.to_string(date)
}

pub fn to_from_json_test() {
  let expected = DateTime(Date(2025, Jan, 3), Time(20, 30, 40))
  let assert Ok(out) =
    expected
    |> date_time.to_json()
    |> json.to_string()
    |> json.parse(date_time.decoder())
  assert out == expected
}

pub fn from_birl_test() {
  let assert Ok(birl) =
    "2025-12-16T21:06:04.745+01:00"
    |> birl.parse()

  let date = date.Date(2025, Dec, 16)
  let time = time.Time(21, 6, 4)
  let dt = DateTime(date, time)
  assert dt == date_time.from_birl(birl)
}
