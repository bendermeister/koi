use super::prelude::*;
use std::cmp::Ordering;
use std::fmt::Display;
use std::str::FromStr;

#[derive(Debug, PartialEq, Eq, Clone, Copy)]
pub struct Time {
    hour: u8,
    minute: u8,
}

impl PartialOrd for Time {
    fn partial_cmp(&self, other: &Self) -> Option<Ordering> {
        Some(self.cmp(other))
    }
}

impl Ord for Time {
    fn cmp(&self, other: &Self) -> Ordering {
        match self.hour.cmp(&other.hour) {
            Ordering::Less => Ordering::Less,
            Ordering::Equal => self.minute.cmp(&other.minute),
            Ordering::Greater => Ordering::Greater,
        }
    }
}

impl TimeLike for Time {
    fn hour(&self) -> u32 {
        self.hour as u32
    }

    fn minute(&self) -> u32 {
        self.minute as u32
    }

    fn with_date(&self, date: Date) -> DateTime {
        DateTime::new(date, *self)
    }
}

impl AsRef<Time> for Time {
    fn as_ref(&self) -> &Time {
        self
    }
}

fn is_valid_time(hour: u32, minute: u32) -> bool {
    if hour > 23 {
        return false;
    }

    if minute > 59 {
        return false;
    }

    true
}

impl Time {
    /// creates a new valid time
    ///
    /// # Returns
    /// - `Some(Time)` if the given hour and minute form a valid time
    /// - `None` if the given hour and given minute doesnt form a time
    ///
    /// # Exmaples
    /// ```
    /// use koi::time::Time;
    ///
    /// let time = Time::from_hm(12, 30);
    /// assert!(time.is_some());
    ///
    /// let fail = Time::from_hm(100, 0);
    /// assert!(fail.is_none());
    /// ```
    pub fn from_hm(hour: u32, minute: u32) -> Option<Self> {
        if !is_valid_time(hour, minute) {
            return None;
        }
        let hour = hour as u8;
        let minute = minute as u8;
        Some(Self { hour, minute })
    }
}

impl Display for Time {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        write!(f, "{:>02}:{:>02}", self.hour(), self.minute())
    }
}

impl FromStr for Time {
    type Err = ();

    fn from_str(s: &str) -> Result<Self, Self::Err> {
        let (hour, minute) = s.trim().split_once(":").ok_or(())?;
        let hour = hour.trim().parse().map_err(|_| ())?;
        let minute = minute.trim().parse().map_err(|_| ())?;
        Self::from_hm(hour, minute).ok_or(())
    }
}

#[cfg(test)]
mod test {
    use super::*;

    #[test]
    fn test_from_hm() {
        Time::from_hm(12, 30).unwrap();
        Time::from_hm(15, 30).unwrap();
        Time::from_hm(0, 30).unwrap();
        Time::from_hm(0, 0).unwrap();
        Time::from_hm(23, 59).unwrap();
    }

    #[test]
    #[should_panic]
    fn test_from_hm_fail() {
        Time::from_hm(24, 0).unwrap();
        Time::from_hm(12, 60).unwrap();
        Time::from_hm(12, 100).unwrap();
        Time::from_hm(0, 444).unwrap();
    }

    #[test]
    fn test_parse() {
        let time = |hour, minute| Time::from_hm(hour, minute).unwrap();
        assert_eq!(time(12, 30), "12:30".parse().unwrap());
        assert_eq!(time(12, 30), "12:30".parse().unwrap());
        assert_eq!(time(12, 30), "  12:30  ".parse().unwrap());
        assert_eq!(time(12, 30), "12:30  ".parse().unwrap());
        assert_eq!(time(12, 30), "  12:30".parse().unwrap());
    }

    #[test]
    fn test_parse_fail() {
        assert!(":30".parse::<Time>().is_err());
        assert!("12:".parse::<Time>().is_err());
        assert!("12".parse::<Time>().is_err());
        assert!("".parse::<Time>().is_err());
    }

    #[test]
    fn test_display_parse_display() {
        let t = Time::from_hm(12, 30).unwrap();
        let ts = t.to_string();
        let tp = ts.parse().unwrap();
        assert_eq!(t, tp);
    }
}
