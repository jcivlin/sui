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
//! cargo test -p move-mv-llvm-compiler --test failure-tests
//! ```
//!
//! Running a specific test:
//!
//! ```
//! cargo test -p move-mv-llvm-compiler --test failure-tests -- hash_tests.move
//! ```
//!
//! Promoting all results to expected results:
//!
//! ```
//! PROMOTE_LLVM_IR=1 cargo test -p move-mv-llvm-compiler --test failure-tests
//! ```
//!
//! # Details
//!
//! They do the following:
//!
//! - Create a test for every .move file in failure-tests/
//! - Run `move-mv-llvm-compiler` to compile Move source to LLVM IR.
//! - Compare the actual IR to an existing expected IR.
//!
//! If the `PROMOTE_LLVM_IR` env var is set, the actual IR is promoted to the
//! expected IR.
//!
//! MVIR files may contain "test directives" instructing the harness
//! how to behave. These are specially-interpreted comments of the form
//!
//! - `// ignore` - don't run the test

use anyhow::{anyhow, bail};
use log::debug;
use std::{env, fs, io, path::{Path, PathBuf}};

mod test_common;
use test_common as tc;

pub const TEST_DIR: &str = "tests/failure-tests";

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

    debug!(target: "debug", "current_dir {:#?}", &current_dir);
    debug!(target: "debug", "toml_dir {:#?}", &toml_dir);
    debug!(target: "debug", "p_absolute_path {:#?}", &p_absolute_path);

    let dependency = find_move_toml(&p_absolute_path);

    let mut extra_param = if let Some(lib_dep) = dependency {
        let p = "-p".to_string().to_owned();
        let lib_dep_str = lib_dep.to_str().unwrap().to_string();
        vec![p, lib_dep_str]
    } else {
        let stdlib = "--stdlib".to_string().to_owned();
        vec![stdlib]
    };
    extra_param.push("--test".to_string());
    extra_param.push("-O".to_string());
    extra_param.push("--print-assembly".to_string());

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

    let build_dir = &test_plan.build_dir;
    let ext1 = "ll";
    let ext2 = "o";

    // checking that for each file with ext 'll' there is a file with extension 'o'
    let missing_files = check_files_with_extensions(&build_dir, ext1, ext2)?;

    for file in &missing_files {
        println!("File {file}.{ext1} is present but {file}.{ext2} is missing");
    }
    if missing_files.is_empty() {
        Ok(())
    } else {
        Err(anyhow!("Missed files in directory {:#?}: {:?}: ", build_dir, missing_files))
    }
}

fn check_files_with_extensions(dir: &PathBuf, ext1: &str, ext2: &str) -> Result<Vec<String>, io::Error> {
    let mut missing_files = Vec::new();

    // Read the contents of the directory
    let entries = fs::read_dir(dir)?;

    for entry in entries {
        let entry = entry?;
        let path = entry.path();
        // Check if the entry is a file with the specified ext1 extension
        if path.is_file() && path.extension().and_then(|e| e.to_str()) == Some(ext1) {
            debug!("Found {}-file {}", ext1, &path.to_string_lossy());
            // Construct the corresponding file path with ext2 extension
            let mut new_path = path.clone();
            new_path.set_extension(ext2);
            debug!("Checking for correspondin {}-file {}", ext2, &new_path.to_string_lossy());
            // Check if the corresponding file exists
            if !new_path.exists() {
                if let Some(stem) = path.file_stem().and_then(|s| s.to_str()) {
                    let missed = format!("{}.{}", stem.to_string(), ext2);
                    // missing_files.push(stem.to_string());
                    missing_files.push(missed);
                }
            }
        }
    }
    Ok(missing_files)
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