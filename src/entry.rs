use chrono::prelude::*;
use uuid::Uuid;

#[derive(Debug, PartialEq, Eq, Clone, Copy)]
pub enum EntryType {
    Todo,
    Meeting,
}

#[derive(Debug, PartialEq, Eq, Clone)]
pub struct Entry {
    pub id: Uuid,

    pub opened: DateTime<Utc>,
    pub closed: Option<DateTime<Utc>>,
    pub scheduled_begin: Option<DateTime<Utc>>,
    pub scheduled_end: Option<DateTime<Utc>>,
    pub deadline: Option<DateTime<Utc>>,

    pub title: String,
    pub description: Option<String>,
    pub prefix: String,
}

impl Entry {
    pub fn id(&self) -> &Uuid {
        &self.id
    }

    pub fn opened(&self) -> &DateTime<Utc> {
        &self.opened
    }

    pub fn opened_mut(&mut self) -> &mut DateTime<Utc> {
        &mut self.opened
    }

    pub fn closed(&self) -> Option<&DateTime<Utc>> {
        self.closed.as_ref()
    }

    pub fn closed_mut(&mut self) -> &mut Option<DateTime<Utc>> {
        &mut self.closed
    }

    pub fn scheduled_begin(&self) -> Option<&DateTime<Utc>> {
        self.scheduled_begin.as_ref()
    }

    pub fn scheduled_begin_mut(&mut self) -> &mut Option<DateTime<Utc>> {
        &mut self.scheduled_begin
    }

    pub fn scheduled_end(&self) -> Option<&DateTime<Utc>> {
        self.scheduled_end.as_ref()
    }

    pub fn scheduled_end_mut(&mut self) -> &mut Option<DateTime<Utc>> {
        &mut self.scheduled_end
    }

    pub fn deadline(&self) -> Option<&DateTime<Utc>> {
        self.deadline.as_ref()
    }

    pub fn deadline_mut(&mut self) -> &mut Option<DateTime<Utc>> {
        &mut self.deadline
    }

    pub fn title(&self) -> &str {
        self.title.as_str()
    }

    pub fn title_mut(&mut self) -> &mut String {
        &mut self.title
    }

    pub fn description(&self) -> Option<&str> {
        self.description.as_deref()
    }

    pub fn description_mut(&mut self) -> &mut Option<String> {
        &mut self.description
    }

    pub fn prefix(&self) -> &str {
        self.prefix.as_str()
    }

    pub fn prefix_mut(&mut self) -> &mut String {
        &mut self.prefix
    }
}
