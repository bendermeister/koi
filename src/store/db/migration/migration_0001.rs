use super::MigrationLike;

pub struct Migration;

impl MigrationLike for Migration {
    fn up(&self, db: &rusqlite::Connection) -> anyhow::Result<()> {
        db.execute(
            "
            CREATE TABLE entries (
                id            INTEGER NOT NULL UNIQUE,

                title         TEXT NOT NULL,
                body          TEXT NOT NULL,
                prefix        TEXT NOT NULL,
                entry_type    TEXT NOT NULL,

                opened        TEXT NOT NULL,
                closed        TEXT,

                scheduled     TEXT,
                scheduled_end TEXT,

                deadline      TEXT,

                PRIMARY KEY(id)
            );
            ",
            [],
        )?;
        Ok(())
    }
}
