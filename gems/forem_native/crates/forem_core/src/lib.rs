//! Pure-Rust core algorithms for Forem.
//!
//! This crate intentionally has **zero** dependencies on Ruby, `magnus`, or `rb-sys`.
//! Keeping core algorithms pure Rust allows the exact same code to be:
//! 1. Linked into the in-process `forem_native` Ruby C-ABI extension via `magnus` (Option A).
//! 2. Tested and benchmarked standalone with `cargo test` in milliseconds.
//! 3. Compiled to `wasm32-unknown-unknown` (Option B) or standalone Rust services in future phases.

pub mod calendar;
pub mod color;
pub mod emoji;
pub(crate) mod emoji_data;
pub mod feed;
pub mod fixer;
pub mod html;
pub mod image;
pub mod markdown;
pub(crate) mod psl_data;
pub mod sanitize;
pub mod scrubber;
pub mod svg;
pub mod text;
pub mod title;
pub mod url;
