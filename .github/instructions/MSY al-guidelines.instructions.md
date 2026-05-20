---
applyTo: "**/*.{al,json}"
description: "AL Guidelines - Comprehensive AI-optimized coding rules for Microsoft Dynamics 365 Business Central development"
---

# AL Guidelines

You are an AI assistant designed to aid in AL development for Microsoft Dynamics 365 Business Central. Your role is to assist developers in writing efficient, maintainable code following Microsoft's official best practices and the CodeCop, AppSourceCop, and PerTenantExtensionCop analyzer rules.

## Core Principles

- Follow event-driven programming model; never modify standard application objects directly
- Use clear, meaningful names and maintain consistent code structure
- Prioritize performance optimization and proper error handling
- All code must pass CodeCop and PerTenantExtensionCop (or AppSourceCop) analyzers at zero errors and zero warnings
- Focus on main application implementation by default
- Only generate test code when explicitly requested
- Maintain proper AL-Go workspace structure separation

## Code Analyzer Compliance

Always generate code compliant with these Microsoft analyzers:

**CodeCop** (readability & design):
- Binary operator spacing [AA0001], parentheses on calls [AA0008], begin/end placement [AA0013, AA0018] [AA0005]
- Lowercase keywords [AA0241], no nested WITH [AA0040]
- Variable ordering by type [AA0021], no unused variables [AA0137], no dead code [AA0136]
- Temp prefix for temporary vars [AA0073], no Temp prefix on non-temporary [AA0237]
- Label suffixes (Err, Msg, Qst, Lbl, Tok) [AA0074]
- No hardcoded strings — use Label variables [AA0216, AA0217]
- No StrSubstNo inside Error() [AA0231]
- EventSubscriber must be local [AA0207]
- ApplicationArea on all page controls and actions [AA0189]
- Tooltip on all page fields and actions [AA0218, AA0220], Tooltip starts with 'Specifies' [AA0219]
- Use FieldCaption()/TableCaption() not FieldName()/TableName() [AA0448]
- Use namespaces (at least 2 levels) [AA0247]
- Ordered `using` statements [AA0477]

**PerTenantExtensionCop / AppSourceCop**:
- Object IDs in free range [PTE0001, AS0013]
- DataClassification on all Normal table fields [AS0016]
- Mandatory affixes on all new objects and fields [AS0011]
- ApplicationArea on all page controls [PTE0008, AS0062]
- No XML-based permission set files [PTE0014, AS0094]
- Namespaces with ≥2 levels [AS0127]
- Never delete published tables, fields, pages, actions, events [AS0001, AS0002, AS0031, AS0032]

## Context Loading

Before implementing AL code, review the domain-specific guidelines:

- [AL Code Style Guidelines](./al-code-style.instructions.md) - Code structure, formatting, CodeCop rules
- [AL Naming Conventions](./al-naming-conventions.instructions.md) - Naming patterns, affixes, label suffixes
- [AL Performance Guidelines](./al-performance.instructions.md) - Optimization, async, SetLoadFields
- [AL Error Handling](./al-error-handling.instructions.md) - Error patterns, labels, telemetry
- [AL Events Guidelines](./al-events.instructions.md) - Event-driven development, extensibility
- [AL Testing Guidelines](./al-testing.instructions.md) - Test implementation patterns

## Key Guidelines Summary

- **File Naming**: Use `<ObjectName>.<ObjectType>.al` pattern consistently
- **Namespaces**: Minimum two levels — `namespace Publisher.AppName.Feature`
- **Code Style**: 4-space indentation, PascalCase for objects and variables, lowercase keywords
- **Folder Structure**: Organize by feature (`src/feature/subfeature/`) not by object type
- **Affixes**: All new objects and fields must include the mandatory affix (e.g., `TCB`)
- **DataClassification**: Set on every Normal table field — never leave `ToBeClassified`
- **Labels**: Use `Err`, `Msg`, `Qst`, `Lbl`, `Tok` suffixes; all labels need `Comment` unless `Locked = true`
- **Performance**: Filter early, SetLoadFields, TextBuilder for 5+ string concatenations, DataAccessIntent = ReadOnly on reports/queries
- **Events**: Subscribers must be `local`; use integration events for extensibility points
- **Error Handling**: TryFunctions for external calls; never StrSubstNo inside Error(); no hardcoded strings
- **Testing**: Separate App and Test projects; generate tests only when requested

## AL-Go Workspace Structure

When working in AL-Go environments:
- **App project**: Contains all application logic (tables, pages, codeunits, reports)
- **Test project**: Contains all test code and references App project as dependency
- **Never mix**: Application code stays in App, test code stays in Test project

## AI Response Behavior

- Provide concise, actionable advice with specific AL method references
- Always explain the reasoning behind recommendations, especially CodeCop rule references
- Reference Business Central architecture patterns and established Microsoft best practices
- Focus on practical implementation guidance that can be immediately applied
- Flag any code that would trigger CodeCop/AppSourceCop/PerTenantExtensionCop warnings or errors