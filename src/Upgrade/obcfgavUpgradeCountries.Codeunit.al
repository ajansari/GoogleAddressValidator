namespace OnlyBCFans.GoogleAddress;

using System.Upgrade;

codeunit 92816 "obcfgav Upgrade Countries"
{
    Subtype = Upgrade;
    Access = Internal;
    Permissions = tabledata "obcfgav Supported Country" = ri;

    trigger OnUpgradePerCompany()
    var
        UpgradeTag: Codeunit "Upgrade Tag";
        UpgradeTags: Codeunit "obcfgav Upgrade Tags";
        CountryMgt: Codeunit "obcfgav Country Mgt.";
    begin
        if UpgradeTag.HasUpgradeTag(UpgradeTags.GetCountriesTag()) then
            exit;

        CountryMgt.SeedSupportedCountries();
        UpgradeTag.SetUpgradeTag(UpgradeTags.GetCountriesTag());
    end;
}
