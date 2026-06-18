# Component Patterns

## Contents
- Component API design
- Composition patterns
- State management decision guide
- Data fetching patterns
- Error boundary strategy
- Performance patterns

## Component API Design

### Props design rules

1. **Prefer fewer, focused props** over many configurational ones.
   Bad: `<Button size="lg" variant="primary" isLoading isDisabled rounded fullWidth />`
   Better: Compose smaller components or use variants.

2. **Use TypeScript interfaces** with explicit optional markers.
   ```typescript
   interface ButtonProps {
     children: React.ReactNode;
     variant?: 'primary' | 'secondary' | 'ghost';
     size?: 'sm' | 'md' | 'lg';
     disabled?: boolean;
     loading?: boolean;
     onClick?: () => void;
   }
   ```

3. **Extend native HTML elements** for wrapper components.
   ```typescript
   interface InputProps extends React.InputHTMLAttributes<HTMLInputElement> {
     label: string;
     error?: string;
   }
   ```
   This automatically supports all native input props without listing them.

4. **Use `children` for content, not props.**
   Bad: `<Card title="Hello" description="World" />`
   Better: `<Card><Card.Title>Hello</Card.Title><Card.Body>World</Card.Body></Card>`

5. **Don't pass components as string names.**
   Bad: `<Icon name="arrow-right" />`
   Better: `<Icon as={ArrowRightIcon} />` or `<ArrowRightIcon />`

## Composition Patterns

### Compound Components
Components that work together, sharing implicit state through Context:

```typescript
const Tabs = ({ children, defaultValue }) => {
  const [active, setActive] = useState(defaultValue);
  return (
    <TabsContext.Provider value={{ active, setActive }}>
      {children}
    </TabsContext.Provider>
  );
};

Tabs.List = ({ children }) => <div role="tablist">{children}</div>;
Tabs.Tab = ({ value, children }) => {
  const { active, setActive } = useTabsContext();
  return (
    <button role="tab" aria-selected={active === value} onClick={() => setActive(value)}>
      {children}
    </button>
  );
};
Tabs.Panel = ({ value, children }) => {
  const { active } = useTabsContext();
  return active === value ? <div role="tabpanel">{children}</div> : null;
};

// Usage — clean, readable, flexible
<Tabs defaultValue="general">
  <Tabs.List>
    <Tabs.Tab value="general">General</Tabs.Tab>
    <Tabs.Tab value="security">Security</Tabs.Tab>
  </Tabs.List>
  <Tabs.Panel value="general">General settings...</Tabs.Panel>
  <Tabs.Panel value="security">Security settings...</Tabs.Panel>
</Tabs>
```

Use compound components for: tabs, accordions, menus, selects, form groups.

### Render Props / Children as Function
When a component needs to share computed state with its children:

```typescript
<Fetch url="/api/users">
  {({ data, loading, error }) => {
    if (loading) return <Skeleton />;
    if (error) return <ErrorMessage error={error} />;
    return <UserList users={data} />;
  }}
</Fetch>
```

Modern alternative: Custom hooks usually replace render props:
```typescript
const { data, loading, error } = useFetch('/api/users');
```

### Slot Pattern (Layout Components)
```typescript
function PageLayout({ header, sidebar, children, footer }) {
  return (
    <div className="grid grid-cols-[250px_1fr] grid-rows-[auto_1fr_auto]">
      <header className="col-span-2">{header}</header>
      <aside>{sidebar}</aside>
      <main>{children}</main>
      <footer className="col-span-2">{footer}</footer>
    </div>
  );
}
```

## State Management Decision Guide

### When to use what

```
Is the state only used in one component?
  → YES: useState
  
Is the state shared between parent and 1-2 children?
  → YES: Lift state to parent, pass via props
  
Is it being drilled through 3+ levels?
  → Is it rarely changing (theme, locale, auth)?
    → YES: React Context
  → Is it frequently changing?
    → Is it server data (from an API)?
      → YES: TanStack Query / SWR
    → Is it form data?
      → YES: React Hook Form (local to form)
    → Is it shared client state?
      → YES: Zustand (simple) or Redux Toolkit (complex/team)

Should it survive page navigation?
  → YES: URL search params (filters, pagination, sort)

Should it survive page refresh?
  → YES: URL params (shareable) or localStorage (personal preferences)
```

### Server state vs client state

This is the most important distinction. **Don't put server data in Redux/Zustand.**

**Server state** (data from your API):
- Has a source of truth on the server
- Can become stale
- Needs refetching, caching, and invalidation
- Examples: user profile, order list, product catalog
- Tool: TanStack Query, SWR, RTK Query

**Client state** (exists only in the browser):
- Has no server counterpart
- Is always "fresh" by definition
- Examples: sidebar open/closed, selected tab, modal visibility, dark mode
- Tool: useState, Context, Zustand

## Data Fetching Patterns

### TanStack Query (recommended for most apps)

```typescript
// Define the query
function useProjects() {
  return useQuery({
    queryKey: ['projects'],
    queryFn: () => api.get('/projects'),
    staleTime: 5 * 60 * 1000, // Consider data fresh for 5 minutes
  });
}

// Use in component — loading/error/data handled automatically
function ProjectList() {
  const { data: projects, isLoading, error } = useProjects();
  if (isLoading) return <Skeleton />;
  if (error) return <ErrorMessage error={error} />;
  return <List items={projects} />;
}

// Mutations with optimistic updates
function useDeleteProject() {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: (id) => api.delete(`/projects/${id}`),
    onMutate: async (id) => {
      await queryClient.cancelQueries(['projects']);
      const previous = queryClient.getQueryData(['projects']);
      queryClient.setQueryData(['projects'], old => old.filter(p => p.id !== id));
      return { previous };
    },
    onError: (err, id, context) => {
      queryClient.setQueryData(['projects'], context.previous); // Rollback
    },
    onSettled: () => queryClient.invalidateQueries(['projects']),
  });
}
```

## Error Boundary Strategy

```typescript
// Generic error boundary
function ErrorBoundary({ children, fallback }) {
  return (
    <ReactErrorBoundary
      fallbackRender={({ error, resetErrorBoundary }) => (
        fallback || (
          <ErrorPanel
            message="Something went wrong"
            error={error}
            onRetry={resetErrorBoundary}
          />
        )
      )}
    >
      {children}
    </ReactErrorBoundary>
  );
}

// Strategy: wrap at feature boundaries, not at the app root
<ErrorBoundary>        {/* Page-level: catches route errors */}
  <Header />           {/* Not wrapped: if header breaks, show error */}
  <ErrorBoundary>      {/* Feature-level: isolates sidebar failures */}
    <Sidebar />
  </ErrorBoundary>
  <ErrorBoundary>      {/* Feature-level: isolates main content failures */}
    <MainContent />
  </ErrorBoundary>
</ErrorBoundary>
```

Place error boundaries at **feature boundaries**, not around every component. The goal: a sidebar crash doesn't take down the whole page.

## Performance Patterns

### Memoization rules
- `React.memo()`: Wrap components that receive the same props frequently but re-render anyway. Don't wrap everything — it has overhead.
- `useMemo()`: Cache expensive computations. Not needed for simple operations.
- `useCallback()`: Stabilize function references passed as props to memoized children.
- **Rule of thumb**: Don't optimize until you measure a problem. Then optimize surgically.

### Code splitting
```typescript
// Route-level splitting (always do this)
const ProjectPage = React.lazy(() => import('./features/projects/ProjectPage'));
const SettingsPage = React.lazy(() => import('./features/settings/SettingsPage'));

// Component-level splitting (for large, rarely-used components)
const HeavyChart = React.lazy(() => import('./components/HeavyChart'));
```

### List virtualization
For lists over 100 items, use virtualization (react-window or TanStack Virtual) to render only visible items. Don't render 10,000 DOM nodes.
