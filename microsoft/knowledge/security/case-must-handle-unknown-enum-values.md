---
bc-version: [all]
domain: security
keywords: [case, else, enum, fallthrough, authentication, authorization, default, switch]
technologies: [al]
countries: [w1]
application-area: [all]
---

# `case` over an enum must handle unknown values via `else`

## Description

A `case` statement that branches on an enum value and lists only the values the author knows about silently falls through when the runtime value is one the code does not name. For business-logic enums, falling through usually means "do nothing"; for security-relevant enums — authentication type, authorization mode, identity provider, encryption strategy, permission scope — falling through means **the code path that was supposed to set up the security context never runs, and the operation proceeds with whatever state the variables had before the `case`**.

A canonical example, lifted from real review traffic:

```al
case SharePointAccount."Authentication Type" of
    SharePointAccount."Authentication Type"::"Client Secret":
        GraphAuthInterface := GraphAuthClientCredentials;
    SharePointAccount."Authentication Type"::Certificate:
        GraphAuthInterface := GraphAuthCertificate;
end;
GraphClient.Initialize(GraphAuthInterface);
```

If a new authentication type is added to the enum, or if a database row carries a value the deployed code does not yet handle, `GraphAuthInterface` is whatever the previous caller left in it (or default-initialised), and the client initialises against an unauthenticated or wrongly-authenticated context. The compiler does not warn — enums are not closed sets to the AL type system the way unions are in other languages.

The same shape shows up outside security: postings codeunits that handle two of three document types and silently skip the third; tax computation that branches on calculation method; report layouts that branch on output format. Wherever a `case` over an enum determines what code path executes, an `else` branch with a controlled error (or a deliberate documented no-op) is required.

## Best Practice

Add an `else` branch to every `case` statement that branches on an enum value when the code paths matter. For security-sensitive branches, raise a `Error` with a message that names the unsupported value:

```al
case SharePointAccount."Authentication Type" of
    SharePointAccount."Authentication Type"::"Client Secret":
        GraphAuthInterface := GraphAuthClientCredentials;
    SharePointAccount."Authentication Type"::Certificate:
        GraphAuthInterface := GraphAuthCertificate;
    else
        Error(UnsupportedAuthTypeErr, SharePointAccount."Authentication Type");
end;
```

For deliberate no-op fall-through, document it: `else // intentional: format X is a passthrough.` so reviewers see the choice was made rather than forgotten. Pair the `else` arm of a security branch with telemetry — an unsupported value reaching this point in production is a deployment signal worth surfacing.

See sample: `case-must-handle-unknown-enum-values.good.al`.

## Anti Pattern

`case` over an enum with no `else`, used to choose which authentication, authorization, or security-state-initialising code path runs. Detection signal: a `case` whose arms write to a single shared output (an interface variable, a credentials record, a permission token) with no `else` arm. The narrower signal — a `case` whose value type is a security-related enum (`Authentication Type`, `Authorization Mode`, `Identity Provider`, `Permission Scope`, `Encryption Algorithm`) — is the high-confidence anti-pattern.

See sample: `case-must-handle-unknown-enum-values.bad.al`.
