---
applyTo: "**/*.al"
description: "Comprehensive naming conventions for AL files, objects, variables, and functions"
---

# Naming Conventions Rules

Consistent naming conventions improve code readability, maintainability, and compliance with Microsoft CodeCop and AppSourceCop analyzers.

## Rule 1: Object Naming Conventions

### Intent
Use consistent naming patterns for all AL objects to improve discoverability and maintain professional standards. Use PascalCase for object names (tables, pages, reports, codeunits) and meaningful, descriptive names that clearly indicate the object's purpose. Object names must not exceed 30 characters total, with a maximum of 26 characters for the name itself to reserve space for prefixes/affixes (3 characters + 1 space).

All new objects, extension objects, and fields must include the mandatory affix defined in `AppSourceCop.json` or `PerTenantExtensionCop.json` to prevent naming conflicts with other extensions. [AS0011, AS0079]

### Examples

```al
// Good examples (within 26 character limit, with mandatory affix "TCB")
table 50100 "TCB Project Header"         // affix "TCB" + descriptive name
page 50101 "TCB Project List"
codeunit 50102 "TCB Project Posting"
report 50103 "TCB Project Statement"
```

```al
// Bad examples - avoid abbreviations, unclear names, missing affix, or length violations
table 50100 "ProjHdr"                          // Too abbreviated, no affix
page 50101 "SalesInv"                          // Too abbreviated
table 50104 "Very Long Customer Ledger Entry"  // 32 chars - exceeds limit
codeunit 50102 "SIPoster"                      // Unclear abbreviation, no affix
```

## Rule 2: File Naming Conventions

### Intent
Establish consistent file naming patterns that clearly identify object types and facilitate organized development. Use pattern `<ObjectName>.<ObjectType>.al` and maintain consistency across all file names. Ensure file names are descriptive and match the AL object name within the files.

### Examples

```al
// Good examples
TCBProjectHeader.Table.al
TCBProjectList.Page.al
TCBProjectPosting.Codeunit.al
TCBProjectStatement.Report.al
CustomerCardExt.PageExt.al
SalesHeaderExt.TableExt.al

// For implementations and interfaces
IProjectService.Interface.al
TCBProjectServiceImpl.Codeunit.al

// For test files
TCBProjectTests.Codeunit.al
TCBSalesPostingTests.Codeunit.al
```

## Rule 3: Variable and Function Naming

### Intent
Use consistent naming conventions for variables and functions to improve code readability. Use PascalCase for variable and function names, descriptive names that clearly indicate purpose, and avoid abbreviations unless they are well-known business terms.

Variables and parameters must be suffixed with the type or object name. [AA0072] Temporary variables must be prefixed with `Temp`. [AA0073] Non-temporary variables must NOT be prefixed with `Temp`. [AA0237] Do not use identical names for parameters, local variables, and global variables or fields. [AA0198, AA0244, AA0245]

### Examples

```al
// Good examples - Variables suffixed with type [AA0072], Temp prefix for temporaries [AA0073]
var
    CustomerLedgerEntry: Record "Cust. Ledger Entry";         // suffix = object name
    TempSalesLine: Record "Sales Line" temporary;             // "Temp" prefix for temporary records
    TotalAmountDecimal: Decimal;                              // suffix = type
    IsValidTransactionBoolean: Boolean;                       // suffix = type
    DocumentNoCode: Code[20];                                 // suffix = type
```

```al
// Simplified acceptable form - when context is unambiguous
var
    CustomerLedgerEntry: Record "Cust. Ledger Entry";
    TempSalesLine: Record "Sales Line" temporary;
    TotalAmount: Decimal;
    IsValidTransaction: Boolean;
    DocumentNo: Code[20];
```

```al
// Good examples - Functions
procedure CalculateCustomerBalance(CustomerNo: Code[20]): Decimal
procedure ValidateSalesDocument(var SalesHeader: Record "Sales Header")
procedure UpdateInventoryQuantity(ItemNo: Code[20]; Quantity: Decimal)
```

```al
// Bad examples - avoid
var
    TempCustomer: Record Customer;     // not temporary - avoid Temp prefix [AA0237]
    CL: Record "Cust. Ledger Entry";   // unclear abbreviation [AA0072]
    Rec: Record Customer;              // ambiguous name
```

## Rule 4: Label Variable Naming

### Intent
All Label/TextConst variables must have an approved suffix to indicate their usage type. [AA0074] This enforces clarity about how the label is used and improves maintainability. All labels must include a `Comment` for translators unless `Locked = true` is set.

Approved suffixes:
- `Lbl` — general labels (captions, descriptions)
- `Msg` — user messages (Message function)
- `Err` — error messages (Error function)
- `Qst` — questions (Confirm function)
- `Tok` — tokens used in telemetry or locked strings (`Locked = true`)

### Examples

```al
// Good examples - approved label suffixes [AA0074]
var
    CustomerNotFoundErr: Label 'Customer %1 was not found.', Comment = '%1 = Customer No.';
    PostingSuccessMsg: Label 'Document %1 has been posted successfully.', Comment = '%1 = Document No.';
    ConfirmDeleteQst: Label 'Are you sure you want to delete %1?', Comment = '%1 = Record description';
    ProjectCaptionLbl: Label 'Project';
    TelemetryEventTok: Label 'ProjectPosted', Locked = true;
```

```al
// Bad examples - avoid missing or wrong suffixes [AA0074]
var
    CustomerNotFoundError: Label 'Customer not found.';    // wrong suffix (Error vs Err)
    Message1: Label 'Posting done.';                       // no suffix, unclear
    ConfirmText: Label 'Delete this record?';              // no approved suffix
```

## Rule 5: Parameter Naming in Event Subscribers

### Intent
Use meaningful parameter names in event subscribers to improve code clarity and maintainability. Use descriptive parameter names that clearly indicate their purpose, follow Business Central conventions for common parameter types, and maintain consistency across similar event subscribers. Avoid unclear generic names like "Rec" - use specific descriptive names.

### Examples

```al
// Good example - Descriptive parameter names
[EventSubscriber(ObjectType::Table, Database::"Sales Header", OnBeforeInsert, '', false, false)]
local procedure AddDefaultValuesOnBeforeInsertSalesHeader(var SalesHeader: Record "Sales Header"; RunTrigger: Boolean)
begin
    // Event handling logic
end;

[EventSubscriber(ObjectType::Table, Database::Customer, OnBeforeModify, '', false, false)]
local procedure CheckBalanceOnBeforeModifyCustomer(var Customer: Record Customer; var xCustomer: Record Customer)
begin
    // Event handling logic
end;
```

## Rule 6: Interface and Implementation Naming

### Intent
Clearly distinguish between interfaces and their implementations using consistent naming patterns. Prefix interfaces with "I" (e.g., `INoSeries`), use "Impl" suffix for implementation codeunits, and keep interface and implementation names closely related. Ensure names stay within the 26-character limit.

Event handler codeunits should have the "Handler" or "Mgt" suffix to indicate their role.

### Examples

```al
// Good examples (within character limits)
// Interface file: ICustomerService.Interface.al
interface ICustomerService
{
    procedure GetCustomerBalance(CustomerNo: Code[20]): Decimal;
}

// Implementation file: TCBCustomerServiceImpl.Codeunit.al
codeunit 50100 "TCB Customer Service Impl" implements ICustomerService
{
    procedure GetCustomerBalance(CustomerNo: Code[20]): Decimal
    begin
        // Implementation logic
    end;
}

// Event handler codeunit
codeunit 50110 "TCB Sales Events Handler"
{
    [EventSubscriber(ObjectType::Table, Database::"Sales Header", OnBeforeInsert, '', false, false)]
    local procedure OnBeforeInsertSalesHeader(var SalesHeader: Record "Sales Header"; RunTrigger: Boolean)
    begin
        // ...
    end;
}
```