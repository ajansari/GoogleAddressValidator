namespace OnlyBCFans.GoogleAddress;

using Microsoft.HumanResources.Employee;

tableextension 92811 "obcfgav Employee" extends "Employee"
{
    fields
    {
        field(92800; "obcfgav Address Validated"; Boolean)
        {
            Caption = 'Address Validated';
            DataClassification = CustomerContent;
            InitValue = false;
            Editable = false;
        }

        modify(Address)
        {
            trigger OnAfterValidate()
            begin
                ResetAddressValidatedIfChanged();
            end;
        }

        modify("Address 2")
        {
            trigger OnAfterValidate()
            begin
                ResetAddressValidatedIfChanged();
            end;
        }

        modify(City)
        {
            trigger OnAfterValidate()
            begin
                ResetAddressValidatedIfChanged();
            end;
        }

        modify(County)
        {
            trigger OnAfterValidate()
            begin
                ResetAddressValidatedIfChanged();
            end;
        }

        modify("Post Code")
        {
            trigger OnAfterValidate()
            begin
                ResetAddressValidatedIfChanged();
            end;
        }

        modify("Country/Region Code")
        {
            trigger OnAfterValidate()
            begin
                ResetAddressValidatedIfChanged();
            end;
        }
    }

    local procedure ResetAddressValidatedIfChanged()
    begin
        if not Rec."obcfgav Address Validated" then
            exit;

        if (Rec.Address <> xRec.Address) or
           (Rec."Address 2" <> xRec."Address 2") or
           (Rec.City <> xRec.City) or
           (Rec.County <> xRec.County) or
           (Rec."Post Code" <> xRec."Post Code") or
           (Rec."Country/Region Code" <> xRec."Country/Region Code")
        then
            Rec."obcfgav Address Validated" := false;
    end;
}
