# OWASP Top 10 Security Checklist

## Contents
- A01: Broken Access Control
- A02: Cryptographic Failures
- A03: Injection
- A04: Insecure Design
- A05: Security Misconfiguration
- A06: Vulnerable and Outdated Components
- A07: Identification and Authentication Failures
- A08: Software and Data Integrity Failures
- A09: Security Logging and Monitoring Failures
- A10: Server-Side Request Forgery (SSRF)

## A01: Broken Access Control

The #1 vulnerability. Access control means enforcing that users can only act within their intended permissions.

**What to check:**
- [ ] Every API endpoint enforces authentication (not just the frontend)
- [ ] Authorization is checked server-side for every protected operation
- [ ] Users cannot access other users' data by changing IDs in URLs (IDOR)
- [ ] Directory traversal is prevented (no `../` in file paths from user input)
- [ ] CORS is configured to allow only specific trusted origins (not `*`)
- [ ] JWT tokens are validated properly (algorithm, signature, expiry, issuer)
- [ ] API rate limiting prevents enumeration attacks
- [ ] Metadata manipulation is blocked (tampering with JWT, cookies, hidden fields)

**Common patterns to flag:**
```javascript
// BAD: Only checks if logged in, not if authorized for THIS resource
app.get('/orders/:id', authenticate, async (req, res) => {
  const order = await db.orders.findById(req.params.id);
  res.json(order); // Any authenticated user can see ANY order
});

// GOOD: Checks ownership
app.get('/orders/:id', authenticate, async (req, res) => {
  const order = await db.orders.findOne({
    id: req.params.id,
    userId: req.user.id  // Scoped to the authenticated user
  });
  if (!order) return res.status(404).json({ error: 'Not found' });
  res.json(order);
});
```

## A02: Cryptographic Failures

Sensitive data exposure through weak or missing cryptography.

**What to check:**
- [ ] Passwords hashed with bcrypt, argon2, or scrypt (never MD5, SHA-1, or SHA-256 alone)
- [ ] Sufficient work factor (bcrypt rounds >= 12, argon2 with recommended params)
- [ ] TLS 1.2+ enforced for all connections
- [ ] Sensitive data encrypted at rest (PII, financial data, health data)
- [ ] Encryption keys managed properly (not hardcoded, rotated periodically)
- [ ] No sensitive data in URLs (tokens, passwords in query strings)
- [ ] Proper random number generation (crypto.randomBytes, not Math.random)

## A03: Injection

Untrusted data sent to an interpreter as part of a command or query.

**What to check:**
- [ ] SQL queries use parameterized statements (never string concatenation)
- [ ] NoSQL queries use typed parameters (not raw user input in operators)
- [ ] OS commands use parameterized execution (never shell interpolation)
- [ ] LDAP queries are parameterized
- [ ] XPath/XML queries are parameterized
- [ ] HTML output is escaped to prevent XSS (use framework auto-escaping)
- [ ] User input in `eval()`, `Function()`, or template literals is blocked
- [ ] GraphQL queries are depth-limited and complexity-bounded

**Injection types and their signatures:**

| Type | Dangerous Pattern | Safe Pattern |
|------|------------------|-------------|
| SQL | `"SELECT * FROM users WHERE id = " + userId` | `db.query("SELECT * FROM users WHERE id = $1", [userId])` |
| XSS | `innerHTML = userInput` | `textContent = userInput` or framework escaping |
| Command | `exec("ls " + userPath)` | `execFile("ls", [userPath])` |
| NoSQL | `{ $where: userInput }` | `{ field: { $eq: userInput } }` |
| Template | `` `Hello ${userInput}` `` in template engine | Template engine with auto-escaping |

## A04: Insecure Design

Flaws in the design itself, not just the implementation.

**What to check:**
- [ ] Business logic has server-side enforcement (not just client-side validation)
- [ ] Rate limiting on resource-intensive operations
- [ ] Transaction limits enforced server-side
- [ ] Multi-step processes can't skip steps
- [ ] File upload validates type, size, and content (not just extension)
- [ ] No mass assignment vulnerabilities (user can't set `role: 'admin'` by adding fields)

## A05: Security Misconfiguration

Default or incomplete configurations that leave openings.

**What to check:**
- [ ] No default credentials in any environment
- [ ] Error messages don't expose stack traces or internal details to users
- [ ] Unnecessary HTTP methods disabled (TRACE, OPTIONS where not needed)
- [ ] Security headers configured: CSP, X-Frame-Options, X-Content-Type-Options, HSTS
- [ ] Directory listing disabled on web servers
- [ ] Debug mode disabled in production
- [ ] Cloud storage buckets/blobs are not publicly accessible by default
- [ ] Database ports not exposed to the internet

## A06: Vulnerable and Outdated Components

Using components with known vulnerabilities.

**What to check:**
- [ ] `npm audit` / `pip audit` / `govulncheck` shows no critical vulnerabilities
- [ ] Dependencies are reasonably up to date (no major versions behind)
- [ ] Unused dependencies are removed (reduce attack surface)
- [ ] Lock files are committed and used for deterministic builds
- [ ] Sub-dependencies (transitive) are also checked

## A07: Identification and Authentication Failures

Weaknesses in the authentication mechanism itself.

**What to check:**
- [ ] Brute force protection (rate limiting, account lockout, CAPTCHA)
- [ ] No credential stuffing vulnerability (breached password checking)
- [ ] Session IDs regenerated after login (session fixation prevention)
- [ ] Session timeout is appropriate (not infinite)
- [ ] Password reset tokens expire and are single-use
- [ ] MFA bypass resistance (recovery codes handled securely)
- [ ] OAuth state parameter used to prevent CSRF

## A08: Software and Data Integrity Failures

Trusting data or code without verification.

**What to check:**
- [ ] CI/CD pipeline integrity (no unsigned code deployments)
- [ ] Deserialization of untrusted data is avoided or secured
- [ ] Software updates verified with signatures
- [ ] Subresource Integrity (SRI) used for CDN-loaded scripts
- [ ] Webhook payloads verified with signatures

## A09: Security Logging and Monitoring Failures

Insufficient detection capability.

**What to check:**
- [ ] Authentication events are logged (login, failed login, logout)
- [ ] Authorization failures are logged
- [ ] Input validation failures are logged (potential attack probing)
- [ ] Sensitive data NOT logged (passwords, tokens, PII)
- [ ] Logs are tamper-proof (centralized, append-only)
- [ ] Alerting on anomalous patterns (burst of failures, unusual access patterns)

## A10: Server-Side Request Forgery (SSRF)

The application fetches a remote resource based on user input without validation.

**What to check:**
- [ ] User-supplied URLs are validated against an allowlist
- [ ] Internal/private IP ranges are blocked (127.0.0.1, 10.x, 172.16.x, 192.168.x)
- [ ] URL scheme is restricted (https only, no file://, gopher://, etc.)
- [ ] Redirects from user-supplied URLs are not followed blindly
- [ ] DNS rebinding attacks are considered (re-resolve after initial check)
