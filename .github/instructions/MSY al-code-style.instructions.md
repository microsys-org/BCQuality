---
applyTo: "**/*.al"
description: "AL Code structure, formatting, and folder organization guidelines for AL development"
---

# AL Code Style & Formatting Rules

These rules ensure consistent code structure and organization across AL projects, aligned with Microsoft CodeCop and AppSourceCop official analyzers.

## Style guidelines for AL code
- Always use PascalCase for variable and function names.
- Use PascalCase for object names (e.g., tables, pages, reports).
- Maintain a consistent indentation style (4 spaces preferred, aligned with AL Language extension defaults).
- Always use lowercase for reserved AL keywords (e.g., `begin`, `end`, `if`, `then`, `else`, `var`, `procedure`). [AA0241]
- Function calls must always include parentheses, even with no parameters (e.g., `MyProc()` not `MyProc`). [AA0008]
- Use `begin..end` only to enclose compound statements; never for single statements. [AA0005]
- When `begin` follows `then`, `else`, or `do`, it must be on the same line preceded by one space. [AA0013]
- `end`, `if`, `repeat`, `until`, `for`, `while`, `case` must always start a new line. [AA0018]
- Exactly one space on each side of binary operators (`:=`, `+`, `-`, `and`, `or`, `=`). [AA0001]
- Never use nested `with` statements. [AA0040]
- Variable declarations must be ordered by type (Records, Codeunits, Pages, Reports, then scalar types). [AA0021]
- Do not declare unused variables. [AA0137]
- Do not assign values to variables that are never used. [AA0206]
- Do not use identical names for local and global variables. [AA0198]
- Do not write unreachable code. [AA0136]
- Avoid non-indexed fields in filters where possible. [AA0210]
- All table fields of class `Normal` must have the `DataClassification` property set to a value other than `ToBeClassified`. [AS0016]
- Use namespaces with at least two levels for all objects (e.g., `namespace Publisher.AppName.Feature`). [AA0247, AS0127]

## Rule 1: Consistent Indentation and Formatting

### Intent
Maintain consistent code formatting following CodeCop rules (AA0001, AA0005, AA0008, AA0013, AA0018, AA0241). Use 4 spaces for indentation (AL extension default) and follow all structural rules.

### Examples

```al
// Good example - correct formatting, lowercase keywords, parentheses on calls
procedure CalculateDiscount(Amount: Decimal; DiscountPct: Decimal): Decimal
begin
    if DiscountPct > 0 then
        exit(Amount * DiscountPct / 100);

    exit(0);
end;

// Good example - begin on same line after then
if IsValid then begin
    Process();
    Confirm();
end;
```

```al
// Bad example - avoid: missing parentheses, wrong begin placement, uppercase keywords
PROCEDURE CalculateDiscount(Amount: Decimal; DiscountPct: Decimal): Decimal
BEGIN
    IF IsValid THEN
    BEGIN   // begin must be on same line as then [AA0013]
        Process
    END;
END;
```

## Rule 2: Feature-Based Folder Organization

### Intent
Organize code by business features rather than object types to improve maintainability and logical grouping. Use feature-based organization with `src/feature/subfeature/` structure and place shared components in `Common` or `Shared` folders.

### Examples

```
// Good example - Feature-based organization
src/
├── NoSeries/
│   ├── NoSeries.Table.al
│   ├── NoSeries.Page.al
│   └── NoSeriesSetup.Codeunit.al
├── Sales/
│   ├── Invoice/
│   │   ├── SalesInvoice.Page.al
│   │   └── SalesInvoicePosting.Codeunit.al
│   └── Order/
│       └── SalesOrder.Page.al
└── Common/
    ├── Helpers/
    │   └── DateHelper.Codeunit.al
    └── Interfaces/
        └── IPostable.Interface.al
```

```
// Bad example (avoid object-type segregation)
src/
├── Tables/
│   ├── NoSeries.Table.al
│   └── SalesHeader.Table.al
├── Pages/
│   ├── NoSeries.Page.al
│   └── SalesInvoice.Page.al
└── Codeunits/
    ├── NoSeriesSetup.Codeunit.al
    └── SalesInvoicePosting.Codeunit.al
```

## Rule 3: Code Documentation and Comments

### Intent
Provide clear documentation for global functions using XML documentation comments. Code should be self-documenting through clear naming, but global functions in codeunits require proper documentation for API clarity. Never use hardcoded strings in Error/Message/ConfirmManagement calls — always use label variables. [AA0216, AA0217, AA0231]

### Examples

```al
// Good example - XML documentation for global functions, labels for messages
codeunit 50100 "Base64 Convert"
{
    /// <summary>
    /// Converts the value of the input string to its equivalent string representation that is encoded with base-64 digits.
    /// </summary>
    /// <param name="String">The string to convert.</param>
    /// <returns>The string representation, in base-64, of the input string.</returns>
    procedure ToBase64(String: Text): Text
    begin
        exit(Base64ConvertImpl.ToBase64(String));
    end;
}
```

```al
// Good example - label variables for all messages, no StrSubstNo in Error() [AA0231]
procedure ValidateDiscountPercentage(DiscountPct: Decimal)
var
    DiscountTooHighErr: Label 'Discount cannot exceed 50%% due to company policy.';
    DiscountNegativeErr: Label 'Discount percentage cannot be negative.';
begin
    if DiscountPct > 50 then
        Error(DiscountTooHighErr);

    if DiscountPct < 0 then
        Error(DiscountNegativeErr);
end;
```

```al
// Bad example - hardcoded strings and StrSubstNo inside Error() [AA0216, AA0231]
procedure ValidateDiscountPercentage(DiscountPct: Decimal)
begin
    if DiscountPct > 50 then
        Error('Discount cannot exceed 50%%');  // hardcoded - avoid [AA0216]

    if DiscountPct < 0 then
        Error(StrSubstNo('Discount %1 is negative', DiscountPct));  // StrSubstNo in Error - avoid [AA0231]
end;
```

## Rule 4: Modular and Reusable Code Structure

### Intent
Keep code modular and reusable to enhance maintainability and reduce duplication. Write small, focused procedures that do one thing well and use interfaces and patterns where appropriate.

### Examples

```al
// Good example - Modular approach
procedure PostDocument(var DocumentHeader: Record "Sales Header")
begin
  ValidateDocument(DocumentHeader);
  CalculateTotals(DocumentHeader);
  CreateLedgerEntries(DocumentHeader);
  UpdateStatus(DocumentHeader);
end;

local procedure ValidateDocument(var DocumentHeader: Record "Sales Header")
begin
  if DocumentHeader."No." = '' then
    Error('Document number cannot be empty');
end;

local procedure CalculateTotals(var DocumentHeader: Record "Sales Header")
begin
  DocumentHeader.CalcFields(Amount);
end;
```

```al
// Bad example (avoid monolithic procedures)
procedure PostDocument(var DocumentHeader: Record "Sales Header")
begin
  // All validation, calculation, and posting logic in one procedure
  // ... 200+ lines of mixed concerns
end;
``` 

## Rule 5: Slim pages

### Intent
Keep code slim and easy to read

### Examples

```al
// Good example - compact
        area(Content)
        {
            repeater(Group)
            {
                field("Code"; Rec."Code") { }
                field(Description; Rec.Description) { }
            }
        }
```

```al
// Bad example (too long, caption and tooltip already present on table)
procedure PostDocument(var DocumentHeader: Record "Sales Header")
begin
        area(Content)
        {
            repeater(Group)
            {
                field("Code"; Rec."Code") 
                { 

                }
                field(Description; Rec.Description) 
                {
                  
                 }
            }
        }
end;
``` 

## Rule 6: Promoted a Group

### Intent
Keep code slim and easy to read

### Examples

```al
// Good example - compact
        area(Promoted)
        {
            actionref(A01; InitializeData) { }
        }
        area(Processing)
        {
            action(InitializeData)
            {
                ApplicationArea = All;
                Caption = 'Inizializza Dati di Default';
                ToolTip = 'Reinizializza i dati di default per tutte le tabelle Progetti (Tipo Commessa, Categoria Contabile, Scopo Lavoro)';
                Image = Setup;

                trigger OnAction()
                var
                    ProgettiDataInit: Codeunit "MSY TCB Progetti Data Init";
                    ConfirmQst: Label 'Questa azione aggiungerà i dati di default mancanti per tutte le tabelle Progetti. I dati esistenti NON verranno modificati.\\Continuare?';
                    SuccessMsg: Label 'Dati di default inizializzati con successo.';
                begin
                    if not Confirm(ConfirmQst) then
                        exit;

                    ProgettiDataInit.ReinitializeAllData();
                    Message(SuccessMsg);
                    CurrPage.Update(false);
                end;
            }
        }
```

```al
// Bad example (too long, caption and tooltip already present on table)
            action(InitializeData)
            {
                ApplicationArea = All;
                Caption = 'Inizializza Dati di Default';
                ToolTip = 'Reinizializza i dati di default per tutte le tabelle Progetti (Tipo Commessa, Categoria Contabile, Scopo Lavoro)';
                Image = Setup;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;

                trigger OnAction()
                var
                    ProgettiDataInit: Codeunit "MSY TCB Progetti Data Init";
                begin
                    if not Confirm(ConfirmQst) then
                        exit;

                    ProgettiDataInit.ReinitializeAllData();
                    Message(SuccessMsg);
                    CurrPage.Update(false);
                end;
            }
``` 

## Rule 7: Variable Declaration Order

### Intent
Variable declarations must be ordered by type to improve readability. [AA0021] Order: Record, Codeunit, Page, Report, XmlPort, Query, Notification, BigText, DateFormula, RecordId, RecordRef, FieldRef, FilterPageBuilder, then scalar types (Text, Code, Decimal, Integer, Boolean, Date, Time, DateTime, Duration, BigInteger, Guid, Blob).

### Examples

```al
// Good example - correct variable ordering [AA0021]
var
    SalesHeader: Record "Sales Header";
    SalesLine: Record "Sales Line";
    PostingCU: Codeunit "Sales-Post";
    ConfirmManagement: Codeunit "Confirm Management";
    SalesInvoicePage: Page "Posted Sales Invoice";
    ErrorNotification: Notification;
    TotalAmount: Decimal;
    PostingDate: Date;
    IsPosted: Boolean;
    DocumentNo: Code[20];
```

```al
// Bad example - avoid mixed/unordered declarations [AA0021]
var
    TotalAmount: Decimal;
    SalesHeader: Record "Sales Header";
    DocumentNo: Code[20];
    PostingCU: Codeunit "Sales-Post";
    IsPosted: Boolean;
```

## Rule 8: DataClassification on Table Fields

### Intent
All table fields of class `Normal` must set the `DataClassification` property to a value other than `ToBeClassified`. This is required for per-tenant extensions (PTE) and AppSource submissions. [AS0016] Classify fields correctly: use `CustomerContent` for customer data, `SystemMetadata` for system/technical fields, `EndUserIdentifiableInformation` for GDPR-sensitive data.

### Examples

```al
// Good example - DataClassification on every Normal field
table 50100 "Project Header"
{
    fields
    {
        field(1; "No."; Code[20])
        {
            DataClassification = CustomerContent;
        }
        field(2; Description; Text[100])
        {
            DataClassification = CustomerContent;
        }
        field(3; "System Code"; Code[10])
        {
            DataClassification = SystemMetadata;
        }
    }
}
```

```al
// Bad example - missing DataClassification [AS0016]
table 50100 "Project Header"
{
    fields
    {
        field(1; "No."; Code[20]) { }           // missing DataClassification - error
        field(2; Description; Text[100]) { }    // missing DataClassification - error
    }
}
```

## Rule 9: ApplicationArea and Tooltip on Page Controls

### Intent
All page and page extension fields and actions must set the `ApplicationArea` property. [PTE0008, AA0189] All fields and actions on pages must have a `ToolTip` property filled in. [AA0218, AA0220] The `Tooltip` of fields should start with 'Specifies'. [AA0219] Use `FieldCaption()` and `TableCaption()` instead of `FieldName()` and `TableName()`. [AA0448]

### Examples

```al
// Good example - ApplicationArea and ToolTip on all controls
page 50100 "Project List"
{
    PageType = List;
    ApplicationArea = All;

    layout
    {
        area(Content)
        {
            repeater(Group)
            {
                field("No."; Rec."No.") { }
                field(Description; Rec.Description) { }
            }
        }
    }
}
```

```al
// Bad example - missing ApplicationArea and ToolTip [PTE0008, AA0218]
page 50100 "Project List"
{
    layout
    {
        area(Content)
        {
            repeater(Group)
            {
                field("No."; Rec."No.") {
                        ApplicationArea = all;
                        ToolTip = 'Specifies the value of the field';
                 }          // With ApplicationArea and ToolTip
                field(Description; Rec.Description) {
                        ApplicationArea = all;
                        ToolTip = 'Specifies the value of the field';

                 } // With ApplicationArea and ToolTip
            }
        }
    }
}
```

## Rule 10: Namespaces

### Intent
All AL objects must be placed in a namespace with at least two levels. [AA0247, AS0127] Use `using` statements to reference types from other namespaces rather than fully qualifying them inline. Order `using` statements alphabetically. [AA0477]

### Examples

```al
// Good example - two-level namespace and using ordered by name
namespace Techbau.TCB.Projects;

using Microsoft.Sales.Document;
using Techbau.TCB.Common;

codeunit 50100 "Project Management"
{
    // ...
}
```

```al
// Bad example - no namespace or single-level namespace [AA0247]
// (no namespace declaration)
codeunit 50100 "Project Management"
{
    // ...
}
```
