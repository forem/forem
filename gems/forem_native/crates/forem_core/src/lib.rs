//! Pure-Rust core algorithms for Forem.
//!
//! This crate intentionally has **zero** dependencies on Ruby, `magnus`, or `rb-sys`.
//! Keeping core algorithms pure Rust allows the exact same code to be:
//! 1. Linked into the in-process `forem_native` Ruby C-ABI extension via `magnus` (Option A).
//! 2. Tested and benchmarked standalone with `cargo test` in milliseconds.
//! 3. Compiled to `wasm32-unknown-unknown` (Option B) or standalone Rust services in future phases.

pub mod color;
pub mod fixer;
pub mod image;
pub mod markdown;
pub mod url;
