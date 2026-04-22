default:
    @just --list

# Symlink this template into the local @preview package dir (typship dev)
dev:
    typship dev

# Install this template locally as @local/fine-lncs (typship install local)
install:
    typship install local

# Format all .typ files in place
fmt:
    typstyle -i .

# Check formatting without modifying files (same as CI)
fmt-check:
    typstyle --check .

# Run the test suite
test:
    tt run

# Run everything CI runs
ci: fmt-check test
