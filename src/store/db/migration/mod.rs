use rusqlite::Connection;

mod base_migration;
mod migration_0001;

trait MigrationLike {
    fn up(&self, db: &Connection) -> anyhow::Result<()>;
}

const MIGRATIONS: [&dyn MigrationLike; 2] =
    [&base_migration::Migration, &migration_0001::Migration];

fn get_level(db: &Connection) -> anyhow::Result<usize> {
    let exists: bool = db.query_one(
        "SELECT EXISTS (
            SELECT 1 FROM sqlite_master 
                WHERE type = 'table' AND name = 'migration'
        );",
        [],
        |row| row.get(0),
    )?;

    if !exists {
        return Ok(0);
    }

    let level = db.query_one("SELECT level FROM migration LIMIT 1;", [], |row| row.get(0))?;

    Ok(level)
}

fn update_level(db: &Connection) -> anyhow::Result<()> {
    db.execute("UPDATE migration SET level = ?;", [MIGRATIONS.len()])?;
    Ok(())
}

pub fn run(db: &Connection) -> anyhow::Result<()> {
    let level = get_level(db)?;
    let migrations = &MIGRATIONS[level..];
    for migration in migrations {
        migration.up(db)?;
    }

    update_level(db)?;

    Ok(())
}

#[cfg(test)]
mod test {
    use super::*;

    #[test]
    fn test_migration() {
        let db = Connection::open_in_memory().unwrap();
        run(&db).unwrap();
    }
}
