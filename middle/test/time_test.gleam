import birl
import gleam/json
import time.{Time}

pub fn to_string_test() {
  assert "22:21" == time.to_string(Time(22, 21))
}

pub fn to_string_01_test() {
  assert "01:02" == time.to_string(Time(1, 2))
}

pub fn to_string_02_test() {
  assert "01:22" == time.to_string(Time(1, 22))
}

pub fn to_string_03_test() {
  assert "22:01" == time.to_string(Time(22, 1))
}

pub fn parse_00_test() {
  assert Ok(Time(1, 2)) == time.from_string("01:02")
}

pub fn parse_01_test() {
  assert Ok(Time(0, 0)) == time.from_string("00:00")
}

pub fn parse_02_test() {
  assert Error(Nil) == time.from_string("00")
}

pub fn parse_03_test() {
  assert Ok(Time(0, 0)) == time.from_string("00:00")
}

pub fn parse_04_test() {
  assert Error(Nil) == time.from_string("word:00:00")
}

pub fn parse_05_test() {
  assert Error(Nil) == time.from_string("00:word:00")
}

pub fn parse_06_test() {
  assert Error(Nil) == time.from_string("24:00:00")
}

pub fn parse_07_test() {
  assert Error(Nil) == time.from_string("22:60:00")
}

pub fn parse_08_test() {
  assert Error(Nil) == time.from_string("22:00:word")
}

pub fn parse_10_test() {
  assert Error(Nil) == time.from_string("00:00:00:00")
}

pub fn to_from_json_test() {
  let time = Time(1, 2)
  let assert Ok(out) =
    time
    |> time.to_json()
    |> json.to_string
    |> json.parse(time.decoder())
  assert out == time
}

pub fn from_birl_test() {
  let assert Ok(time) =
    "2025-12-16T20:47:34.875+01:00"
    |> birl.parse()

  assert Time(20, 47) == time.from_birl(time)
}
