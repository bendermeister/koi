use std::path::Path;

use crate::entry::{Entry, EntryState};
use crate::time::prelude::*;
use rusqlite::Connection;

#[derive(Debug, PartialEq, Eq, Clone)]
pub struct Query<'a> {
    pub state: Option<EntryState>,
    pub prefix: Option<&'a str>,
    pub scheduled_or_deadline: Option<(DateTime, DateTime)>,
}

#[derive(Debug)]
pub struct Store {
    db: Connection,
}

mod db;

impl Store {
    pub fn open<P: AsRef<Path>>(path: P) -> anyhow::Result<Self> {
        let db = db::open(path)?;
        Ok(Self { db })
    }

    pub fn query_by_id(&mut self, id: u64) -> anyhow::Result<Entry> {
        db::get_entry_by_id(&self.db, id)
    }

    pub fn query(&mut self, query: Query) -> anyhow::Result<Vec<Entry>> {
        let mut entries = db::get_all_entries(&self.db)?;

        let filter = |entry: &Entry| {
            if let Some(state) = query.state {
                if state != entry.state() {
                    return false;
                }
            }

            if let Some(prefix) = query.prefix {
                if !entry.prefix.starts_with(prefix) {
                    return false;
                }
            }

            if let Some((begin, end)) = query.scheduled_or_deadline {
                let check_range =
                    |a: Option<DateTime>| a.map(|a| begin <= a && a < end).unwrap_or(false);

                let scheduled = check_range(entry.scheduled);
                let deadline = check_range(entry.deadline);
                if !(scheduled || deadline) {
                    return false;
                }
            }
            true
        };

        entries.retain(filter);
        Ok(entries)
    }

    pub fn new_entry_id(&mut self) -> anyhow::Result<u64> {
        db::get_max_entry_id(&self.db)
            .map(|id| id.unwrap_or(1) + 1)
    }

    pub fn add_entry(&mut self, entry: &Entry) -> anyhow::Result<()> {
        db::add_entry(&self.db, entry)
    }
}
