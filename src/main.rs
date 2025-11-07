mod bridge;

#[cfg(not(tarpaulin_include))]
fn main() {
    run();
}

fn run() {
    println!("Hello, world!");
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_run() {
        // Test that run executes without panicking
        run();
    }
}
