namespace OnlyBCFans.GoogleAddress;

using Microsoft.HumanResources.Employee;

pageextension 92811 "obcfgav Employee Card" extends "Employee Card"
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
    }

    actions
    {
        addlast("F&unctions")
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
                    AddressValidation.ValidateAddress(Database::Employee, Rec.SystemId, Enum::"obcfgav Address Type"::Main);
                    Rec.GetBySystemId(Rec.SystemId);
                    CurrPage.Update(false);
                end;
            }
        }
        addlast(Category_Process)
        {
            actionref(obcfgavValidateAddr_Promoted; obcfgavValidateAddress)
            {
            }
        }
        addlast("E&mployee")
        {
            action(obcfgavValidationLog)
            {
                Caption = 'Google Address Validation Log';
                ToolTip = 'View the address validation checks for this record.';
                ApplicationArea = All;
                Image = Log;
                RunObject = page "obcfgav Log Entries";
                RunPageLink = "Source Table No." = const(5200), "Source SystemId" = field(SystemId);
                RunPageView = sorting("Source Table No.", "Source SystemId", "Checked At") order(descending);
            }
        }
    }

    var
        AddressValidation: Codeunit "obcfgav Address Validation";
}
