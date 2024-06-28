// Copyright (c) The Diem Core Contributors
// Copyright (c) The Move Contributors
// SPDX-License-Identifier: Apache-2.0

//! Run tests for known and fixed failures.
//!
//! # Usage
//!
//! These tests require `move-compiler` to be pre-built:
//!
//! ```
//! cargo build -p move-compiler
//! ```
//!
//! Running the tests:
//!
//! ```
//! cargo test -p move-mv-llvm-compiler --test sui-framework-tests
//! ```
//!
//! Running a specific test:
//!
//! ```
//! cargo test -p move-mv-llvm-compiler --test sui-framework-tests -- hash_tests.move
//! ```
//!
//! Promoting all results to expected results:
//!
//! ```
//! PROMOTE_LLVM_IR=1 cargo test -p move-mv-llvm-compiler --test sui-framework-tests
//! ```
//!
//! # Details
//!
//! They do the following:
//!
//! - Create a test for every .move file in sui-framework-tests/
//! - Run `move-mv-llvm-compiler` to compile Move source to LLVM IR.
//! - Compare the actual IR to an existing expected IR.
//!
//! If the `PROMOTE_LLVM_IR` env var is set, the actual IR is promoted to the
//! expected IR.
//!

use anyhow::bail;
use log::debug;
use std::{env, path::{Path, PathBuf}};

mod test_common;
use test_common as tc;

pub const TEST_DIR: &str = "tests/sui-framework-tests";

datatest_stable::harness!(run_test, TEST_DIR, r".*\.move$");

fn run_test(test_path: &Path) -> Result<(), Box<dyn std::error::Error>> {
    tc::setup_logging_for_test();
    dbg!(test_path);
    Ok(run_test_inner(test_path)?)
}

fn run_test_inner(test_path: &Path) -> anyhow::Result<()> {
    let harness_paths = tc::get_harness_paths("move-compiler")?;
    let test_plan = tc::get_test_plan(test_path)?;

    if test_plan.should_ignore() {
        eprintln!("ignoring {}", test_plan.name);
        return Ok(());
    }

    let current_dir = env::current_dir()
    .or_else(|err| bail!("Cannot get currecnt directory. Got error: {}", err))
    .unwrap();

    let test_name = &test_plan.name;
    debug!(target: "debug", "test_name {:#?}", &test_name);

    let toml_dir: String;
    if let Some(pos) = test_name.rfind('/') {
        toml_dir = test_name[..pos].to_string();
    } else {
        bail!("No extension found in the filename {}", test_name);
    }

    let p_absolute_path = current_dir.join(&toml_dir).to_str().unwrap().to_owned();
    debug!(target: "debug", "p_absolute_path {}", &p_absolute_path);


    debug!(target: "debug", "current_dir {:#?}", &current_dir);
    debug!(target: "debug", "toml_dir {:#?}", &toml_dir);
    debug!(target: "debug", "p_absolute_path {:#?}", &p_absolute_path);

    let dependency = find_move_toml(&p_absolute_path);
    debug!(target: "debug", "dependency {:#?}", &dependency);

    let mut extra_param = if let Some(lib_dep) = dependency {
        let p = "-p".to_string().to_owned();
        let lib_dep_str = lib_dep.to_str().unwrap().to_string();
        vec![p, lib_dep_str]
    } else {
        let stdlib = "--stdlib".to_string().to_owned();
        vec![stdlib]
    };
    extra_param.push("--test".to_string());
    extra_param.push("--skip-undefined-entries".to_string());

    let src = &test_plan.build_dir;
    let dst = &src.join("stored_results");

    tc::clean_results(src)?;
    std::fs::remove_dir_all(dst).ok();



    debug!("harness_paths {:#?} &test_plan {:#?}", &harness_paths, &test_plan);
    tc::run_move_to_llvm_build(
        &harness_paths,
        &test_plan,
        extra_param.iter().collect()
    )?;

    tc::compare_results(&test_plan)?;

    Ok(())
}

fn find_move_toml(dir: &str) -> Option<PathBuf> {
    let path = Path::new(dir);
    let move_toml = path.join("Move.toml");

    if move_toml.exists() {
        Some(move_toml)
    } else {
        None
    }
}
