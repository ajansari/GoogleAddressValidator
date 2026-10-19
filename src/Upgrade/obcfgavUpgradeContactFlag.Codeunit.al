namespace OnlyBCFans.GoogleAddress;

using Microsoft.CRM.BusinessRelation;
using Microsoft.CRM.Contact;
using Microsoft.Sales.Customer;
using System.Upgrade;

codeunit 92812 "obcfgav Upgrade Contact Flag"
{
    Subtype = Upgrade;
    Access = Internal;
    Permissions =
        tabledata Contact = rm,
        tabledata Customer = r,
        tabledata "Contact Business Relation" = r;

    trigger OnUpgradePerCompany()
    var
        UpgradeTag: Codeunit "Upgrade Tag";
        UpgradeTags: Codeunit "obcfgav Upgrade Tags";
    begin
        if UpgradeTag.HasUpgradeTag(UpgradeTags.GetContactFlagTag()) then
            exit;

        UpgradeContactFlag();
        UpgradeTag.SetUpgradeTag(UpgradeTags.GetContactFlagTag());
    end;

    local procedure UpgradeContactFlag()
    var
        Customer: Record Customer;
        ContactBusinessRelation: Record "Contact Business Relation";
        Contact: Record Contact;
    begin
        Customer.SetLoadFields("No.", Address, "Address 2", City, County, "Post Code", "Country/Region Code", "obcfgav Address Validated");
        Customer.SetRange("obcfgav Address Validated", true);
        if Customer.FindSet() then
            repeat
                ContactBusinessRelation.SetCurrentKey("Link to Table", "No.");
                ContactBusinessRelation.SetRange("Link to Table", ContactBusinessRelation."Link to Table"::Customer);
                ContactBusinessRelation.SetRange("No.", Customer."No.");
                if ContactBusinessRelation.FindFirst() then
                    if Contact.Get(ContactBusinessRelation."Contact No.") then
                        if SameAddress(Contact, Customer) and not Contact."obcfgav Address Validated" then begin
                            Contact."obcfgav Address Validated" := true;
                            Contact.Modify(false);
                        end;
            until Customer.Next() = 0;
    end;

    local procedure SameAddress(Contact: Record Contact; Customer: Record Customer): Boolean
    begin
        exit(
            (Contact.Address = Customer.Address) and
            (Contact."Address 2" = Customer."Address 2") and
            (Contact.City = Customer.City) and
            (Contact.County = Customer.County) and
            (Contact."Post Code" = Customer."Post Code") and
            (Contact."Country/Region Code" = Customer."Country/Region Code"));
    end;
}
