namespace OnlyBCFans.GoogleAddress;

page 92802 "obcfgav Log Entries"
{
    PageType = List;
    Caption = 'Google Address Validation Log';
    AdditionalSearchTerms = 'Google Address Validation, Google Maps, address validation log, address check history';
    SourceTable = "obcfgav Validation Log";
    SourceTableView = sorting("Entry No.") order(descending);
    UsageCategory = Lists;
    ApplicationArea = All;
    Editable = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    Permissions = tabledata "obcfgav Validation Log" = r;

    layout
    {
        area(Content)
        {
            repeater(Entries)
            {
                field(entryNo; Rec."Entry No.")
                {
                    Caption = 'Entry No.';
                    ToolTip = 'Specifies the number of the log entry.';
                    ApplicationArea = All;
                }
                field(sourceTableCaption; Rec."Source Table Caption")
                {
                    Caption = 'Source Table';
                    ToolTip = 'Specifies the kind of record whose address was checked, for example Vendor.';
                    ApplicationArea = All;
                }
                field(recordNo; Rec."Record No.")
                {
                    Caption = 'Record No.';
                    ToolTip = 'Specifies the number or key of the record whose address was checked, for example the customer, vendor or employee number. For records with a two-part key, such as a ship-to address, the parts are separated by a slash. It shows the number as it was when the check ran, and it is blank for Company Information.';
                    ApplicationArea = All;
                }
                field(addressType; Rec."Address Type")
                {
                    Caption = 'Address Type';
                    ToolTip = 'Specifies which address of the record was checked: the main address or the company''s ship-to address.';
                    ApplicationArea = All;
                }
                field(checkedAt; Rec."Checked At")
                {
                    Caption = 'Checked At';
                    ToolTip = 'Specifies when the address was checked.';
                    ApplicationArea = All;
                }
                field(userId; Rec."User ID")
                {
                    Caption = 'User ID';
                    ToolTip = 'Specifies the user who ran the check.';
                    ApplicationArea = All;
                }
                field(customerNo; Rec."Customer No.")
                {
                    Caption = 'Customer No.';
                    ToolTip = 'Specifies the number of the customer whose address was checked. It is blank for other kinds of records. Use Record No. instead; this column is kept for entries written by version 1.0.';
                    ApplicationArea = All;
                    Visible = false;
                }
                field(sourceDescription; Rec."Source Description")
                {
                    Caption = 'Source';
                    ToolTip = 'Specifies the record whose address was checked, by its table and key, as it was written when the check ran.';
                    ApplicationArea = All;
                    Visible = false;
                }
                field(sourceTableNo; Rec."Source Table No.")
                {
                    Caption = 'Source Table No.';
                    ToolTip = 'Specifies the number of the table whose record was checked.';
                    ApplicationArea = All;
                    Visible = false;
                }
                field(result; Rec.Result)
                {
                    Caption = 'Result';
                    ToolTip = 'Specifies the outcome of the check.';
                    ApplicationArea = All;
                }
                field(accepted; Rec.Accepted)
                {
                    Caption = 'Accepted';
                    ToolTip = 'Specifies whether the user accepted the suggested address.';
                    ApplicationArea = All;
                }
                field(originalAddress; Rec."Original Address")
                {
                    Caption = 'Original Address';
                    ToolTip = 'Specifies the address values that were sent to the address validation service.';
                    ApplicationArea = All;
                }
                field(originalAddress2; Rec."Original Address 2")
                {
                    Caption = 'Original Address 2';
                    ToolTip = 'Specifies the second address line that was sent to the address validation service.';
                    ApplicationArea = All;
                }
                field(originalCity; Rec."Original City")
                {
                    Caption = 'Original City';
                    ToolTip = 'Specifies the city that was sent to the address validation service.';
                    ApplicationArea = All;
                }
                field(originalState; Rec."Original State")
                {
                    Caption = 'Original State / Province';
                    ToolTip = 'Specifies the state that was sent to the address validation service.';
                    ApplicationArea = All;
                }
                field(originalZipCode; Rec."Original ZIP Code")
                {
                    Caption = 'Original ZIP / Postal Code';
                    ToolTip = 'Specifies the ZIP / Postal Code that was sent to the address validation service.';
                    ApplicationArea = All;
                }
                field(suggestedAddress; Rec."Suggested Address")
                {
                    Caption = 'Suggested Address';
                    ToolTip = 'Specifies the suggested street address that the address validation service returned.';
                    ApplicationArea = All;
                }
                field(suggestedAddress2; Rec."Suggested Address 2")
                {
                    Caption = 'Suggested Address 2';
                    ToolTip = 'Specifies the suggested second address line that the address validation service returned.';
                    ApplicationArea = All;
                }
                field(suggestedCity; Rec."Suggested City")
                {
                    Caption = 'Suggested City';
                    ToolTip = 'Specifies the suggested city that the address validation service returned.';
                    ApplicationArea = All;
                }
                field(suggestedState; Rec."Suggested State")
                {
                    Caption = 'Suggested State / Province';
                    ToolTip = 'Specifies the suggested state that the address validation service returned.';
                    ApplicationArea = All;
                }
                field(suggestedZipCode; Rec."Suggested ZIP Code")
                {
                    Caption = 'Suggested ZIP / Postal Code';
                    ToolTip = 'Specifies the suggested ZIP / Postal Code that the address validation service returned.';
                    ApplicationArea = All;
                }
                field(dpvConfirmation; Rec."DPV Confirmation")
                {
                    Caption = 'Delivery Point Confirmation';
                    ToolTip = 'Specifies the delivery point confirmation code that the address validation service returned.';
                    ApplicationArea = All;
                }
                field(validationGranularity; Rec."Validation Granularity")
                {
                    Caption = 'Validation Granularity';
                    ToolTip = 'Specifies how precisely the service could confirm the address, for example down to the premise.';
                    ApplicationArea = All;
                }
                field(nextAction; Rec."Next Action")
                {
                    Caption = 'Next Action';
                    ToolTip = 'Specifies the next action that the service recommends for the address.';
                    ApplicationArea = All;
                }
                field(providerMessage; Rec."Provider Message")
                {
                    Caption = 'Provider Message';
                    ToolTip = 'Specifies the message that the address validation service returned, or the error text.';
                    ApplicationArea = All;
                }
                field(httpStatus; Rec."HTTP Status")
                {
                    Caption = 'HTTP Status';
                    ToolTip = 'Specifies the HTTP status code of the response. Zero means no response was received.';
                    ApplicationArea = All;
                }
                field(provider; Rec.Provider)
                {
                    Caption = 'Provider';
                    ToolTip = 'Specifies the address validation service that was used for the check, for example Google Maps.';
                    ApplicationArea = All;
                }
                field(addressComplete; Rec."Address Complete")
                {
                    Caption = 'Address Complete';
                    ToolTip = 'Specifies whether the service reported the address as complete.';
                    ApplicationArea = All;
                }
            }
        }
    }

    trigger OnOpenPage()
    begin
        Rec.FilterGroup(2);
        Rec.SetFilter("Source Table No.", AddressSource.ReadableSourceFilter());
        Rec.FilterGroup(0);
    end;

    var
        AddressSource: Codeunit "obcfgav Address Source";
}
