namespace OnlyBCFans.GoogleAddress;

using Microsoft.Foundation.Company;

tableextension 92807 "obcfgav Company Information" extends "Company Information"
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
        field(92801; "obcfgav Ship-to Validated"; Boolean)
        {
            Caption = 'Ship-to Address Validated';
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

        modify("Ship-to Address")
        {
            trigger OnAfterValidate()
            begin
                ResetShipToValidatedIfChanged();
            end;
        }

        modify("Ship-to Address 2")
        {
            trigger OnAfterValidate()
            begin
                ResetShipToValidatedIfChanged();
            end;
        }

        modify("Ship-to City")
        {
            trigger OnAfterValidate()
            begin
                ResetShipToValidatedIfChanged();
            end;
        }

        modify("Ship-to County")
        {
            trigger OnAfterValidate()
            begin
                ResetShipToValidatedIfChanged();
            end;
        }

        modify("Ship-to Post Code")
        {
            trigger OnAfterValidate()
            begin
                ResetShipToValidatedIfChanged();
            end;
        }

        modify("Ship-to Country/Region Code")
        {
            trigger OnAfterValidate()
            begin
                ResetShipToValidatedIfChanged();
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

    local procedure ResetShipToValidatedIfChanged()
    begin
        if not Rec."obcfgav Ship-to Validated" then
            exit;

        if (Rec."Ship-to Address" <> xRec."Ship-to Address") or
           (Rec."Ship-to Address 2" <> xRec."Ship-to Address 2") or
           (Rec."Ship-to City" <> xRec."Ship-to City") or
           (Rec."Ship-to County" <> xRec."Ship-to County") or
           (Rec."Ship-to Post Code" <> xRec."Ship-to Post Code") or
           (Rec."Ship-to Country/Region Code" <> xRec."Ship-to Country/Region Code")
        then
            Rec."obcfgav Ship-to Validated" := false;
    end;
}
