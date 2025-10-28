---
name: security-audit
description: OWASP Top 10 security checklist, vulnerability scanning, and security hardening procedures for web applications
---

# Security Audit Checklist

## When to Use This Skill

- Performing security audits on web applications
- Reviewing code for security vulnerabilities
- Implementing security hardening measures
- Following OWASP Top 10 best practices
- Preparing for security compliance audits

## Target Agents

- `cyber-sentinel` - Primary user for security analysis
- `backend-developer` - Secure backend implementation
- `frontend-developer` - Frontend security practices
- `devops-engineer` - Infrastructure security

## OWASP Top 10 (2021) Security Checklist

### 1. Broken Access Control

**Checklist:**

- [ ] Implement proper authentication on all protected routes
- [ ] Enforce authorization checks at the function/method level
- [ ] Deny access by default (whitelist approach)
- [ ] Prevent directory listing and file metadata exposure
- [ ] Log access control failures and alert admins
- [ ] Implement rate limiting on API endpoints
- [ ] Disable CORS for sensitive operations or use strict origins

**Example - Backend Authorization:**

```python
# ✅ Good: Function-level access control
from functools import wraps
from flask import abort

def require_role(role):
    def decorator(f):
        @wraps(f)
        def decorated_function(*args, **kwargs):
            if not current_user.has_role(role):
                abort(403)  # Forbidden
            return f(*args, **kwargs)
        return decorated_function
    return decorator

@app.route('/admin/users')
@require_role('admin')
def admin_users():
    return render_template('admin/users.html')
```

### 2. Cryptographic Failures

**Checklist:**

- [ ] Use TLS 1.2+ for all data in transit
- [ ] Never store passwords in plaintext
- [ ] Use bcrypt, scrypt, or Argon2 for password hashing
- [ ] Encrypt sensitive data at rest
- [ ] Use strong, random keys (minimum 256 bits)
- [ ] Implement proper key management (rotate regularly)
- [ ] Avoid deprecated cryptographic algorithms (MD5, SHA1, DES)

**Example - Password Hashing:**

```python
# ✅ Good: Using bcrypt
import bcrypt

def hash_password(password: str) -> str:
    salt = bcrypt.gensalt(rounds=12)
    return bcrypt.hashpw(password.encode('utf-8'), salt).decode('utf-8')

def verify_password(password: str, hashed: str) -> bool:
    return bcrypt.checkpw(password.encode('utf-8'), hashed.encode('utf-8'))
```

### 3. Injection

**Checklist:**

- [ ] Use parameterized queries (prepared statements)
- [ ] Validate and sanitize all user input
- [ ] Use ORM frameworks properly (avoid raw queries)
- [ ] Implement input validation on both client and server
- [ ] Use Content Security Policy (CSP) headers
- [ ] Escape output when rendering user content
- [ ] Use allowlist input validation where possible

**Example - SQL Injection Prevention:**

```python
# ❌ Bad: Vulnerable to SQL injection
query = f"SELECT * FROM users WHERE email = '{email}'"
cursor.execute(query)

# ✅ Good: Parameterized query
query = "SELECT * FROM users WHERE email = %s"
cursor.execute(query, (email,))

# ✅ Good: ORM usage
user = User.objects.filter(email=email).first()
```

**Example - XSS Prevention:**

```jsx
// ❌ Bad: Vulnerable to XSS
<div dangerouslySetInnerHTML={{__html: userContent}} />

// ✅ Good: React automatically escapes
<div>{userContent}</div>

// ✅ Good: Sanitize HTML if needed
import DOMPurify from 'dompurify';
<div dangerouslySetInnerHTML={{__html: DOMPurify.sanitize(userContent)}} />
```

### 4. Insecure Design

**Checklist:**

- [ ] Implement threat modeling during design phase
- [ ] Use secure design patterns and reference architectures
- [ ] Implement defense in depth (multiple security layers)
- [ ] Separate tenants/users robustly
- [ ] Limit resource consumption per user/transaction
- [ ] Use secure libraries and frameworks
- [ ] Document security requirements and assumptions

**Example - Rate Limiting:**

```python
from flask_limiter import Limiter
from flask_limiter.util import get_remote_address

limiter = Limiter(
    app,
    key_func=get_remote_address,
    default_limits=["200 per day", "50 per hour"]
)

@app.route("/api/login", methods=["POST"])
@limiter.limit("5 per minute")
def login():
    # Login logic
    pass
```

### 5. Security Misconfiguration

**Checklist:**

- [ ] Remove default accounts and passwords
- [ ] Disable unnecessary features, ports, and services
- [ ] Keep all software up to date (dependencies, OS, frameworks)
- [ ] Implement proper error handling (don't expose stack traces)
- [ ] Configure security headers properly
- [ ] Use environment-specific configurations
- [ ] Regular security scanning and patching

**Example - Security Headers:**

```python
# Flask security headers
from flask_talisman import Talisman

talisman = Talisman(
    app,
    force_https=True,
    strict_transport_security=True,
    strict_transport_security_max_age=31536000,
    content_security_policy={
        'default-src': "'self'",
        'img-src': '*',
        'script-src': "'self' 'unsafe-inline'",
        'style-src': "'self' 'unsafe-inline'"
    },
    content_security_policy_nonce_in=['script-src']
)
```

### 6. Vulnerable and Outdated Components

**Checklist:**

- [ ] Maintain inventory of all components and versions
- [ ] Monitor for security advisories (CVE databases)
- [ ] Remove unused dependencies
- [ ] Only use official sources for components
- [ ] Prefer signed packages when available
- [ ] Automate dependency scanning (Snyk, Dependabot)
- [ ] Regularly update dependencies

**Example - Dependency Scanning:**

```bash
# Python - Check for vulnerabilities
pip install safety
safety check

# Node.js - Check for vulnerabilities
npm audit
npm audit fix

# Automated scanning in CI/CD
- name: Run Snyk security scan
  uses: snyk/actions/node@master
  env:
    SNYK_TOKEN: ${{ secrets.SNYK_TOKEN }}
```

### 7. Identification and Authentication Failures

**Checklist:**

- [ ] Implement multi-factor authentication (MFA)
- [ ] Don't ship with default credentials
- [ ] Enforce strong password policies
- [ ] Implement account lockout after failed attempts
- [ ] Use secure session management
- [ ] Regenerate session IDs after authentication
- [ ] Implement proper logout functionality
- [ ] Use HTTP-only and Secure flags on cookies

**Example - Secure Session Management:**

```python
from flask import session
import secrets

app.config['SECRET_KEY'] = secrets.token_hex(32)
app.config['SESSION_COOKIE_SECURE'] = True  # HTTPS only
app.config['SESSION_COOKIE_HTTPONLY'] = True  # No JavaScript access
app.config['SESSION_COOKIE_SAMESITE'] = 'Lax'  # CSRF protection
app.config['PERMANENT_SESSION_LIFETIME'] = 3600  # 1 hour

@app.route('/login', methods=['POST'])
def login():
    if verify_credentials(request.form):
        session.clear()  # Clear old session
        session['user_id'] = user.id
        session.permanent = True
        return redirect('/dashboard')
```

### 8. Software and Data Integrity Failures

**Checklist:**

- [ ] Use digital signatures to verify software integrity
- [ ] Verify dependencies from trusted repositories
- [ ] Use CI/CD pipeline security best practices
- [ ] Implement code review process
- [ ] Separate development, staging, and production
- [ ] Implement proper backup and recovery procedures
- [ ] Monitor for unauthorized changes

**Example - Content Integrity:**

```html
<!-- ✅ Good: Subresource Integrity (SRI) -->
<script
  src="https://cdn.example.com/library.js"
  integrity="sha384-oqVuAfXRKap7fdgcCY5uykM6+R9GqQ8K/uxy9rx7HNQlGYl1kPzQho1wx4JwY8wC"
  crossorigin="anonymous">
</script>
```

### 9. Security Logging and Monitoring Failures

**Checklist:**

- [ ] Log all authentication events (success and failure)
- [ ] Log access control failures
- [ ] Log input validation failures
- [ ] Ensure logs are tamper-proof
- [ ] Implement log monitoring and alerting
- [ ] Don't log sensitive data (passwords, tokens, PII)
- [ ] Use centralized logging solution

**Example - Security Logging:**

```python
import logging
from logging.handlers import RotatingFileHandler

# Configure security logger
security_logger = logging.getLogger('security')
handler = RotatingFileHandler('security.log', maxBytes=10000000, backupCount=5)
formatter = logging.Formatter(
    '%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
handler.setFormatter(formatter)
security_logger.addHandler(handler)
security_logger.setLevel(logging.INFO)

# Log security events
@app.route('/login', methods=['POST'])
def login():
    email = request.form.get('email')
    if verify_credentials(request.form):
        security_logger.info(f"Login successful: {email}")
        return redirect('/dashboard')
    else:
        security_logger.warning(f"Login failed: {email} from {request.remote_addr}")
        return render_template('login.html', error="Invalid credentials")
```

### 10. Server-Side Request Forgery (SSRF)

**Checklist:**

- [ ] Validate and sanitize all user-supplied URLs
- [ ] Use allowlist for allowed domains/IPs
- [ ] Disable HTTP redirections
- [ ] Don't send raw responses to clients
- [ ] Implement network segmentation
- [ ] Block access to internal services
- [ ] Use DNS resolution validation

**Example - SSRF Prevention:**

```python
from urllib.parse import urlparse
import requests

ALLOWED_DOMAINS = ['api.example.com', 'cdn.example.com']

def fetch_url(user_url):
    # Parse and validate URL
    parsed = urlparse(user_url)

    # Check protocol
    if parsed.scheme not in ['http', 'https']:
        raise ValueError("Invalid protocol")

    # Check domain against allowlist
    if parsed.netloc not in ALLOWED_DOMAINS:
        raise ValueError("Domain not allowed")

    # Block private IP ranges
    if is_private_ip(parsed.hostname):
        raise ValueError("Private IPs not allowed")

    # Make request with timeout
    response = requests.get(
        user_url,
        timeout=5,
        allow_redirects=False  # Prevent redirect attacks
    )

    return response.content
```

## Additional Security Measures

### API Security

- [ ] Implement API authentication (OAuth 2.0, JWT)
- [ ] Use API keys for service-to-service communication
- [ ] Implement request signing for sensitive operations
- [ ] Rate limit API endpoints
- [ ] Validate content type headers
- [ ] Implement API versioning

### Frontend Security

- [ ] Implement Content Security Policy
- [ ] Use HTTPS for all resources
- [ ] Sanitize user input before display
- [ ] Don't store sensitive data in localStorage
- [ ] Implement proper CORS configuration
- [ ] Use Subresource Integrity for CDN resources

### Infrastructure Security

- [ ] Use firewalls and security groups
- [ ] Implement network segmentation
- [ ] Regular security patching
- [ ] Encrypt databases and backups
- [ ] Use secrets management (HashiCorp Vault, AWS Secrets Manager)
- [ ] Regular penetration testing

## Security Tools

**Static Analysis:**
- Bandit (Python)
- ESLint security plugin (JavaScript)
- SonarQube

**Dependency Scanning:**
- Snyk
- OWASP Dependency-Check
- GitHub Dependabot

**Dynamic Testing:**
- OWASP ZAP
- Burp Suite
- Nikto

**Secrets Scanning:**
- TruffleHog
- GitGuardian
- git-secrets

## Additional Resources

For more detailed guidance, see:
- [penetration-testing.md](penetration-testing.md) - Penetration testing procedures
- [compliance.md](compliance.md) - GDPR, HIPAA, SOC 2 compliance
- [incident-response.md](incident-response.md) - Security incident response plan
