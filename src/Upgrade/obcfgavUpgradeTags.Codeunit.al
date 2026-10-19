namespace OnlyBCFans.GoogleAddress;

using System.Upgrade;

codeunit 92810 "obcfgav Upgrade Tags"
{
    Access = Internal;

    procedure GetLogSourceTag(): Code[250]
    begin
        exit(LogSourceTagTok);
    end;

    procedure GetContactFlagTag(): Code[250]
    begin
        exit(ContactFlagTagTok);
    end;

    procedure GetRecordNoTag(): Code[250]
    begin
        exit(RecordNoTagTok);
    end;

    procedure GetCountriesTag(): Code[250]
    begin
        exit(CountriesTagTok);
    end;

    procedure SetTagsOnInstall()
    var
        UpgradeTag: Codeunit "Upgrade Tag";
    begin
        if not UpgradeTag.HasUpgradeTag(GetLogSourceTag()) then
            UpgradeTag.SetUpgradeTag(GetLogSourceTag());
        if not UpgradeTag.HasUpgradeTag(GetContactFlagTag()) then
            UpgradeTag.SetUpgradeTag(GetContactFlagTag());
        if not UpgradeTag.HasUpgradeTag(GetRecordNoTag()) then
            UpgradeTag.SetUpgradeTag(GetRecordNoTag());
        if not UpgradeTag.HasUpgradeTag(GetCountriesTag()) then
            UpgradeTag.SetUpgradeTag(GetCountriesTag());
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Upgrade Tag", 'OnGetPerCompanyUpgradeTags', '', false, false)]
    local procedure RegisterPerCompanyTags(var PerCompanyUpgradeTags: List of [Code[250]])
    begin
        PerCompanyUpgradeTags.Add(GetLogSourceTag());
        PerCompanyUpgradeTags.Add(GetContactFlagTag());
        PerCompanyUpgradeTags.Add(GetRecordNoTag());
        PerCompanyUpgradeTags.Add(GetCountriesTag());
    end;

    var
        LogSourceTagTok: Label 'OBCFGAV-SC1-LogSource-20261017', Locked = true;
        ContactFlagTagTok: Label 'OBCFGAV-SC1-ContactFlag-20261017', Locked = true;
        RecordNoTagTok: Label 'OBCFGAV-SC1-RecordNo-20261018', Locked = true;
        CountriesTagTok: Label 'OBCFGAV-SC4-Countries-20261018', Locked = true;
}
