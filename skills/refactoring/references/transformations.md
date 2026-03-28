# Safe Refactoring Transformations

## Contents
- Extract transformations
- Move transformations
- Simplify transformations
- Rename transformations
- Data transformations

## Extract Transformations

### Extract Method
**When**: A code block does a distinct subtask within a larger function.
**How**: Move the block to a new function. Pass needed values as parameters. Return what the caller needs.
**Watch for**: Don't extract if it requires more than 3 parameters — that signals the function is entangled with too much state.

### Extract Variable
**When**: A complex expression is hard to read.
**How**: Assign the expression to a well-named local variable.
**Watch for**: Don't create variables for trivially simple expressions.

### Extract Class
**When**: A class has fields/methods that form a natural cluster separate from the rest.
**How**: Move the cluster to a new class. The original class delegates to the new one.
**Watch for**: Don't extract if the "cluster" is just one method — that's probably Extract Method.

### Extract Interface/Protocol
**When**: Multiple classes share a subset of methods that consumers depend on.
**How**: Define the shared contract explicitly. Depend on the abstraction.
**Watch for**: YAGNI — don't extract an interface with only one implementation unless you need it for testing.

## Move Transformations

### Move Method
**When**: A method uses more data from another class than its own (feature envy).
**How**: Move it to the class whose data it uses most. The original method becomes a delegating call or is removed.

### Move Field
**When**: A field is used more by another class than by its owner.
**How**: Move it and update all references.

### Inline Method
**When**: A method's body is as clear as its name, or the method is only called once and adds no abstraction value.
**How**: Replace the call with the method body. Remove the method.

## Simplify Transformations

### Replace Conditional with Early Return
**When**: Deep nesting from null checks or validation.
**Before**: `if (x) { if (y) { if (z) { doThing() } } }`
**After**: `if (!x) return; if (!y) return; if (!z) return; doThing()`

### Replace Conditional with Polymorphism
**When**: Switch/if-else chains that select behavior based on type.
**How**: Each case becomes a class implementing a shared interface.
**Watch for**: Only worthwhile if the switch appears in multiple places.

### Decompose Conditional
**When**: A complex boolean expression controls flow.
**How**: Extract each part into a well-named method: `isEligible()` instead of `age > 18 && hasId && !isBanned`.

### Replace Magic Number with Named Constant
**When**: A literal value has domain meaning.
**How**: Extract to a constant with a descriptive name.

### Consolidate Duplicate Conditional Fragments
**When**: The same code appears in every branch of a conditional.
**How**: Move it outside the conditional.

## Rename Transformations

### Rename Variable/Function/Class
**When**: The name doesn't reveal intent or uses abbreviations.
**Rules**:
- Functions: verb phrases (`calculateTotal`, `sendNotification`)
- Variables: noun phrases describing the value (`activeUserCount`, not `n`)
- Booleans: question phrases (`isValid`, `hasPermission`, `canEdit`)
- Classes: noun phrases for the concept (`OrderProcessor`, not `OrderHelper`)

## Data Transformations

### Introduce Parameter Object
**When**: A function takes 4+ parameters that travel together.
**How**: Group them into a named object/struct/dataclass.
**Benefit**: Reduces function signatures and provides a home for related logic.

### Replace Data Value with Object
**When**: A primitive (string, number) carries domain meaning (email, money, coordinates).
**How**: Wrap in a domain type with validation and formatting.

### Encapsulate Collection
**When**: A class exposes a mutable collection directly.
**How**: Return a copy or provide add/remove/query methods instead.

## Extended Code Smells

These complement the primary smells listed in SKILL.md Step 2. Each is a signal, not a hard rule — context determines whether the smell warrants action.

### Data Clumps
**Smell**: The same group of fields appears together in multiple function signatures or classes (e.g., `street, city, state, zip`).
**Fix**: Introduce a parameter object or value type (`Address`) that groups them.
**Why**: Scattered groups indicate a missing concept in the domain model. Extracting it provides a home for related validation and behavior.

### Speculative Generality
**Smell**: Abstract classes, interfaces, or parameters that exist "in case we need them later" but have only one implementation or caller.
**Fix**: Remove the unused abstraction. Reinstate it when a second use case actually appears.
**Why**: Unused abstractions add indirection that confuses readers and increases maintenance cost for zero benefit.

### Temporary Fields
**Smell**: Instance variables that are only set and used in certain code paths, leaving them null/undefined the rest of the time.
**Fix**: Extract the fields and the methods that use them into a separate class, or pass them as method parameters instead of storing as state.
**Why**: Readers expect instance variables to be meaningful throughout the object's lifetime. Fields that are sometimes null create confusion and null-check clutter.

### Middle Man
**Smell**: A class where most methods just delegate to another object without adding logic.
**Fix**: Inline the delegator — have callers use the target class directly. Keep the middle man only if it provides a meaningful abstraction boundary.
**Why**: Unnecessary delegation adds a layer of indirection that makes code harder to trace without providing value.

### Data Classes
**Smell**: A class that has only fields and getters/setters with no behavior. Other classes reach in to read its data and perform logic on it (feature envy from the outside).
**Fix**: Push behavior into the data class. If callers compute derived values from its fields, those computations belong on the class itself.
**Why**: Data classes violate encapsulation — the logic that belongs with the data is scattered across the codebase.

### Inappropriate Intimacy
**Smell**: Two classes that know too much about each other's internals — accessing private fields, calling internal methods, or passing internal data structures back and forth.
**Fix**: Move methods or fields to reduce the coupling. Extract a shared interface if both classes need a common contract. Consider merging if the classes are inseparable.
**Why**: Intimate coupling means changes to one class ripple unpredictably into the other.

### Comments as Deodorant
**Smell**: A block comment explaining what a complex piece of code does — not *why*, but *what*. The comment exists because the code is too convoluted to understand on its own.
**Fix**: Refactor the code so the comment becomes unnecessary. Extract methods with descriptive names, rename variables, simplify conditionals.
**Why**: The comment is masking a readability problem. If the code changes and the comment doesn't, it becomes a lie. Self-documenting code is more reliable than commented code.
