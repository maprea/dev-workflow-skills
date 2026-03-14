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
