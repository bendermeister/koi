use std::{cmp::Ordering, fmt::Display, str::FromStr};

use rusqlite::{ToSql, types::FromSql};

use super::prelude::*;

impl FromSql for DateTime {
    fn column_result(value: rusqlite::types::ValueRef<'_>) -> rusqlite::types::FromSqlResult<Self> {
        <String as FromSql>::column_result(value)?
            .parse()
            .map_err(|_| rusqlite::types::FromSqlError::InvalidType)
    }
}

impl ToSql for DateTime {
    fn to_sql(&self) -> rusqlite::Result<rusqlite::types::ToSqlOutput<'_>> {
        Ok(rusqlite::types::ToSqlOutput::Owned(
            rusqlite::types::Value::Text(self.to_string()),
        ))
    }
}

#[derive(Debug, PartialEq, Eq, Clone, Copy)]
pub struct DateTime {
    date: Date,
    time: Time,
}

impl TimeLike for DateTime {
    fn hour(&self) -> u32 {
        self.time.hour()
    }

    fn minute(&self) -> u32 {
        self.time.minute()
    }

    fn with_date(&self, date: Date) -> DateTime {
        self.time().with_date(date)
    }
}

impl DateLike for DateTime {
    fn year(&self) -> u32 {
        self.date.year()
    }

    fn month(&self) -> u32 {
        self.date.year()
    }

    fn day(&self) -> u32 {
        self.date.day()
    }

    fn add_days(&self, days: i32) -> Self {
        self.date().add_days(days).with_time(self.time())
    }

    fn add_months(&self, months: i32) -> Self {
        self.date().add_months(months).with_time(self.time())
    }

    fn add_years(&self, years: i32) -> Self {
        self.date().add_years(years).with_time(self.time())
    }

    fn with_time(&self, time: Time) -> DateTime {
        self.date().with_time(time)
    }

    fn next_day(&self) -> Self {
        self.date().next_day().with_time(self.time())
    }

    fn prev_day(&self) -> Self {
        self.date().prev_day().with_time(self.time())
    }

    fn with_year(&self, year: u32) -> Option<Self> {
        self.date()
            .with_year(year)
            .map(|d| d.with_time(self.time()))
    }

    fn with_month(&self, month: u32) -> Option<Self> {
        self.date()
            .with_month(month)
            .map(|d| d.with_time(self.time()))
    }

    fn with_day(&self, day: u32) -> Option<Self> {
        self.date().with_day(day).map(|d| d.with_time(self.time()))
    }

    fn prev_month(&self) -> Self {
        self.date().prev_month().with_time(self.time())
    }

    fn next_month(&self) -> Self {
        self.date().next_month().with_time(self.time())
    }

    fn prev_year(&self) -> Self {
        self.date().prev_year().with_time(self.time())
    }

    fn next_year(&self) -> Self {
        self.date().next_year().with_time(self.time())
    }

    fn month_begin(&self) -> Self {
        self.date().month_begin().with_time(self.time())
    }

    fn month_end(&self) -> Self {
        self.date().month_end().with_time(self.time())
    }

    fn year_begin(&self) -> Self {
        self.date().year_begin().with_time(self.time())
    }

    fn year_end(&self) -> Self {
        self.date().year_end().with_time(self.time())
    }

    fn add_duration(&self, duration: Duration) -> Self {
        self.date().add_duration(duration).with_time(self.time())
    }
}

impl DateTime {
    pub fn new(date: Date, time: Time) -> Self {
        Self { date, time }
    }

    pub fn date(&self) -> Date {
        self.date
    }

    pub fn time(&self) -> Time {
        self.time
    }
}

impl AsRef<Time> for DateTime {
    fn as_ref(&self) -> &Time {
        self.time.as_ref()
    }
}

impl AsRef<Date> for DateTime {
    fn as_ref(&self) -> &Date {
        self.date.as_ref()
    }
}

impl Display for DateTime {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        write!(f, "{} {}", self.date(), self.time())
    }
}

impl FromStr for DateTime {
    type Err = ();

    fn from_str(s: &str) -> Result<Self, Self::Err> {
        let s = s.trim();
        if s == "now" {
            return Ok(now());
        }

        let mut parts = s.split_whitespace();
        let date = parts.next().ok_or(())?.parse()?;
        let time = parts.next().unwrap_or("00:00").parse()?;

        Ok(DateTime::new(date, time))
    }
}

impl PartialOrd for DateTime {
    fn partial_cmp(&self, other: &Self) -> Option<Ordering> {
        Some(self.cmp(other))
    }
}

impl Ord for DateTime {
    fn cmp(&self, other: &Self) -> Ordering {
        let date = self.date().cmp(other.date().as_ref());
        let time = self.time().cmp(other.time().as_ref());
        date.then(time)
    }
}
