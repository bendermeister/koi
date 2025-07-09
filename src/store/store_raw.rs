use std::{fs, io, path::Path};

use crate::entry::Entry;

use super::{entry_raw::EntryRaw, ConversionError, Store};

#[derive(Debug, PartialEq, Eq, Clone, serde::Serialize, serde::Deserialize)]
pub struct StoreRaw {
    pub max_id: u64,
    pub entries: Vec<EntryRaw>,
}

impl StoreRaw {
    pub fn open<P>(path: P) -> Result<StoreRaw, io::Error>
    where
        P: AsRef<Path>,
    {
        let store = fs::read_to_string(path)?;
        let store: StoreRaw = serde_json::from_str(store.as_str())?;
        Ok(store)
    }

    pub fn close<P>(self, path: P) -> io::Result<()>
    where
        P: AsRef<Path>,
    {
        let store = serde_json::to_string(&self)?;
        fs::write(path, store)?;
        Ok(())
    }
}

impl From<Store> for StoreRaw {
    fn from(store: Store) -> Self {
        let max_id = store.max_id;

        let entries = store
            .entries
            .into_iter()
            .map(|entry| entry.into())
            .collect();

        Self { max_id, entries }
    }
}

impl TryFrom<StoreRaw> for Store {
    type Error = ConversionError;

    fn try_from(store: StoreRaw) -> Result<Self, Self::Error> {
        let max_id = store.max_id;
        let entries = store
            .entries
            .into_iter()
            .map(|entry| entry.try_into())
            .collect::<Result<Vec<Entry>, _>>();
        let entries = entries?;

        Ok(Self {
            max_id,
            entries,
        })
    }
}

#[cfg(test)]
mod test {
    use super::*;

    #[test]
    fn test_store_to_raw_to_store() {
        let expected = Store::default();
        let got: StoreRaw = expected.clone().into();
        let got: Store = got.try_into().unwrap();

        assert_eq!(expected, got);
    }
}
