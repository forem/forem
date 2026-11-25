//! Pure-Rust core algorithms for Forem.
//!
//! This crate intentionally has **zero** dependencies on Ruby, `magnus`, or `rb-sys`.
//! Keeping core algorithms pure Rust allows the exact same code to be:
//! 1. Linked into the in-process `forem_native` Ruby C-ABI extension via `magnus` (Option A).
//! 2. Tested and benchmarked standalone with `cargo test` in milliseconds.
//! 3. Compiled to `wasm32-unknown-unknown` (Option B) or standalone Rust services in future phases.

pub mod ahoy_link;
pub mod analytics;
pub mod api_articles;
pub mod api_collections;
pub mod api_comments;
pub mod api_users;
pub mod billboard_html;
pub mod calendar;
pub mod color;
pub mod comment_tree;
pub mod emoji;
pub(crate) mod emoji_data;
pub mod feed;
pub mod feed_events;
pub mod fixer;
pub mod homepage_articles;
pub mod html;
pub mod image;
pub mod image_ops;
pub mod json;
pub mod markdown;
pub mod metal;
pub mod processed_html;
pub(crate) mod psl_data;
pub mod reactions;
pub mod redaction_metadata;
pub mod redcarpet;
pub mod rss;
pub mod sanitize;
pub mod scrubber;
pub mod sitemap;
pub mod social_image;
pub mod stories_feed;
pub mod story_card;
pub mod svg;
pub mod syntax;
pub(crate) mod syntax_data;
pub mod text;
pub mod title;
pub mod transcript;
pub mod url;
