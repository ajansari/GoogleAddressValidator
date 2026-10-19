namespace OnlyBCFans.GoogleAddress;

using Microsoft.Foundation.Company;
using System.DataAdministration;
using System.Environment.Configuration;
using System.Media;
using System.Privacy;

codeunit 92802 "obcfgav Setup Registration"
{
    Access = Internal;
    Permissions = tabledata "Retention Period" = ri,
                  tabledata "Retention Policy Setup" = ri;

    procedure RegisterAll()
    var
        CountryMgt: Codeunit "obcfgav Country Mgt.";
    begin
        CountryMgt.SeedSupportedCountries();
        RegisterRetentionPolicy();
        RegisterAssistedSetup();
        EnsurePrivacyNotice();
    end;

    procedure PrivacyNoticeId(): Code[50]
    begin
        exit(PrivacyNoticeIdTok);
    end;

    /// <summary>
    /// Creates the privacy notice when it is missing. Safe to call repeatedly: an existing notice is left alone.
    /// Called at install, on company creation, and before every approval check, so an upgraded app has it too.
    /// </summary>
    procedure EnsurePrivacyNotice()
    var
        PrivacyNotice: Codeunit "Privacy Notice";
    begin
        PrivacyNotice.CreatePrivacyNotice(PrivacyNoticeIdTok, PrivacyNoticeNameTxt, PrivacyNoticeLinkTok);
    end;

    local procedure RegisterRetentionPolicy()
    var
        ValidationLog: Record "obcfgav Validation Log";
        RetentionPolicySetup: Record "Retention Policy Setup";
        RetenPolAllowedTables: Codeunit "Reten. Pol. Allowed Tables";
        RetentionPolicySetupCU: Codeunit "Retention Policy Setup";
        TwoYears: DateFormula;
        PeriodCode: Code[20];
    begin
        RetenPolAllowedTables.AddAllowedTable(Database::"obcfgav Validation Log", ValidationLog.FieldNo("Checked At"));
        Evaluate(TwoYears, TwoYearsFormulaTok);
        PeriodCode := RetentionPolicySetupCU.FindOrCreateRetentionPeriod(RetentionPeriodCodeTok, Enum::"Retention Period Enum"::Custom, TwoYears);
        if not RetentionPolicySetup.Get(Database::"obcfgav Validation Log") then begin
            RetentionPolicySetup.Validate("Table Id", Database::"obcfgav Validation Log");
            RetentionPolicySetup.Validate("Apply to all records", true);
            RetentionPolicySetup.Validate("Retention Period", PeriodCode);
            RetentionPolicySetup.Validate(Enabled, false);
            RetentionPolicySetup.Insert(true);
        end;
    end;

    local procedure RegisterAssistedSetup()
    var
        GuidedExperience: Codeunit "Guided Experience";
        CredentialMgt: Codeunit "obcfgav Credential Mgt.";
    begin
        InsertAssistedSetupItem();
        if CredentialMgt.HasApiKey() then
            GuidedExperience.CompleteAssistedSetup(ObjectType::Page, Page::"obcfgav Setup Wizard");
    end;

    local procedure InsertAssistedSetupItem()
    var
        GuidedExperience: Codeunit "Guided Experience";
    begin
        GuidedExperience.InsertAssistedSetup(AssistedSetupTitleTxt, AssistedSetupShortTitleTxt, AssistedSetupDescriptionTxt, 5,
            ObjectType::Page, Page::"obcfgav Setup Wizard", Enum::"Assisted Setup Group"::Connect, '',
            Enum::"Video Category"::Uncategorized, '');
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Guided Experience", 'OnRegisterAssistedSetup', '', false, false)]
    local procedure RegisterOnRegisterAssistedSetup()
    begin
        InsertAssistedSetupItem();
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Company-Initialize", 'OnCompanyInitialize', '', false, false)]
    local procedure RegisterOnCompanyInitialize()
    begin
        RegisterAll();
    end;

    var
        PrivacyNoticeIdTok: Label 'OBCFGAV-ADDRESS', Locked = true;
        PrivacyNoticeNameTxt: Label 'Google Address Validation', MaxLength = 250;
        PrivacyNoticeLinkTok: Label 'https://policies.google.com/privacy', Locked = true;
        RetentionPeriodCodeTok: Label 'OBCFGAV-2Y', Locked = true;
        TwoYearsFormulaTok: Label '<-2Y>', Locked = true;
        AssistedSetupTitleTxt: Label 'Set up Google address validation', MaxLength = 2048;
        AssistedSetupShortTitleTxt: Label 'Google address validation', MaxLength = 50;
        AssistedSetupDescriptionTxt: Label 'Enter the Google Maps API key used to validate addresses.', MaxLength = 1024;
}
