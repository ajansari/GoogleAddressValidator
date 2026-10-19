namespace OnlyBCFans.GoogleAddress;

using Microsoft.Sales.Customer;
using System.Reflection;
using System.Security.AccessControl;

table 92801 "obcfgav Validation Log"
{
    Caption = 'Google Address Validation Log';
    DataClassification = CustomerContent;
    LookupPageId = "obcfgav Log Entries";
    DrillDownPageId = "obcfgav Log Entries";

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
            AutoIncrement = true;
        }
        field(2; "Customer No."; Code[20])
        {
            Caption = 'Customer No.';
            TableRelation = Customer."No.";
        }
        field(3; "Checked At"; DateTime)
        {
            Caption = 'Checked At';
        }
        field(4; "User ID"; Code[50])
        {
            Caption = 'User ID';
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = User."User Name";
            ValidateTableRelation = false;
        }
        field(5; Result; Enum "obcfgav Validation Result")
        {
            Caption = 'Result';
        }
        field(6; Accepted; Boolean)
        {
            Caption = 'Accepted';
        }
        field(7; "Original Address"; Text[100])
        {
            Caption = 'Original Address';
        }
        field(8; "Original Address 2"; Text[50])
        {
            Caption = 'Original Address 2';
        }
        field(9; "Original City"; Text[30])
        {
            Caption = 'Original City';
        }
        field(10; "Original State"; Text[30])
        {
            Caption = 'Original State / Province';
        }
        field(11; "Original ZIP Code"; Code[20])
        {
            Caption = 'Original ZIP / Postal Code';
        }
        field(12; "Suggested Address"; Text[250])
        {
            Caption = 'Suggested Address';
        }
        field(13; "Suggested Address 2"; Text[250])
        {
            Caption = 'Suggested Address 2';
        }
        field(14; "Suggested City"; Text[250])
        {
            Caption = 'Suggested City';
        }
        field(15; "Suggested State"; Text[250])
        {
            Caption = 'Suggested State / Province';
        }
        field(16; "Suggested ZIP Code"; Text[250])
        {
            Caption = 'Suggested ZIP / Postal Code';
        }
        field(17; "DPV Confirmation"; Code[10])
        {
            Caption = 'Delivery Point Confirmation';
        }
        field(18; "Validation Granularity"; Text[30])
        {
            Caption = 'Validation Granularity';
        }
        field(19; "Next Action"; Text[30])
        {
            Caption = 'Next Action';
        }
        field(20; "Provider Message"; Text[2048])
        {
            Caption = 'Provider Message';
        }
        field(21; "HTTP Status"; Integer)
        {
            Caption = 'HTTP Status';
        }
        field(22; Provider; Enum "obcfgav Address Provider")
        {
            Caption = 'Provider';
        }
        field(23; "Address Complete"; Boolean)
        {
            Caption = 'Address Complete';
        }
        field(24; "Source Table No."; Integer)
        {
            Caption = 'Source Table No.';
        }
        field(25; "Address Type"; Enum "obcfgav Address Type")
        {
            Caption = 'Address Type';
        }
        field(26; "Source SystemId"; Guid)
        {
            Caption = 'Source SystemId';
        }
        field(27; "Source Description"; Text[250])
        {
            Caption = 'Source';
        }
        field(28; "Source Table Caption"; Text[249])
        {
            Caption = 'Source Table';
            FieldClass = FlowField;
            CalcFormula = lookup(AllObjWithCaption."Object Caption" where("Object Type" = const(Table), "Object ID" = field("Source Table No.")));
            Editable = false;
        }
        field(29; "Record No."; Text[100])
        {
            Caption = 'Record No.';
        }
    }

    keys
    {
        key(PK; "Entry No.")
        {
            Clustered = true;
        }
        key(CustomerCheckedAt; "Customer No.", "Checked At")
        {
        }
        key(SourceCheckedAt; "Source Table No.", "Source SystemId", "Checked At")
        {
        }
    }

    trigger OnInsert()
    begin
        Rec.TestField("Source Table No.");
        if Rec."Source Table No." = Database::Customer then
            Rec.TestField("Customer No.");
    end;
}
