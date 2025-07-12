mod date;

pub mod util;

pub use date::Date;
mod time;
pub use time::Time;

mod datetime;
pub use datetime::DateTime;

mod duration;
pub use duration::Duration;

pub mod prelude {
    pub use super::Duration;

    pub trait DateLike 
        where
            Self: Sized
    {
        fn year(&self) -> u32;
        fn month(&self) -> u32;
        fn day(&self) -> u32;

        fn add_days(&self, days: i32) -> Self;
        fn add_months(&self, months: i32) -> Self;
        fn add_years(&self, years: i32) -> Self;

        fn add_duration(&self, duration: Duration) -> Self;

        fn with_time(&self, time: Time) -> DateTime;

        fn next_day(&self) -> Self;
        fn prev_day(&self) -> Self;

        fn with_year(&self, day: u32) -> Option<Self>;
        fn with_month(&self, day: u32) -> Option<Self>;
        fn with_day(&self, day: u32) -> Option<Self>;

        fn prev_month(&self) -> Self;
        fn next_month(&self) -> Self;

        fn prev_year(&self) -> Self;
        fn next_year(&self) -> Self;

        fn month_begin(&self) -> Self;
        fn month_end(&self) -> Self;

        fn year_begin(&self) -> Self;
        fn year_end(&self) -> Self;
    }

    pub trait TimeLike {
        fn hour(&self) -> u32;
        fn minute(&self) -> u32;

        fn with_date(&self, date: Date) -> DateTime;
    }

    pub use super::util::*;

    pub use super::Date;
    pub use super::DateTime;
    pub use super::Time;
}
