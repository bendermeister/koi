use std::{fmt::Display, str::FromStr};

use rusqlite::{ToSql, types::FromSql};

use crate::time::prelude::*;

#[derive(Debug, PartialEq, Eq, Clone, Copy)]
pub enum EntryType {
    Todo,
    Meeting,
}

impl Display for EntryType {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {




        let num: u32 = 69;
        let num: usize = num as usize;

        let num: i32 = 69;
        // let num: u32 = num.try_into().expect("no negativity here bro");
        let num: u32 = num.into();

        let num: u32 = 69;
        let num: u64 = num.into();




        let s = match self {
            EntryType::Todo => "todo",
            EntryType::Meeting => "meeting",
        };
        write!(f, "{}", s)
    }
}

impl FromStr for EntryType {
    type Err = ();

    fn from_str(s: &str) -> Result<Self, Self::Err> {
        match s.trim() {
            "todo" => Ok(Self::Todo),
            "meeting" => Ok(Self::Meeting),
            _ => Err(()),
        }
    }
}

impl FromSql for EntryType {
    fn column_result(value: rusqlite::types::ValueRef<'_>) -> rusqlite::types::FromSqlResult<Self> {
        <String as FromSql>::column_result(value)?
            .parse()
            .map_err(|_| rusqlite::types::FromSqlError::InvalidType)
    }
}

impl ToSql for EntryType {
    fn to_sql(&self) -> rusqlite::Result<rusqlite::types::ToSqlOutput<'_>> {
        Ok(rusqlite::types::ToSqlOutput::Owned(
            rusqlite::types::Value::Text(self.to_string()),
        ))
    }
}

#[derive(Debug, PartialEq, Eq, Clone, Copy)]
pub enum EntryState {
    Open,
    Closed,
}

#[derive(Debug, PartialEq, Eq, Clone)]
pub struct Entry {
    pub id: u64,

    pub title: String,
    pub body: String,
    pub prefix: String,
    pub entry_type: EntryType,

    pub opened: DateTime,
    pub closed: Option<DateTime>,

    pub scheduled: Option<DateTime>,
    pub scheduled_end: Option<DateTime>,

    pub deadline: Option<DateTime>,
}

impl Entry {
    #[cfg(test)]
    pub fn test_entry(id: u64, title: String) -> Self {
        Self {
            id,
            title,
            body: "".into(),
            entry_type: EntryType::Todo,
            prefix: "".into(),
            opened: now().into(),
            closed: None,
            scheduled: None,
            scheduled_end: None,
            deadline: None,
        }
    }

    pub fn is_open(&self) -> bool {
        self.closed.map(|_| true).unwrap_or(false)
    }

    pub fn is_closed(&self) -> bool {
        !self.is_open()
    }

    pub fn state(&self) -> EntryState {
        self.is_open()
            .then_some(EntryState::Open)
            .unwrap_or(EntryState::Closed)
    }
}
