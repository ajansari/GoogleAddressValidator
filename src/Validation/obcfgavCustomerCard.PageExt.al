namespace OnlyBCFans.GoogleAddress;

using Microsoft.Sales.Customer;

pageextension 92800 "obcfgav Customer Card" extends "Customer Card"
{
    layout
    {
        addafter("Post Code")
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
                ToolTip = 'Check this customer''s address with the address validation service (Google Maps) and accept or ignore the suggested address.';
                ApplicationArea = All;
                Image = Map;

                trigger OnAction()
                begin
                    CurrPage.SaveRecord();
                    Commit();
                    AddressValidation.ValidateCustomerAddress(Rec."No.");
                    Rec.Get(Rec."No.");
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
        addlast("&Customer")
        {
            action(obcfgavValidationLog)
            {
                Caption = 'Google Address Validation Log';
                ToolTip = 'View the address validation checks for this customer.';
                ApplicationArea = All;
                Image = Log;
                RunObject = page "obcfgav Log Entries";
                RunPageLink = "Customer No." = field("No.");
                RunPageView = sorting("Customer No.", "Checked At") order(descending);
            }
        }
    }

    var
        AddressValidation: Codeunit "obcfgav Address Validation";
}
