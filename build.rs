use std::path::PathBuf;
use std::process::Command;

fn main() {
    // Declare custom cfg for tarpaulin coverage exclusion
    println!("cargo::rustc-check-cfg=cfg(tarpaulin_include)");

    let bridge = vec!["src/bridge.rs"];

    for path in &bridge {
        println!("cargo:rerun-if-changed={path}");
    }

    // Watch Swift source files for changes
    println!("cargo:rerun-if-changed=swift/Sources/MusicKitBridge.swift");

    // Generate Swift bridge code
    let out_dir = PathBuf::from(out_dir());
    let module_name = bridge_module_name();

    swift_bridge_build::parse_bridges(bridge).write_all_concatenated(&out_dir, module_name);

    // Compile Swift source files into a static library
    compile_swift_library(&out_dir, module_name);
}

fn compile_swift_library(out_dir: &PathBuf, module_name: &str) {
    use std::fs;

    // Files are generated in a subdirectory
    let generated_swift = out_dir
        .join(module_name)
        .join(format!("{}.swift", module_name));
    let swift_bridge_core = out_dir.join("SwiftBridgeCore.swift");
    let swift_bridge_core_header = out_dir.join("SwiftBridgeCore.h");
    let swift_source = PathBuf::from("swift/Sources/MusicKitBridge.swift");
    let generated_header = out_dir.join(module_name).join(format!("{}.h", module_name));

    // Verify generated files exist
    if !generated_swift.exists() {
        panic!(
            "Generated Swift file not found: {}",
            generated_swift.display()
        );
    }
    if !generated_header.exists() {
        panic!(
            "Generated header file not found: {}",
            generated_header.display()
        );
    }
    if !swift_bridge_core.exists() {
        panic!("SwiftBridgeCore not found: {}", swift_bridge_core.display());
    }
    if !swift_bridge_core_header.exists() {
        panic!(
            "SwiftBridgeCore.h not found: {}",
            swift_bridge_core_header.display()
        );
    }

    // Create a combined bridging header that imports both headers
    let bridging_header = out_dir.join("BridgingHeader.h");
    let bridging_header_content = format!(
        "#import \"{}\"\n#import \"{}\"\n",
        swift_bridge_core_header.display(),
        generated_header.display()
    );
    fs::write(&bridging_header, bridging_header_content).expect("Failed to write bridging header");

    // Output library name and path
    let lib_name = "musickit_bridge";
    let lib_path = out_dir.join(format!("lib{}.a", lib_name));

    println!("cargo:rerun-if-changed={}", swift_source.display());

    // Compile Swift files into a static library
    // Use the combined bridging header that imports both SwiftBridgeCore.h and generated.h
    let output = Command::new("swiftc")
        .arg("-emit-library")
        .arg("-static")
        .arg("-module-name")
        .arg(lib_name)
        .arg("-import-objc-header")
        .arg(&bridging_header)
        .arg("-o")
        .arg(&lib_path)
        .arg(&swift_bridge_core) // Include SwiftBridgeCore
        .arg(&generated_swift)
        .arg(&swift_source)
        .arg("-framework")
        .arg("MusicKit")
        .arg("-framework")
        .arg("Foundation")
        .output()
        .expect("Failed to execute swiftc. Is Xcode Command Line Tools installed?");

    if !output.status.success() {
        eprintln!("Swift compilation failed!");
        eprintln!("stdout: {}", String::from_utf8_lossy(&output.stdout));
        eprintln!("stderr: {}", String::from_utf8_lossy(&output.stderr));
        panic!("Swift compilation failed");
    }

    // Tell Cargo to link the Swift library
    println!("cargo:rustc-link-search=native={}", out_dir.display());
    println!("cargo:rustc-link-lib=static={}", lib_name);

    // Add Swift runtime library search paths
    // These are needed for Swift concurrency support
    println!("cargo:rustc-link-search=/usr/lib/swift");
    println!("cargo:rustc-link-arg=-Wl,-rpath,/usr/lib/swift");

    // Link required frameworks
    println!("cargo:rustc-link-lib=framework=MusicKit");
    println!("cargo:rustc-link-lib=framework=Foundation");
}

fn out_dir() -> String {
    std::env::var("OUT_DIR").unwrap()
}

fn bridge_module_name() -> &'static str {
    "generated"
}
