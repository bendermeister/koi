use std::{fmt::Display, str::FromStr};

#[derive(Debug, PartialEq, Eq, Clone, Copy)]
pub enum Duration {
    Day(i32),
    Week(i32),
    Month(i32),
    Year(i32),
}

impl Display for Duration {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            Duration::Day(x) => write!(f, "{}d", x),
            Duration::Week(x) => write!(f, "{}w", x),
            Duration::Month(x) => write!(f, "{}m", x),
            Duration::Year(x) => write!(f, "{}y", x),
        }
    }
}

impl FromStr for Duration {
    type Err = ();

    fn from_str(s: &str) -> Result<Self, Self::Err> {
        let s = s.trim();

        if s.is_empty() {
            return Err(());
        }

        let num = s[..s.len()-1].trim().parse().map_err(|_| ())?;

        match s.chars().next_back() {
            Some('d') => Ok(Duration::Day(num)),
            Some('w') => Ok(Duration::Week(num)),
            Some('m') => Ok(Duration::Month(num)),
            Some('y') => Ok(Duration::Year(num)),
            _ => Err(())
        }
    }
}

#[cfg(test)]
mod test {
    use super::*;

    #[test]
    fn test_parsing() {
        let parse = |s: &str| s.parse::<Duration>().unwrap();
        assert_eq!(parse("7d"), Duration::Day(7));
        assert_eq!(parse("+7d"), Duration::Day(7));
        assert_eq!(parse("-3d"), Duration::Day(-3));

        assert_eq!(parse("7w"), Duration::Week(7));
        assert_eq!(parse("+7w"), Duration::Week(7));
        assert_eq!(parse("-1w"), Duration::Week(-1));

        assert_eq!(parse("7m"), Duration::Month(7));
        assert_eq!(parse("+7m"), Duration::Month(7));
        assert_eq!(parse("-7m"), Duration::Month(-7));

        assert_eq!(parse("10y"), Duration::Year(10));
        assert_eq!(parse("+10y"), Duration::Year(10));
        assert_eq!(parse("-1y"), Duration::Year(-1));
    }

    #[test]
    fn test_display_parse() {
        let expected = Duration::Day(1);
        let got = expected.to_string().parse().unwrap();
        assert_eq!(expected, got);

        let expected = Duration::Day(-10);
        let got = expected.to_string().parse().unwrap();
        assert_eq!(expected, got);

        let expected = Duration::Week(20);
        let got = expected.to_string().parse().unwrap();
        assert_eq!(expected, got);

        let expected = Duration::Week(-20);
        let got = expected.to_string().parse().unwrap();
        assert_eq!(expected, got);

        let expected = Duration::Month(20);
        let got = expected.to_string().parse().unwrap();
        assert_eq!(expected, got);

        let expected = Duration::Month(-20);
        let got = expected.to_string().parse().unwrap();
        assert_eq!(expected, got);

        let expected = Duration::Year(20);
        let got = expected.to_string().parse().unwrap();
        assert_eq!(expected, got);

        let expected = Duration::Year(-20);
        let got = expected.to_string().parse().unwrap();
        assert_eq!(expected, got);
    }
}
