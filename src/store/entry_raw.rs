use crate::entry::Entry;
use chrono::prelude::*;

use super::ConversionError;

#[derive(Debug, PartialEq, Eq, Clone, serde::Serialize, serde::Deserialize)]
pub struct EntryRaw {
    pub id: u64,

    pub opened: String,
    pub closed: Option<String>,
    pub scheduled_begin: Option<String>,
    pub scheduled_end: Option<String>,
    pub deadline: Option<String>,

    pub title: String,
    pub description: Option<String>,
    pub prefix: String,
}

impl From<Entry> for EntryRaw {
    fn from(entry: Entry) -> Self {
        Self {
            id: entry.id,
            opened: entry.opened().to_rfc3339(),
            closed: entry.closed().map(|v| v.to_rfc3339()),
            scheduled_begin: entry.scheduled_begin().map(|v| v.to_rfc3339()),
            scheduled_end: entry.scheduled_end().map(|v| v.to_rfc3339()),
            deadline: entry.deadline().map(|v| v.to_rfc3339()),
            title: entry.title,
            description: entry.description,
            prefix: entry.prefix,
        }
    }
}

impl TryFrom<EntryRaw> for Entry {
    type Error = ConversionError;

    fn try_from(value: EntryRaw) -> Result<Self, Self::Error> {
        let id = value.id;

        let parse_date = |date: String| {
            DateTime::parse_from_rfc3339(&date)
                .map(|date| date.to_utc())
                .map_err(|_| ConversionError)
        };

        let parse_option_date =
            |date: Option<String>| date.map(|date| parse_date(date)).transpose();

        let opened = parse_date(value.opened)?;
        let closed = parse_option_date(value.closed)?;
        let scheduled_begin = parse_option_date(value.scheduled_begin)?;
        let scheduled_end = parse_option_date(value.scheduled_end)?;
        let deadline = parse_option_date(value.deadline)?;

        let title = value.title;

        let description = value.description;
        let prefix = value.prefix;

        Ok(Entry {
            id,
            opened,
            closed,
            scheduled_begin,
            scheduled_end,
            deadline,
            title,
            description,
            prefix,
        })
    }
}

#[cfg(test)]
mod test {
    use super::*;

    #[test]
    fn test_entry_to_raw_to_entry() {
        let expected = Entry {
            id: 0,
            opened: Utc::now(),
            closed: Some(Utc::now()),
            scheduled_begin: Some(Utc::now()),
            scheduled_end: Some(Utc::now()),
            deadline: Some(Utc::now()),
            title: "title".into(),
            description: Some("description".into()),
            prefix: "Pre/Fix".into(),
        };

        let got: EntryRaw = expected.clone().into();
        let got: Entry = got.try_into().unwrap();

        assert_eq!(expected, got);
    }
}
