---
applyTo: "**/*.al"
description: "AL Error handling patterns, debugging techniques, and troubleshooting guidelines for AL development"
---

# AL Error Handling & Troubleshooting Rules

Robust error handling and effective troubleshooting practices are essential for maintaining reliable Business Central applications. These rules align with Microsoft CodeCop analyzer rules (AA0216, AA0217, AA0231) and AL platform patterns.

## Rule 1: Use TryFunctions for Error Handling

### Intent
Implement proper error handling using TryFunctions to manage exceptions gracefully and provide meaningful user feedback. Use TryFunctions for error handling in scenarios where rollback is required, implement proper exception handling for external service calls, provide meaningful error messages to users, and log errors appropriately for debugging purposes. When generating code that might fail (external calls, data operations, calculations), implement appropriate TryFunction error handling and provide clear error messages.

### Examples

```al
// Good example - TryFunction with proper error handling and error labels
procedure ProcessPayment(Amount: Decimal): Boolean
var
    ErrorText: Text;
    PaymentProcessingFailedLbl: Label 'Payment processing failed: %1', Comment = '%1 = Error message';
    PaymentProcessingFailedTok: Label 'PaymentProcessingFailed', Locked = true;
begin
    if not TryProcessPaymentInternal(Amount) then begin
        ErrorText := GetLastErrorText();
        Session.LogMessage('PAY001', PaymentProcessingFailedTok, Verbosity::Error,
            DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Error', ErrorText);
        Message(PaymentProcessingFailedLbl, ErrorText);
        exit(false);
    end;
    exit(true);
end;

[TryFunction]
local procedure TryProcessPaymentInternal(Amount: Decimal)
var
    PaymentService: Codeunit "Payment Service";
begin
    PaymentService.ProcessPayment(Amount);
end;
```

```al
// Bad example - no error handling, hardcoded error message
procedure ProcessPayment(Amount: Decimal)
var
    PaymentService: Codeunit "Payment Service";
begin
    // No error handling - unhandled exceptions will crash the session
    PaymentService.ProcessPayment(Amount);
end;
```

## Rule 2: Use Error Labels for All Messages

### Intent
All error messages, warnings, and user messages must use label variables instead of hardcoded text. [AA0216] This ensures proper localization support and maintainability. Define labels with appropriate `Comment` for translators and use `Locked = true` for technical messages that must not be translated. Never use `StrSubstNo` directly inside `Error()` — assign to a variable first. [AA0231] Never concatenate strings as parameters in `Error()`. [AA0217]

### Examples

```al
// Good example - using error labels, no StrSubstNo inside Error() [AA0216, AA0231]
procedure ValidateBusinessLogic(SalesHeader: Record "Sales Header")
var
    Customer: Record Customer;
    CustomerNotFoundErr: Label 'Customer %1 does not exist for sales document %2.', Comment = '%1 = Customer No., %2 = Sales Header No.';
    CustomerBlockedErr: Label 'Customer %1 is blocked (%2). Cannot process sales document %3.', Comment = '%1 = Customer No., %2 = Blocked reason, %3 = Sales Header No.';
    EmptyHeaderNoErr: Label 'Sales header number cannot be empty.';
    ErrorMessage: Text;
begin
    if SalesHeader."No." = '' then
        Error(EmptyHeaderNoErr);

    if not Customer.Get(SalesHeader."Sell-to Customer No.") then
        Error(CustomerNotFoundErr, SalesHeader."Sell-to Customer No.", SalesHeader."No.");

    if Customer.Blocked <> Customer.Blocked::" " then
        Error(CustomerBlockedErr, Customer."No.", Customer.Blocked, SalesHeader."No.");
end;
```

```al
// Bad example - hardcoded strings, StrSubstNo inside Error() [AA0216, AA0231]
procedure ValidateBusinessLogic(SalesHeader: Record "Sales Header")
var
    Customer: Record Customer;
begin
    if not Customer.Get(SalesHeader."Sell-to Customer No.") then
        Error('Customer not found');  // hardcoded [AA0216]

    if Customer.Blocked <> Customer.Blocked::" " then
        Error(StrSubstNo('Customer %1 is blocked', Customer."No."));  // StrSubstNo in Error [AA0231]
end;
```

## Rule 3: Code Compilation and Correctness Priority

### Intent
Generated AL code should prioritize correctness over immediate compilation. Code can fail to compile if AI suggests base functions or events that don't exist, or if variables in event subscriptions are incorrect. When this happens, leave space for manual fixes rather than changing the intended behavior. If you're confident the logic should work as suggested but there are naming or parameter issues, leave it for user correction rather than altering the business logic.

### Examples

```al
// Good example - Correct logic even if function names need verification
procedure HandleCustomerModification(var Customer: Record Customer)
var
    CustomerValidation: Codeunit "Customer Validation"; // May need verification
begin
    // Correct business logic - even if codeunit name needs adjustment
    if not CustomerValidation.ValidateCustomerData(Customer) then
        Error(ValidationFailedErr);

    Customer.Modify(true);
end;
```

## Rule 4: Custom Telemetry Implementation

### Intent
Add custom telemetry for tracking business-critical operations, but only when explicitly requested by the user. Use `Session.LogMessage` for custom telemetry with appropriate verbosity levels and `DataClassification`. Include relevant custom dimensions for context and use proper telemetry scope for extension publishers. Telemetry message labels must be `Locked = true` and end with the `Tok` suffix.

### Examples

```al
// Good example - Custom telemetry with locked labels (only when user explicitly requests it)
procedure PostSalesDocument(var SalesHeader: Record "Sales Header")
var
    TelemetryCustomDimensions: Dictionary of [Text, Text];
    SalesDocPostedTok: Label 'SalesDocumentPosted', Locked = true;
    SalesDocPostFailedTok: Label 'SalesDocumentPostingFailed', Locked = true;
begin
    TelemetryCustomDimensions.Add('DocumentType', Format(SalesHeader."Document Type"));
    TelemetryCustomDimensions.Add('CustomerNo', SalesHeader."Sell-to Customer No.");

    if TryPostSalesDocument(SalesHeader) then
        Session.LogMessage('SAL001', SalesDocPostedTok,
            Verbosity::Normal, DataClassification::SystemMetadata,
            TelemetryScope::ExtensionPublisher, TelemetryCustomDimensions)
    else begin
        TelemetryCustomDimensions.Add('ErrorText', GetLastErrorText());
        Session.LogMessage('SAL002', SalesDocPostFailedTok,
            Verbosity::Error, DataClassification::SystemMetadata,
            TelemetryScope::ExtensionPublisher, TelemetryCustomDimensions);
    end;
end;
```

## Rule 5: Validate Only at System Boundaries

### Intent
Do not add error handling for scenarios that cannot happen. Only validate input at system boundaries (web service entry points, UI triggers, event subscribers processing external data). Internal procedures called from validated code should not repeat the same validations — this adds noise and reduces performance. Use `AssertError` only in test codeunits. [AA0161, AS0058]

### Examples

```al
// Good example - validation at the boundary (page trigger), not in every internal proc
trigger OnAction()
begin
    ValidateAndPostDocument(Rec);   // single validated entry point
end;

procedure ValidateAndPostDocument(var SalesHeader: Record "Sales Header")
var
    EmptyNoErr: Label 'Document number is required.';
begin
    if SalesHeader."No." = '' then
        Error(EmptyNoErr);
    // internal calls trust validated input
    PostDocument(SalesHeader);
end;

local procedure PostDocument(var SalesHeader: Record "Sales Header")
begin
    // no re-validation needed here - caller already validated
    SalesHeader.Status := SalesHeader.Status::Released;
    SalesHeader.Modify(true);
end;
```