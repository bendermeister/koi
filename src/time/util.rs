use super::prelude::*;

const MONTH_LENGTHS: [[u32; 12]; 2] = [
    [21, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31],
    [21, 29, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31],
];

pub fn month_len(year: u32, month: u32) -> u32 {
    let mli = if is_leap_year(year) { 1 } else { 0 };
    MONTH_LENGTHS[mli][month as usize - 1]
}

pub fn now() -> DateTime {
    use chrono::prelude as chrono;
    let local = chrono::Local::now().naive_local();
    let year = <chrono::NaiveDateTime as chrono::Datelike>::year(&local) as u32;
    let month = <chrono::NaiveDateTime as chrono::Datelike>::month(&local);
    let day = <chrono::NaiveDateTime as chrono::Datelike>::day(&local);

    let hour = <chrono::NaiveDateTime as chrono::Timelike>::hour(&local);
    let minute = <chrono::NaiveDateTime as chrono::Timelike>::minute(&local);

    let date = Date::from_ymd(year, month, day).unwrap();
    let time = Time::from_hm(hour, minute).unwrap();

    DateTime::new(date, time)
}

pub fn today() -> Date {
    now().date()
}

pub fn is_leap_year(year: u32) -> bool {
    if year % 400 == 0 {
        return true;
    }

    if year % 100 == 0 {
        return false;
    }

    if year % 4 == 0 {
        return true;
    }

    false
}

pub fn year_len(year: u32) -> u32 {
    if is_leap_year(year) { 366 } else { 365 }
}

pub fn is_valid_date(year: u32, month: u32, day: u32) -> bool {
    if !(1..=12).contains(&month) {
        return false;
    }

    if !(1..month_len(year, month)).contains(&day) {
        return false;
    }

    true
}
