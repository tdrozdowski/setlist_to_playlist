fn main() {
    // Declare custom cfg for tarpaulin coverage exclusion
    println!("cargo::rustc-check-cfg=cfg(tarpaulin_include)");

    let bridge = vec!["src/bridge.rs"];

    for path in &bridge {
        println!("cargo:rerun-if-changed={path}");
    }

    swift_bridge_build::parse_bridges(bridge)
        .write_all_concatenated(out_dir(), bridge_module_name());
}

fn out_dir() -> String {
    std::env::var("OUT_DIR").unwrap()
}

fn bridge_module_name() -> &'static str {
    "generated"
}
