---
applyTo: "**/*.al"
description: "Performance optimization guidelines and best practices for AL development"
---

# AL Performance Optimization Rules

These rules focus on writing performant AL code that scales well and provides optimal user experience in Business Central environments.

## AL Performance Guidelines Summary

- Always analyze performance impact when adding new features
- Optimize queries by filtering data as early as possible
- Avoid unnecessary loops; use set-based operations when possible
- Use SetLoadFields to minimize data retrieval
- Use temporary tables, dictionaries, or lists for temporary data storage

## Rule 1: Early Data Filtering and Query Optimization

### Intent

Optimize queries by filtering data as early as possible to reduce data transfer and processing overhead. Apply filters before processing records, use appropriate table keys and sorting, minimize the amount of data retrieved from the database, and use SetRange and SetFilter methods effectively.

### Examples

```al
// Good example - Early filtering
procedure GetNumberOfCustomersByCity(CityFilter: Text): Integer
var
  Customer: Record Customer;
begin
  Customer.SetRange(City, CityFilter);
  Customer.SetRange(Blocked, Customer.Blocked::" ");
  if Customer.FindSet() then
    repeat
      // Process only filtered customers
    until Customer.Next() = 0;
    
  exit(Customer.Count);
end;
```

```al
// Bad example (avoid processing all records)
procedure GetNumberOfCustomersByCity(CityFilter: Text): Integer
var
  Customer: Record Customer;
  Count: Integer;
begin
  if Customer.FindSet() then
    repeat
      // Processing all customers then filtering
      if (Customer.City = CityFilter) and (Customer.Blocked = Customer.Blocked::" ") then
        Count += 1;
    until Customer.Next() = 0;
    
  exit(Count);
end;
```

## Rule 2: Use SetLoadFields for Optimal Data Retrieval

### Intent

Use SetLoadFields to minimize data retrieval from the database by loading only the fields you need. Place SetLoadFields before the Get or Find operation, and include only the fields that will be used in your code.

### Examples

```al
// Good example - SetLoadFields with filtering
Item.SetRange("Third Party Item Exists", false);
Item.SetLoadFields("Item Category Code");
Item.FindFirst();
```

```al
// Bad example (avoid SetLoadFields after filtering)
Item.SetLoadFields("Item Category Code");
Item.SetRange("Third Party Item Exists", false);
Item.FindFirst();
```

## Rule 3: Use Temporary Tables, Dictionaries, and Lists for Performance

### Intent

Leverage temporary tables, dictionaries, and lists to improve performance in read-heavy scenarios and complex data processing. Use temporary tables for structured record data, dictionaries for key-value pairs, and lists for simple collections that are only temporarily needed.

### Examples

```al
// Good example - Using temporary tables for structured data
procedure ProcessSalesData(var TempSalesLine: Record "Sales Line" temporary)
var
  SalesLine: Record "Sales Line";
begin
  // Load data into temporary table once
  if SalesLine.FindSet() then
    repeat
      TempSalesLine := SalesLine;
      TempSalesLine.Insert();
    until SalesLine.Next() = 0;
    
  // Process temporary data multiple times without database hits
  ProcessDiscounts(TempSalesLine);
  CalculateTotals(TempSalesLine);
  ValidateInventory(TempSalesLine);
end;
```

```al
// Good example - Using dictionaries for key-value temporary data
procedure CacheCustomerData()
var
  Customer: Record Customer;
  CustomerCache: Dictionary of [Code[20], Text];
begin
  if Customer.FindSet() then
    repeat
      CustomerCache.Add(Customer."No.", Customer.Name);
    until Customer.Next() = 0;
    
  // Use cached data for lookups
  ProcessOrdersWithCache(CustomerCache);
end;
```

```al
// Good example - Using lists for simple collections
procedure GetBlockedCustomers(): List of [Code[20]]
var
  Customer: Record Customer;
  BlockedCustomers: List of [Code[20]];
begin
  Customer.SetRange(Blocked, Customer.Blocked::All);
  if Customer.FindSet() then
    repeat
      BlockedCustomers.Add(Customer."No.");
    until Customer.Next() = 0;
    
  exit(BlockedCustomers);
end;
```

## Rule 4: Avoid Unnecessary Loops - Use Set-Based Operations

### Intent

Minimize looping operations and favor set-based approaches when possible to improve performance. Use built-in aggregation methods (CalcSums, CalcFields), leverage SQL-based operations through AL, avoid nested loops when possible, and use batch operations for multiple record updates.

### Examples

```al
// Good example - Set-based operation
procedure GetTotalSalesAmount(CustomerNo: Code[20]): Decimal
var
  CustLedgerEntry: Record "Cust. Ledger Entry";
begin
  CustLedgerEntry.SetRange("Customer No.", CustomerNo);
  CustLedgerEntry.CalcSums(Amount);
  exit(CustLedgerEntry.Amount);
end;
```

```al
// Bad example (avoid manual loops for aggregation)
procedure GetTotalSalesAmount(CustomerNo: Code[20]): Decimal
var
  CustLedgerEntry: Record "Cust. Ledger Entry";
  TotalAmount: Decimal;
begin
  CustLedgerEntry.SetRange("Customer No.", CustomerNo);
  if CustLedgerEntry.FindSet() then
    repeat
      TotalAmount += CustLedgerEntry.Amount;
    until CustLedgerEntry.Next() = 0;
    
  exit(TotalAmount);
end;
```

## Rule 5: Performance Impact Analysis

### Intent

Always analyze and consider performance impact when adding new features or modifying existing code. While the AL compiler does not have direct access to performance profilers, you should implement performance-optimal code patterns from the start and consider scalability implications of code changes.

### Examples

```al
// Good example - Performance-conscious implementation
procedure UpdatePricesForItems(var Item: Record Item)
var
    ItemCount: Integer;
begin
    // Check data volume before processing
    ItemCount := Item.Count();

    if ItemCount > 1000 then
        UpdatePricesInBatches(Item)
    else
        UpdatePricesDirectly(Item);
end;
```

```al
// Good example - Batched modifications to minimize database writes
procedure UpdateCustomerStatistics(CustomerNo: Code[20])
var
    Customer: Record Customer;
    TotalBalance: Decimal;
    LastPaymentDate: Date;
begin
    // Calculate all values first
    CalculateCustomerTotals(CustomerNo, TotalBalance, LastPaymentDate);

    // Single database write with all changes
    Customer.SetLoadFields("Balance (LCY)", "Last Payment Date");
    if Customer.Get(CustomerNo) then begin
        Customer."Balance (LCY)" := TotalBalance;
        Customer."Last Payment Date" := LastPaymentDate;
        Customer.Modify(true);
    end;
end;
```

## Rule 6: Use Built-In Data Structures (TextBuilder, Dictionary, List)

### Intent

Use the right built-in data structure for each scenario to maximize performance. Use `TextBuilder` instead of `+=` on `Text` when concatenating 5 or more strings or in loops. Use `Dictionary` for key-value lookups. Use `List` instead of temporary tables for simple unbound collections. Use `Media`/`MediaSet` instead of `Blob` for images.

References: [TextBuilder](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/textbuilder/textbuilder-data-type), [Dictionary](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/dictionary/dictionary-data-type), [List](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/list/list-data-type)

### Examples

```al
// Good example - TextBuilder for concatenating many strings
procedure BuildCsvLine(Values: List of [Text]): Text
var
    Builder: TextBuilder;
    Value: Text;
begin
    foreach Value in Values do begin
        if Builder.Length > 0 then
            Builder.Append(',');
        Builder.Append(Value);
    end;
    exit(Builder.ToText());
end;
```

```al
// Bad example - += in a loop is slow for many concatenations
procedure BuildCsvLine(Values: List of [Text]): Text
var
    Result: Text;
    Value: Text;
begin
    foreach Value in Values do
        Result += ',' + Value;   // slow - allocates new string each iteration
    exit(Result);
end;
```

## Rule 7: Async and Parallel Execution Patterns

### Intent

Offload long-running operations from the UI thread to background sessions to keep the UI responsive. Use Page Background Tasks for cues and read-only calculations shown on pages. Use `TaskScheduler.CreateTask` or Job Queue for durable background processing. Never block the UI thread with long database or web service operations.

Reference: [Page Background Tasks](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-page-background-tasks)

### Examples

```al
// Good example - Page Background Task for cue calculation
pageextension 50100 "Project Role Center Ext" extends "Business Manager Role Center"
{
    trigger OnOpenPage()
    begin
        // Schedule background calculation instead of blocking UI
        CurrPage.EnqueueBackgroundTask(BackgroundTaskId, Codeunit::"TCB Project Cue Calculator", BackgroundParameters);
    end;

    trigger OnPageBackgroundTaskCompleted(TaskId: Integer; Results: Dictionary of [Text, Text])
    begin
        if TaskId = BackgroundTaskId then
            UpdateCueValues(Results);
    end;
}
```

## Rule 8: DataAccessIntent for Read-Only Scenarios

### Intent

Set `DataAccessIntent = ReadOnly` on reports, API pages, and queries that only read data. This allows Business Central to route queries to a read-only replica (Read Scale-Out), reducing load on the primary database and improving performance for analytical workloads.

Reference: [DataAccessIntent property](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-dataaccessintent-property)

### Examples

```al
// Good example - read-only report uses replica
report 50100 "TCB Project Summary"
{
    DataAccessIntent = ReadOnly;

    dataset
    {
        dataitem(ProjectHeader; "TCB Project Header")
        {
            // Report logic...
        }
    }
}
```

```al
// Good example - API query with read-only intent for Power BI
query 50100 "TCB Project API Query"
{
    QueryType = API;
    DataAccessIntent = ReadOnly;

    elements
    {
        dataitem(ProjectHeader; "TCB Project Header")
        {
            column(No; "No.") { }
            column(Description; Description) { }
        }
    }
}
```

## Rule 9: Limit Event Subscription Performance Impact

### Intent

Event subscriptions have a performance cost. Follow these guidelines to minimize their impact:
- Use **single-instance codeunits** for event subscribers when possible.
- Keep subscriber codeunits small — codeunit size matters.
- Prefer **manually binding** subscribers over static automatic where performance is critical.
- Table events (OnBeforeInsert, OnBeforeModify, etc.) change SQL behavior: `ModifyAll` and `DeleteAll` fall back to row-by-row operations when table events are subscribed. Be aware of this on high-volume tables.
- Minimize work done in `OnCompanyOpen` and `OnCompanyOpenCompleted` event subscribers — all sessions wait for these to complete before starting.

Reference: [Limit your event subscriptions](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/performance/performance-developer#limit-your-event-subscriptions)

### Examples

```al
// Good example - single-instance subscriber codeunit
codeunit 50100 "TCB Sales Events Handler"
{
    SingleInstance = true;  // reduces object creation overhead

    [EventSubscriber(ObjectType::Table, Database::"Sales Header", OnBeforeInsert, '', false, false)]
    local procedure OnBeforeInsertSalesHeader(var SalesHeader: Record "Sales Header"; RunTrigger: Boolean)
    begin
        // Keep this handler minimal and fast
        if SalesHeader."TCB Project No." = '' then
            exit;
        ValidateProjectLink(SalesHeader);
    end;
}
```

## Rule 10: Use Partial Records (SetLoadFields)

### Intent

Use `SetLoadFields` to load only the fields needed for the operation. Partial records improve performance by reducing data transfer from the database and limiting table extension joins. Always place `SetLoadFields` after `SetRange`/`SetFilter` calls and before `Find`/`Get`.

Reference: [Using Partial Records](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-partial-records)

### Examples

```al
// Good example - partial record load
procedure GetProjectDescriptions(): List of [Text]
var
    ProjectHeader: Record "TCB Project Header";
    Descriptions: List of [Text];
begin
    ProjectHeader.SetRange(Status, ProjectHeader.Status::Active);
    ProjectHeader.SetLoadFields(Description);   // load only what we need
    if ProjectHeader.FindSet() then
        repeat
            Descriptions.Add(ProjectHeader.Description);
        until ProjectHeader.Next() = 0;
    exit(Descriptions);
end;
```

```al
// Bad example - loading all fields when only a few are needed
procedure GetProjectDescriptions(): List of [Text]
var
    ProjectHeader: Record "TCB Project Header";
    Descriptions: List of [Text];
begin
    if ProjectHeader.FindSet() then  // loads ALL fields including extensions - wasteful
        repeat
            Descriptions.Add(ProjectHeader.Description);
        until ProjectHeader.Next() = 0;
    exit(Descriptions);
end;
```