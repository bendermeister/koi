use std::path::Path;

use rusqlite::{Connection, Row};

use crate::entry::Entry;

mod migration;

#[cfg(test)]
pub fn open_test() -> Connection {
    let db = Connection::open_in_memory().unwrap();
    migration::run(&db).unwrap();
    db
}

pub fn open<P: AsRef<Path>>(path: P) -> anyhow::Result<Connection> {
    let db = Connection::open(path.as_ref())?;
    migration::run(&db)?;
    Ok(db)
}

// TODO: test this
pub fn get_max_entry_id(db: &Connection) -> anyhow::Result<Option<u64>> {
    match db.query_one(
        "SELECT id FROM entries ORDER BY id DESC LIMIT 1;",
        [],
        |row| row.get(0),
    ) {
        Ok(id) => Ok(Some(id)),
        Err(rusqlite::Error::QueryReturnedNoRows) => Ok(None),
        Err(err) => Err(err.into()),
    }
}

// TODO: test this
// TODO: doc this
pub fn add_entry(db: &Connection, entry: &Entry) -> anyhow::Result<()> {
    db.execute(
        "
        INSERT INTO entries (
            id,

            title,
            body,
            prefix,

            entry_type,

            opened,
            closed,

            scheduled,
            scheduled_end,

            deadline
        ) VALUES (
            ?, ?, ?, ?, ?, ?, ?, ?, ?, ?
        );
        ",
        rusqlite::params![
            &entry.id,
            &entry.title,
            &entry.body,
            &entry.prefix,
            &entry.entry_type,
            &entry.opened,
            &entry.closed,
            &entry.scheduled,
            &entry.scheduled_end,
            &entry.deadline,
        ],
    )?;
    Ok(())
}

fn entry_from_row(row: &Row) -> rusqlite::Result<Entry> {
    Ok(Entry {
        id: row.get(0)?,
        title: row.get(1)?,
        body: row.get(2)?,
        prefix: row.get(3)?,
        entry_type: row.get(4)?,
        opened: row.get(5)?,
        closed: row.get(6)?,
        scheduled: row.get(7)?,
        scheduled_end: row.get(8)?,
        deadline: row.get(9)?,
    })
}

// TODO: test this
// TODO: doc this
pub fn get_all_entries(db: &Connection) -> anyhow::Result<Vec<Entry>> {
    db.prepare(
        "
        SELECT
            id,
            title,
            body,
            prefix,
            entry_type,
            opened,
            closed,
            scheduled,
            scheduled_end,
            deadline
        FROM entries;
        ",
    )?
    .query([])?
    .and_then(entry_from_row)
    .collect::<Result<_, _>>()
    .map_err(|err| err.into())
}

// TODO: test this
// TODO: doc this
pub fn get_entry_by_id(db: &Connection, id: u64) -> anyhow::Result<Entry> {
    db.query_row(
        "
        SELECT
            id,
            title,
            body,
            prefix,
            entry_type,
            opened,
            closed,
            scheduled,
            scheduled_end,
            deadline
        FROM entries WHERE id = ? LIMIT 1;
        ",
        [id],
        entry_from_row,
    )
    .map_err(|err| err.into())
}

#[cfg(test)]
mod test {
    use super::*;

    #[test]
    fn test_open() {
        open_test();
    }

    #[test]
    fn test_add_get() {
        let db = open_test();

        let entry = Entry::test_entry(1, "title a".into());
        add_entry(&db, &entry).unwrap();

        let got = get_entry_by_id(&db, 1).unwrap();
        assert_eq!(entry, got);
    }

    #[test]
    fn test_get_max_id() {
        let db = open_test();

        let id = get_max_entry_id(&db).unwrap();
        assert_eq!(None, id);

        add_entry(&db, &Entry::test_entry(1, "title".into())).unwrap();

        let id = get_max_entry_id(&db).unwrap();
        assert_eq!(Some(1), id);

        add_entry(&db, &Entry::test_entry(3, "title".into())).unwrap();

        let id = get_max_entry_id(&db).unwrap();
        assert_eq!(Some(3), id);
    }

    #[test]
    fn test_get_all_entries() {
        let db = open_test();
        let a = Entry::test_entry(1, "title a".into());
        let b = Entry::test_entry(2, "title b".into());
        let c = Entry::test_entry(3, "title c".into());

        add_entry(&db, &a).unwrap();
        add_entry(&db, &b).unwrap();
        add_entry(&db, &c).unwrap();

        let expected = vec![a, b, c];
        let mut got = get_all_entries(&db).unwrap();
        got.sort_by(|a, b| a.title.cmp(&b.title));

        assert_eq!(expected, got);
    }
}

