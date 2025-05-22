- When building python programs

  Python Tooling Standards:
  - Use uv for all package management, virtual environments, and Python version management
  - Use uvx for running ephemeral tools and one-off commands
  - Use ruff for linting, formatting, and code quality (replaces black, flake8, isort, etc.)
  - Configure everything in pyproject.toml for consistency
  - Prefer the use of uv, uvx and not pip
  
  Essential Commands:
  - uv init project-name (create new project)
  - uv add package-name (add dependencies)
  - uv run command (run in project environment)
  - uvx tool-name (run tools without installing)
  - ruff check . (lint code)
  - ruff format . (format code)
  - ruff check --fix . (auto-fix issues)

  ## 1. Design Phase

  Core Architecture Principles:
  - Design around data transformation pipelines rather than stateful objects
  - Separate pure computation (future Rust) from I/O and glue code (stays Python)
  - Use algebraic data types - enums and structs, not inheritance hierarchies
  - Plan ownership boundaries - who owns what data and when it's transferred

  Data Design for Rust Compatibility:
  - Use @dataclass(frozen=True) for immutable records that map to Rust structs
  - Prefer Enum over string constants (maps to Rust enums)
  - Design collections as Vec<T> equivalents - avoid nested dicts and mixed types
  - Use NewType pattern: UserId(int) instead of bare integers
  - Structure data as trees, not graphs - avoid circular references entirely

  Function Signatures & Error Handling:
  - Return Optional[T] or Union[T, Error] instead of raising exceptions
  - Use Result pattern: def parse() -> Union[ParsedData, ParseError]
  - Make all side effects explicit in function names: read_file(), write_database()
  - Pass dependencies as parameters, not global access

  Performance & Memory Patterns:
  - Batch operations: process_items(List[Item]) not for item: process_item(item)
  - Use generators for lazy evaluation that maps to Rust iterators
  - Minimize Python object creation in hot paths
  - Design for zero-copy where possible - work with bytes/buffers

  PyO3-Specific Design:
  - Create conversion layers - explicit to_python() and from_python() methods
  - Plan async boundaries - Rust async doesn't directly map to Python async
  - Design APIs as command/query patterns that serialize well
  - Use pyo3 compatible types: prefer i64 over int, f64 over float

  When to Convert to Rust Decision Tree:
  - CPU-intensive loops with numeric computation → High Priority
  - Data parsing/validation with complex rules → High Priority  
  - I/O bound operations → Stay in Python
  - Simple CRUD operations → Stay in Python
  - Hot path called >10k times/second → Consider conversion
  - Memory usage >100MB for data structures → Consider conversion

  ## 2. Conversion Phase

  Migration Strategy:
  - Identify computational kernels first - algorithms, data processing, validation
  - Keep interface adapters in Python - CLI, web frameworks, database ORMs
  - Use feature flags to switch between Python/Rust implementations
  - Profile before and after to validate performance gains justify complexity

  PyO3 Conversion Process:
  - Start with pure functions that take/return simple types (int, str, bytes)
  - Create Rust module: cargo init --lib, add pyo3 to Cargo.toml with extension-module
  - Use #[pyfunction] for standalone functions, #[pyclass] for stateful objects
  - Implement From/Into traits for complex type conversions
  - Use PyResult<T> for all fallible operations - maps to Python exceptions
  - Test each conversion with both unit tests (Rust) and integration tests (Python)

  Build Integration:
  - Use maturin for building PyO3 extensions: uv add --dev maturin
  - Structure: src/lib.rs (Rust), python/yourmodule/ (Python wrapper)
  - Use #[pyo3(name = "python_name")] to match Python naming conventions
  - Create __init__.py that imports from both Python and Rust modules
  - Build with: uv run maturin develop (for development) or maturin build (for release)

  Type Conversion Patterns:
  - Python dict → Rust HashMap: use PyDict::extract()
  - Python list → Rust Vec: use PyList::extract() 
  - Custom classes → #[pyclass] with #[pymethods] for Python methods
  - Use Py<T> for holding Python objects in Rust structs
  - Use PyAny for dynamic typing, but prefer concrete types when possible

  Error Handling Bridge:
  - Create custom error types that implement std::error::Error + IntoPy<PyErr>
  - Use PyErr::new::<pyo3::exceptions::PyValueError, _> for validation errors
  - Map Result<T, E> to PyResult<T> with .map_err(|e| PyErr::from(e))
  - Don't panic in Rust - always return PyResult for Python-visible functions

  Performance Validation:
  - Use Python's cProfile and Rust's criterion for benchmarking
  - Measure memory usage with memory_profiler vs Rust's built-in tools
  - Test with realistic data sizes, not toy examples
  - Consider GIL release: use py.allow_threads(|| ...) for CPU-intensive work

  Code Examples:
  - Python: def process(items: List[Item]) -> Union[List[Output], ProcessError]
  - Rust: #[pyfunction] fn process(items: Vec<PyItem>) -> PyResult<Vec<PyOutput>>
  - Conversion: items.extract::<Vec<Item>>()? and results.into_py(py)
  - Error: Err(ProcessError::Invalid) → PyErr::new::<PyValueError, _>("Invalid input")

  Common Mistakes to Avoid:
  - Don't hold Python objects across await points in async Rust
  - Always use py.allow_threads() for CPU work to release GIL
  - Use PyResult, not unwrap() - Python expects exceptions not panics
  - Clone data at boundaries rather than sharing references
  - Don't use Arc<Mutex<>> for Python-visible state - use PyCell instead

  ## 3. Testing & Debugging

  Testing Strategy:
  - Write Python tests first, then ensure Rust version passes same tests
  - Use pytest with uv run pytest for testing
  - Use hypothesis for property-based testing across both implementations
  - Test memory leaks: Python gc.collect() vs Rust drop semantics
  - Integration tests should import both py_module and rust_module
  - Benchmark with realistic data sizes, not toy examples
  - Use ruff check and ruff format in CI/CD pipelines

  Debugging PyO3:
  - Use RUST_BACKTRACE=1 for Rust panics in Python
  - Python -X dev for reference counting issues  
  - Use py-spy for mixed Python/Rust profiling
  - gdb python for debugging segfaults at the boundary
  - valgrind --tool=memcheck for memory issues

  ## Workflow Practices
  - Regression test each claude conversation to ensure that earlier comments, suggestions and ideas are still being used
  - IMPORTANT: Before completing any task, always check the conversation history to ensure no regressions have been introduced and all previous decisions/changes are preserved

  ## WSL Distributions
  - Preferred WSL distributions are Debian (main system) and Alpine Linux (for utility and temporary systems)
  - Examples and scripts should reflect Debian as the primary distribution
  - Alpine Linux may be used under various names for specific utility or temporary system contexts

# Interaction

- Any time you interact with me, you MUST address me as "Jack"

# Writing code

- YOU MUST NEVER USE --no-verify WHEN COMMITTING CODE
- We prefer simple, clean, maintainable solutions over clever or complex ones, even if the latter are more concise or performant. Readability and maintainability are primary concerns.
- Make the smallest reasonable changes to get to the desired outcome. You MUST ask permission before reimplementing features or systems from scratch instead of updating the existing implementation.
- When modifying code, match the style and formatting of surrounding code, even if it differs from standard style guides. Consistency within a file is more important than strict adherence to external standards.
- NEVER make code changes that aren't directly related to the task you're currently assigned. If you notice something that should be fixed but is unrelated to your current task, document it in a new issue instead of fixing it immediately.
- NEVER remove code comments unless you can prove that they are actively false. Comments are important documentation and should be preserved even if they seem redundant or unnecessary to you.
- All code files should start with a brief 2 line comment explaining what the file does. Each line of the comment should start with the string "ABOUTME: " to make it easy to grep for.
- When writing comments, avoid referring to temporal context about refactors or recent changes. Comments should be evergreen and describe the code as it is, not how it evolved or was recently changed.
- NEVER implement a mock mode for testing or for any purpose. We always use real data and real APIs, never mock implementations.
- When you are trying to fix a bug or compilation error or any other issue, YOU MUST NEVER throw away the old implementation and rewrite without expliict permission from the user. If you are going to do this, YOU MUST STOP and get explicit permission from the user.
- NEVER name things as 'improved' or 'new' or 'enhanced', etc. Code naming should be evergreen. What is new today will be "old" someday.

# Getting help

- ALWAYS ask for clarification rather than making assumptions.
- If you're having trouble with something, it's ok to stop and ask for help. Especially if it's something your human might be better at.

# Testing

- Tests MUST cover the functionality being implemented.
- NEVER ignore the output of the system or the tests - Logs and messages often contain CRITICAL information.
- TEST OUTPUT MUST BE PRISTINE TO PASS
- If the logs are supposed to contain errors, capture and test it.
- NO EXCEPTIONS POLICY: Under no circumstances should you mark any test type as "not applicable". Every project, regardless of size or complexity, MUST have unit tests, integration tests, AND end-to-end tests. If you believe a test type doesn't apply, you need the human to say exactly "I AUTHORIZE YOU TO SKIP WRITING TESTS THIS TIME"

## We practice TDD. That means:

- Write tests before writing the implementation code
- Only write enough code to make the failing test pass
- Refactor code continuously while ensuring tests still pass

### TDD Implementation Process

- Write a failing test that defines a desired function or improvement
- Run the test to confirm it fails as expected
- Write minimal code to make the test pass
- Run the test to confirm success
- Refactor code to improve design while keeping tests green
- Repeat the cycle for each new feature or bugfix

# Specific Technologies

- @~/.claude/docs/python.md
- @~/.claude/docs/source-control.md
- @~/.claude/docs/using-uv.md