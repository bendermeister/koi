use super::MigrationLike;

pub struct Migration;

impl MigrationLike for Migration {
    fn up(&self, db: &rusqlite::Connection) -> anyhow::Result<()> {
        db.execute("CREATE TABLE migration (level INTEGER NOT NULL);", [])?;
        db.execute("INSERT INTO migration VALUES(1);", [])?;
        Ok(())
    }
}
