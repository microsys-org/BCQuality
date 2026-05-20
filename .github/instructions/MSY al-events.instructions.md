---
applyTo: "**/*.al"
description: "Guidelines for implementing event-driven patterns and extensibility in AL development"
---

# Event-Driven Development Rules

Event-driven development is fundamental to creating extensible and maintainable Business Central applications that follow the platform's architecture principles. These rules align with Microsoft CodeCop (AA0207) and AL performance guidelines.

## Rule 1: Use Events for Extensibility

### Intent
Implement proper event patterns to enable extensibility without modifying base application code. Subscribe to relevant Business Central events (OnBeforeInsert, OnAfterModify, etc.), create integration events in your code for future extensibility, and use extension objects or events for all changes to standard application objects.

**Critical**: EventSubscriber methods must always be `local`. [AA0207] Never expose event subscribers as public procedures. Do not subscribe to `CompanyOpen` events for non-trivial logic. [PTE0003, AS0061]

### Examples

```al
// Good example - local EventSubscriber with Handler suffix in codeunit name
codeunit 50100 "TCB Sales Events Handler"
{
    [EventSubscriber(ObjectType::Table, Database::"Sales Header", OnBeforeInsert, '', false, false)]
    local procedure OnBeforeInsertSalesHeader(var SalesHeader: Record "Sales Header"; RunTrigger: Boolean)
    begin
        // Custom validation logic
        ValidateCustomFields(SalesHeader);
    end;
}
```

```al
// Bad example - public event subscriber [AA0207]
codeunit 50100 "TCB Sales Events Handler"
{
    [EventSubscriber(ObjectType::Table, Database::"Sales Header", OnBeforeInsert, '', false, false)]
    procedure OnBeforeInsertSalesHeader(var SalesHeader: Record "Sales Header"; RunTrigger: Boolean)  // must be local!
    begin
        ValidateCustomFields(SalesHeader);
    end;
}
```

## Rule 2: Add Integration Events for Extensibility

### Intent
Use integration events to provide extensibility points and clearer API contracts for other developers. Create integration events at logical business process points, document integration event parameters and expected behavior, provide meaningful event names that describe the business context, and implement handled patterns to allow subscribers to control execution flow.

Integration events that have been published must not be deleted, and existing parameters must not be removed or changed. [AS0019, AS0025, AS0026]

### Examples

```al
// Good example - Integration events with handled pattern
codeunit 50101 "TCB Customer Management"
{
    procedure CreateCustomer(var Customer: Record Customer): Boolean
    var
        IsHandled: Boolean;
    begin
        OnBeforeCreateCustomer(Customer, IsHandled);
        if IsHandled then
            exit(true);

        if not Customer.Insert(true) then
            exit(false);

        OnAfterCreateCustomer(Customer);
        exit(true);
    end;

    [IntegrationEvent(false, false)]
    procedure OnBeforeCreateCustomer(var Customer: Record Customer; var IsHandled: Boolean)
    begin
        // Allow extensions to modify customer data before creation
        // Set IsHandled to true to skip default processing
    end;

    [IntegrationEvent(false, false)]
    procedure OnAfterCreateCustomer(var Customer: Record Customer)
    begin
        // Allow extensions to perform additional actions after customer creation
    end;
}
```

```al
// Extension subscribing to integration events - subscriber must be local [AA0207]
codeunit 50102 "TCB Customer Validation Handler"
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"TCB Customer Management", OnBeforeCreateCustomer, '', false, false)]
    local procedure ValidateCustomerOnBeforeCreate(var Customer: Record Customer; var IsHandled: Boolean)
    begin
        ValidateCustomerCreditLimit(Customer);
        if ShouldSkipDefaultProcessing(Customer) then
            IsHandled := true;
    end;
}
```

## Rule 3: Event Parameter Best Practices

### Intent
Design event parameters that provide sufficient context while maintaining performance and usability. Pass record variables by reference when possible, include relevant context parameters, and use meaningful parameter names. Never add `var` modifier to parameters in published events unless it was declared that way from the start. [AS0063, AS0077]

### Examples

```al
// Good example - well-designed event parameters with handled pattern
codeunit 50103 "TCB Document Posting Events"
{
    [IntegrationEvent(false, false)]
    procedure OnBeforePostDocument(var DocumentHeader: Record "Sales Header"; var DocumentLines: Record "Sales Line"; PostingDate: Date; var IsHandled: Boolean)
    begin
        // Comprehensive context for document posting:
        // - DocumentHeader and DocumentLines for full context
        // - PostingDate for temporal context
        // - IsHandled flag for control flow
    end;

    [IntegrationEvent(false, false)]
    procedure OnAfterPostDocument(DocumentHeader: Record "Sales Header"; PostedDocumentNo: Code[20]; PostingResult: Boolean)
    begin
        // Results context after posting:
        // - Original document for reference
        // - Posted document number for tracking
        // - Success/failure indication
    end;
}
```

## Rule 4: Event Subscription Performance Rules

### Intent
Minimize the performance impact of event subscriptions. Table events change SQL behavior significantly — `ModifyAll` and `DeleteAll` on subscribed tables fall back to row-by-row operations instead of bulk SQL. Keep subscriber logic fast, use single-instance codeunits, and avoid expensive operations in subscribers on high-volume tables.

Reference: [Limit your event subscriptions](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/performance/performance-developer#limit-your-event-subscriptions)

### Examples

```al
// Good example - fast, single-instance subscriber
codeunit 50104 "TCB Item Events Handler"
{
    SingleInstance = true;

    [EventSubscriber(ObjectType::Table, Database::Item, OnBeforeModify, '', false, false)]
    local procedure OnBeforeModifyItem(var Item: Record Item; RunTrigger: Boolean)
    begin
        // Keep this minimal - table events force row-by-row SQL operations
        // Avoid: database reads, web calls, heavy calculations
        if Item."TCB Category Code" <> '' then
            ValidateCategoryCode(Item."TCB Category Code");
    end;
}
```

```al
// Bad example - slow subscriber on high-volume table
codeunit 50104 "TCB Item Events Handler"
{
    [EventSubscriber(ObjectType::Table, Database::"Cust. Ledger Entry", OnBeforeInsert, '', false, false)]
    local procedure OnBeforeInsertCustLedgerEntry(var CustLedgerEntry: Record "Cust. Ledger Entry"; RunTrigger: Boolean)
    var
        Customer: Record Customer;
        Classification: Record "TCB Customer Classification";
    begin
        // BAD: multiple DB reads + table extension join on every ledger entry insert
        Customer.Get(CustLedgerEntry."Customer No.");
        if Classification.Get(Customer."TCB Class Code") then
            CustLedgerEntry."TCB Risk Level" := Classification."Risk Level";
    end;
}
```

## Rule 5: Do Not Modify Base Objects — Use Extensions

### Intent
Never modify base application objects directly. Always use table extensions, page extensions, report extensions, or event subscribers. This preserves compatibility with Microsoft updates and allows clean upgrade paths. Obsolete your own published API objects before removing them. [AS0115]

### Examples

```al
// Good example - table extension instead of modifying base table
tableextension 50100 "TCB Sales Header Ext" extends "Sales Header"
{
    fields
    {
        field(50100; "TCB Project No."; Code[20])
        {
            DataClassification = CustomerContent;
            Caption = 'Project No.';
            ToolTip = 'Specifies the project linked to this sales document.';
        }
    }
}

// Good example - page extension instead of modifying base page
pageextension 50100 "TCB Sales Order Ext" extends "Sales Order"
{
    layout
    {
        addafter("External Document No.")
        {
            field("TCB Project No."; Rec."TCB Project No.")
            {
                ApplicationArea = All;
                ToolTip = 'Specifies the project linked to this sales order.';
            }
        }
    }
}
```