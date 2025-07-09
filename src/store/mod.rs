use std::{fmt::Display, io, path::Path};

use store_raw::StoreRaw;

use crate::entry::Entry;

#[derive(Default, Debug, PartialEq, Eq, Clone)]
pub struct Store {
    pub max_id: u64,
    pub entries: Vec<Entry>,
}

mod entry_raw;
mod store_raw;

#[derive(Debug)]
pub struct ConversionError;

impl std::error::Error for ConversionError {}

impl Display for ConversionError {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        write!(f, "could not convert raw type to type")
    }
}

impl Store {
    pub fn open<P>(path: P) -> io::Result<Store>
    where
        P: AsRef<Path>,
    {
        let store = StoreRaw::open(path)?;
        let store: Self = store
            .try_into()
            .map_err(|err| io::Error::new(io::ErrorKind::InvalidData, err))?;

        Ok(store)
    }

    pub fn close<P>(self, path: P) -> io::Result<()>
    where
        P: AsRef<Path>,
    {
        let store: StoreRaw = self.into();
        store.close(path)
    }
}
