import birl
import gleam/json
import time.{Time}

pub fn to_string_test() {
  assert "22:21:20" == time.to_string(Time(22, 21, 20))
}

pub fn to_string_01_test() {
  assert "01:02:20" == time.to_string(Time(1, 2, 20))
}

pub fn to_string_02_test() {
  assert "01:22:20" == time.to_string(Time(1, 22, 20))
}

pub fn to_string_03_test() {
  assert "22:01:20" == time.to_string(Time(22, 1, 20))
}

pub fn parse_00_test() {
  assert Ok(Time(1, 2, 31)) == time.parse("01:02:31")
}

pub fn parse_01_test() {
  assert Ok(Time(0, 0, 0)) == time.parse("00:00:00")
}

pub fn parse_02_test() {
  assert Error(Nil) == time.parse("00")
}

pub fn parse_03_test() {
  assert Ok(Time(0, 0, 0)) == time.parse("00:00:00")
}

pub fn parse_04_test() {
  assert Error(Nil) == time.parse("word:00:00")
}

pub fn parse_05_test() {
  assert Error(Nil) == time.parse("00:word:00")
}

pub fn parse_06_test() {
  assert Error(Nil) == time.parse("24:00:00")
}

pub fn parse_07_test() {
  assert Error(Nil) == time.parse("22:60:00")
}

pub fn parse_08_test() {
  assert Error(Nil) == time.parse("22:00:word")
}

pub fn parse_09_test() {
  assert Error(Nil) == time.parse("22:00:60")
}

pub fn parse_10_test() {
  assert Error(Nil) == time.parse("00:00:00:00")
}

pub fn to_from_json_test() {
  let time = Time(1, 2, 3)
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

  assert Time(20, 47, 34) == time.from_birl(time)
}
