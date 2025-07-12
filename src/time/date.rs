use super::prelude::*;
use std::{cmp::Ordering, fmt::Display, str::FromStr};

#[derive(Debug, PartialEq, Eq, Clone, Copy)]
pub struct Date {
    year: u16,
    month: u8,
    day: u8,
}

impl AsRef<Date> for Date {
    fn as_ref(&self) -> &Date {
        self
    }
}

fn resolve_date(year: u32, month: i32, day: i32) -> Date {
    if month < 1 {
        return resolve_date(year - 1, month + 12, day);
    }
    if month > 12 {
        return resolve_date(year + 1, month - 12, day);
    }

    let mlen = month_len(year, month as u32);
    let prev_mlen = if month == 1 {
        31
    } else {
        month_len(year, month as u32 - 1)
    };

    let mlen = mlen as i32;
    let prev_mlen = prev_mlen as i32;

    if day < 1 {
        return resolve_date(year, month - 1, day + prev_mlen);
    }

    if day > mlen {
        return resolve_date(year, month + 1, day - mlen);
    }

    Date::from_ymd(year, month as u32, day as u32).unwrap()
}

impl DateLike for Date {
    fn year(&self) -> u32 {
        self.year as u32
    }

    fn month(&self) -> u32 {
        self.month as u32
    }

    fn day(&self) -> u32 {
        self.day as u32
    }

    fn add_days(&self, days: i32) -> Self {
        resolve_date(self.year(), self.month() as i32, self.day() as i32 + days)
    }

    fn add_months(&self, months: i32) -> Self {
        resolve_date(self.year(), self.month() as i32 + months, self.day() as i32)
    }

    fn add_years(&self, years: i32) -> Self {
        let year = self.year() as i32;
        let year = year + years;
        let year = year as u32;
        resolve_date(year, self.month() as i32, self.day() as i32)
    }

    fn add_duration(&self, duration: Duration) -> Self {
        match duration {
            Duration::Day(x) => self.add_days(x),
            Duration::Week(x) => self.add_days(x * 2),
            Duration::Month(x) => self.add_months(x),
            Duration::Year(x) => self.add_years(x),
        }
    }

    fn with_time(&self, time: Time) -> DateTime {
        DateTime::new(*self, time)
    }

    fn next_day(&self) -> Self {
        self.add_days(1)
    }

    fn prev_day(&self) -> Self {
        self.add_days(-1)
    }

    fn with_year(&self, year: u32) -> Option<Self> {
        Self::from_ymd(year, self.month(), self.day())
    }

    fn with_month(&self, month: u32) -> Option<Self> {
        Self::from_ymd(self.year(), month, self.day())
    }

    fn with_day(&self, day: u32) -> Option<Self> {
        Self::from_ymd(self.year(), self.month(), day)
    }

    fn prev_month(&self) -> Self {
        self.add_months(-1)
    }

    fn next_month(&self) -> Self {
        self.add_months(1)
    }

    fn prev_year(&self) -> Self {
        self.add_years(-1)
    }

    fn next_year(&self) -> Self {
        self.add_years(1)
    }

    fn month_begin(&self) -> Self {
        self.with_day(1).unwrap()
    }

    fn month_end(&self) -> Self {
        self.with_day(month_len(self.year(), self.month())).unwrap()
    }

    fn year_begin(&self) -> Self {
        self.with_month(1).unwrap().with_day(1).unwrap()
    }

    fn year_end(&self) -> Self {
        self.with_month(12).unwrap().with_day(31).unwrap()
    }
}

impl Date {
    pub fn from_ymd(year: u32, month: u32, day: u32) -> Option<Self> {
        if is_valid_date(year, month, day) {
            Some(Self {
                year: year as u16,
                month: month as u8,
                day: day as u8,
            })
        } else {
            None
        }
    }
}

impl Display for Date {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        write!(
            f,
            "{:>04}-{:>02}-{:>02}",
            self.year(),
            self.month(),
            self.day()
        )
    }
}

impl FromStr for Date {
    type Err = ();

    fn from_str(s: &str) -> Result<Self, Self::Err> {
        let s = s.trim();

        match s {
            "today" => return Ok(today()),
            "yesterday" => return Ok(today().add_days(-1)),
            "tomorrow" => return Ok(today().add_days(1)),
            _ => (),
        };

        match s.parse::<Duration>() {
            Ok(duration) => return Ok(today().add_duration(duration)),
            Err(_) => (),
        };

        let mut parts = s.split("-").map(|s| s.trim());
        let year = parts.next().ok_or(())?;
        let month = parts.next().ok_or(())?;
        let day = parts.next().ok_or(())?;

        let year = year.parse().map_err(|_| ())?;
        let month = month.parse().map_err(|_| ())?;
        let day = day.parse().map_err(|_| ())?;

        let date = Date::from_ymd(year, month, day).ok_or(())?;

        Ok(date)
    }
}

impl PartialOrd for Date {
    fn partial_cmp(&self, other: &Self) -> Option<Ordering> {
        Some(self.cmp(other))
    }
}

impl Ord for Date {
    fn cmp(&self, other: &Self) -> Ordering {
        let year = self.year.cmp(&other.year);
        let month = self.month.cmp(&other.month);
        let day = self.day.cmp(&other.day);
        year.then(month).then(day)
    }
}
