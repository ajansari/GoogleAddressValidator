namespace OnlyBCFans.GoogleAddress;

codeunit 92801 "obcfgav Install"
{
    Subtype = Install;
    Access = Internal;

    trigger OnInstallAppPerCompany()
    var
        SetupRegistration: Codeunit "obcfgav Setup Registration";
        UpgradeTags: Codeunit "obcfgav Upgrade Tags";
    begin
        SetupRegistration.RegisterAll();
        UpgradeTags.SetTagsOnInstall();
    end;
}
