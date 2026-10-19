namespace OnlyBCFans.GoogleAddress;

using Microsoft.Sales.Customer;
using System.Upgrade;

codeunit 92811 "obcfgav Upgrade Log Source"
{
    Subtype = Upgrade;
    Access = Internal;
    Permissions =
        tabledata "obcfgav Validation Log" = rm,
        tabledata Customer = r;

    trigger OnUpgradePerCompany()
    var
        UpgradeTag: Codeunit "Upgrade Tag";
        UpgradeTags: Codeunit "obcfgav Upgrade Tags";
    begin
        if UpgradeTag.HasUpgradeTag(UpgradeTags.GetLogSourceTag()) then
            exit;

        UpgradeLogSource();
        UpgradeTag.SetUpgradeTag(UpgradeTags.GetLogSourceTag());
    end;

    local procedure UpgradeLogSource()
    var
        Log: Record "obcfgav Validation Log";
        Customer: Record Customer;
    begin
        Customer.SetLoadFields("No.");
        if Log.FindSet(true) then
            repeat
                if Log."Source Table No." = 0 then begin
                    Log."Source Table No." := Database::Customer;
                    Log."Address Type" := Log."Address Type"::Main;
                    Clear(Log."Source SystemId");
                    if Customer.Get(Log."Customer No.") then
                        Log."Source SystemId" := Customer.SystemId;
                    Log."Source Description" := CopyStr(Customer.TableCaption() + ' ' + Log."Customer No.", 1, MaxStrLen(Log."Source Description"));
                    Log.Modify(false);
                end;
            until Log.Next() = 0;
    end;
}
