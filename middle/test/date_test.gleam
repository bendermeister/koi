import birl
import date.{Apr, Aug, Date, Dec, Feb, Jan, Jul, Jun, Mar, May, Nov, Oct, Sep}
import gleam/json

pub fn is_leap_year_0_test() {
  let out = date.is_leap_year(2020)
  assert out == True
}

pub fn is_leap_year_1_test() {
  let out = date.is_leap_year(2024)
  assert out == True
}

pub fn is_leap_year_2_test() {
  assert False == date.is_leap_year(1900)
}

pub fn is_leap_year_3_test() {
  assert False == date.is_leap_year(2025)
}

pub fn month_length_00_test() {
  let date = Date(2025, Jan, 1)
  assert 31 == date.month_length(date)
}

pub fn month_length_01_test() {
  let date = Date(2025, Feb, 1)
  assert 28 == date.month_length(date)
}

pub fn month_length_02_test() {
  let date = Date(2025, Mar, 1)
  assert 31 == date.month_length(date)
}

pub fn month_length_03_test() {
  let date = Date(2025, Apr, 1)
  assert 30 == date.month_length(date)
}

pub fn month_length_04_test() {
  let date = Date(2025, May, 1)
  assert 31 == date.month_length(date)
}

pub fn month_length_05_test() {
  let date = Date(2025, Jun, 1)
  assert 30 == date.month_length(date)
}

pub fn month_length_06_test() {
  let date = Date(2025, Jul, 1)
  assert 31 == date.month_length(date)
}

pub fn month_length_07_test() {
  let date = Date(2025, Aug, 1)
  assert 31 == date.month_length(date)
}

pub fn month_length_08_test() {
  let date = Date(2025, Sep, 1)
  assert 30 == date.month_length(date)
}

pub fn month_length_09_test() {
  let date = Date(2025, Oct, 1)
  assert 31 == date.month_length(date)
}

pub fn month_length_10_test() {
  let date = Date(2025, Nov, 1)
  assert 30 == date.month_length(date)
}

pub fn month_length_11_test() {
  let date = Date(2025, Dec, 1)
  assert 31 == date.month_length(date)
}

pub fn month_length_12_test() {
  let date = Date(2020, Feb, 1)
  assert 29 == date.month_length(date)
}

pub fn parse_00_test() {
  let date = "2025-02-01"
  assert Ok(Date(2025, Feb, 1)) == date.parse(date)
}

pub fn parse_01_test() {
  assert Error(Nil) == date.parse("2025-01-01-01")
}

pub fn parse_02_test() {
  assert Error(Nil) == date.parse("2025-01")
}

pub fn parse_03_test() {
  assert Error(Nil) == date.parse("2025")
}

pub fn parse_04_test() {
  assert Error(Nil) == date.parse("word-01-01")
}

pub fn parse_05_test() {
  assert Error(Nil) == date.parse("2025-word-01")
}

pub fn parse_06_test() {
  assert Error(Nil) == date.parse("2025-01-word")
}

pub fn parse_07_test() {
  assert Error(Nil) == date.parse("2025-13-01")
}

pub fn parse_08_test() {
  assert Error(Nil) == date.parse("2025-01-32")
}

pub fn to_string_test() {
  assert "2025-02-01" == date.to_string(Date(2025, Feb, 1))
}

pub fn to_from_json_test() {
  let date = Date(2025, Jan, 2)
  let assert Ok(out) =
    date
    |> date.to_json()
    |> json.to_string()
    |> json.parse(date.decoder())
  assert out == date
}

pub fn from_json_test() {
  let assert Error(_) = json.parse("asdf", date.decoder())
}

pub fn from_birl_test() {
  let assert Ok(time) =
    "2025-01-02T20:29:13.714+01:00"
    |> birl.parse()

  assert Date(2025, Jan, 2) == time |> date.from_birl()
}
