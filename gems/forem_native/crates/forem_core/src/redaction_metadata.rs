//! Aggregates counts supplied by the transcript curator.

use std::collections::HashMap;

use crate::text::trim_ruby_strip;

#[derive(Default)]
pub struct RedactionCounts {
    counts: HashMap<String, (usize, i64)>,
}

impl RedactionCounts {
    /// Borrows each name and allocates only when a distinct name is first seen.
    pub fn add(&mut self, name: &str, count: i64) -> Option<()> {
        let name = trim_ruby_strip(name);
        if count <= 0 || name.chars().all(char::is_whitespace) {
            return Some(());
        }

        if let Some((_, previous)) = self.counts.get_mut(name) {
            *previous = previous.checked_add(count)?;
        } else {
            let index = self.counts.len();
            self.counts.insert(name.to_owned(), (index, count));
        }
        Some(())
    }

    /// Number of distinct redaction names currently accumulated.
    pub fn len(&self) -> usize {
        self.counts.len()
    }

    /// Whether any positive redaction counts have been accumulated.
    pub fn is_empty(&self) -> bool {
        self.counts.is_empty()
    }

    /// Preserve first occurrence so callers can apply Ruby's `sort_by` to the same order.
    pub fn into_insertion_order(self) -> impl Iterator<Item = (String, i64)> {
        let mut entries: Vec<_> = self.counts.into_iter().collect();
        entries.sort_unstable_by_key(|&(_, (index, _))| index);
        entries.into_iter().map(|(name, (_, count))| (name, count))
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn counts_trimmed_positive_names_in_first_seen_order() {
        let mut counts = RedactionCounts::default();
        for (name, count) in [
            (" \0 A \r\n", 1),
            ("\u{3000}", 7),
            (" 😀 ", 2),
            ("ignored", -1),
            ("A", 2),
        ] {
            assert_eq!(counts.add(name, count), Some(()));
        }
        assert_eq!(
            counts.into_insertion_order().collect::<Vec<_>>(),
            [("A".to_owned(), 3), ("😀".to_owned(), 2)]
        );
    }

    #[test]
    fn defers_when_the_total_exceeds_the_integer_range() {
        let mut counts = RedactionCounts::default();
        assert_eq!(counts.add("name", i64::MAX), Some(()));
        assert_eq!(counts.add("name", 1), None);
    }
}
