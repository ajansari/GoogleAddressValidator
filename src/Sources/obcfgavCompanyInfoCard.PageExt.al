namespace OnlyBCFans.GoogleAddress;

using Microsoft.Foundation.Company;

pageextension 92807 "obcfgav Company Info. Card" extends "Company Information"
{
    layout
    {
        addafter("Country/Region Code")
        {
            field(obcfgavAddressValidated; Rec."obcfgav Address Validated")
            {
                Caption = 'Address Validated';
                ToolTip = 'Specifies whether the current address was confirmed by, or accepted from, the address validation service. It is set by Validate Address and cleared when the address is edited.';
                ApplicationArea = All;
                Editable = false;
            }
        }
        addafter("Ship-to Country/Region Code")
        {
            field(obcfgavShipToValidated; Rec."obcfgav Ship-to Validated")
            {
                Caption = 'Ship-to Address Validated';
                ToolTip = 'Specifies whether the current ship-to address was confirmed by, or accepted from, the address validation service. It is set by Validate Ship-to Address and cleared when the ship-to address is edited.';
                ApplicationArea = All;
                Editable = false;
            }
        }
    }

    actions
    {
        addlast(Processing)
        {
            action(obcfgavValidateAddress)
            {
                Caption = 'Validate Address';
                ToolTip = 'Check the address of this record with the address validation service (Google Maps) and accept or ignore the suggested address.';
                ApplicationArea = All;
                Image = Map;

                trigger OnAction()
                begin
                    CurrPage.SaveRecord();
                    Commit();
                    AddressValidation.ValidateAddress(Database::"Company Information", Rec.SystemId, Enum::"obcfgav Address Type"::Main);
                    Rec.GetBySystemId(Rec.SystemId);
                    CurrPage.Update(false);
                end;
            }
            action(obcfgavValidateShipToAddress)
            {
                Caption = 'Validate Ship-to Address';
                ToolTip = 'Check the ship-to address of the company with the address validation service (Google Maps) and accept or ignore the suggested address.';
                ApplicationArea = All;
                Image = Map;

                trigger OnAction()
                begin
                    CurrPage.SaveRecord();
                    Commit();
                    AddressValidation.ValidateAddress(Database::"Company Information", Rec.SystemId, Enum::"obcfgav Address Type"::"Ship-to");
                    Rec.GetBySystemId(Rec.SystemId);
                    CurrPage.Update(false);
                end;
            }
        }
        addlast(Promoted)
        {
            actionref(obcfgavValidateAddr_Promoted; obcfgavValidateAddress)
            {
            }
            actionref(obcfgavValidateShipTo_Promoted; obcfgavValidateShipToAddress)
            {
            }
        }
        addlast(Navigation)
        {
            action(obcfgavValidationLog)
            {
                Caption = 'Google Address Validation Log';
                ToolTip = 'View the address validation checks for this record.';
                ApplicationArea = All;
                Image = Log;
                RunObject = page "obcfgav Log Entries";
                RunPageLink = "Source Table No." = const(79), "Source SystemId" = field(SystemId);
                RunPageView = sorting("Source Table No.", "Source SystemId", "Checked At") order(descending);
            }
        }
    }

    var
        AddressValidation: Codeunit "obcfgav Address Validation";
}
