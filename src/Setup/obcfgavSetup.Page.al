namespace OnlyBCFans.GoogleAddress;

using System.Privacy;

page 92800 "obcfgav Setup"
{
    Caption = 'Google Address Validation Setup';
    AdditionalSearchTerms = 'Google Address Validation, Google Maps, address validation, address check, API key';
    PageType = Card;
    SourceTable = "obcfgav Setup";
    UsageCategory = Administration;
    ApplicationArea = All;
    InsertAllowed = false;
    DeleteAllowed = false;

    layout
    {
        area(Content)
        {
            group(General)
            {
                Caption = 'General';

                field(enabled; Rec.Enabled)
                {
                    Caption = 'Enabled';
                    ToolTip = 'Specifies whether address validation is turned on. When it is off, the Validate Address actions do not send any address to Google Maps.';
                    ApplicationArea = All;
                }
                field(provider; Rec.Provider)
                {
                    Caption = 'Provider';
                    ToolTip = 'Specifies the address validation service this extension uses. It is set by the extension and cannot be changed.';
                    ApplicationArea = All;
                    Editable = false;
                }
                field(blankCountryHandling; Rec."Blank Country Handling")
                {
                    Caption = 'Blank Country Handling';
                    ToolTip = 'Specifies what happens when a record has no Country/Region Code. Let Google decide: the country is worked out from the address, so a Danish address is found in Denmark and the country is filled in when you accept it; an address with a US state and ZIP code, or a Canadian postal code, is taken to be a US or Canadian address (and US ones get USPS delivery data); if Google can''t find it that way, it is asked again without a country. Use default country: every such record is checked as an address in the default country.';
                    ApplicationArea = All;
                }
                field(usCountryRegionCode; Rec."US Country/Region Code")
                {
                    Caption = 'Default Country/Region Code';
                    ToolTip = 'Specifies the country or region that is assumed for a record whose Country/Region Code is blank when Blank Country Handling is Use default country, for example US. The record''s Country/Region Code is filled in with the country Google found when its address is accepted or confirmed (this default is only used when Google names no country). It also decides which Country/Region record is filled in when several share one ISO code. Leave it blank when your records belong to several countries.';
                    ApplicationArea = All;

                    trigger OnValidate()
                    begin
                        WarnIfDefaultCountryNotUsable();
                    end;
                }
                field(timeoutSeconds; Rec."Timeout (Seconds)")
                {
                    Caption = 'Timeout (Seconds)';
                    ToolTip = 'Specifies how many seconds to wait for Google Maps to answer before the check fails.';
                    ApplicationArea = All;
                }
            }
            group(Credentials)
            {
                Caption = 'Google Maps';

                field(apiKey; ApiKeyText)
                {
                    Caption = 'API Key';
                    ToolTip = 'Specifies the API key from your Google Cloud project. It is stored securely, shown masked, and cannot be read back after you save it.';
                    ApplicationArea = All;
                    ExtendedDatatype = Masked;

                    trigger OnValidate()
                    begin
                        SaveApiKey();
                    end;
                }
                field(keyGuidance; KeyGuidance)
                {
                    Caption = 'API key guidance';
                    ToolTip = 'Specifies advice for creating and restricting the API key.';
                    ApplicationArea = All;
                    Editable = false;
                    ShowCaption = false;
                    MultiLine = true;
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(TestConnection)
            {
                Caption = 'Test Connection';
                ToolTip = 'Check the saved API key with Google Maps. No address is checked and no business data is sent.';
                ApplicationArea = All;
                Image = TestDatabase;

                trigger OnAction()
                var
                    SetupRegistration: Codeunit "obcfgav Setup Registration";
                    PrivacyNotice: Codeunit "Privacy Notice";
                    ErrorText: Text;
                begin
                    SetupRegistration.EnsurePrivacyNotice();
                    Commit();
                    if not PrivacyNotice.ConfirmPrivacyNoticeApproval(SetupRegistration.PrivacyNoticeId()) then
                        Error(ShowTextTok, PrivacyNoticeNotApprovedErr);
                    if AddressService.TestConnection(ErrorText) then
                        Message(ConnectionOkMsg)
                    else
                        Error(ShowTextTok, ErrorText);
                end;
            }
            action(SupportedCountries)
            {
                Caption = 'Supported Countries';
                ToolTip = 'See the countries and regions Google Maps can validate addresses in, and turn individual ones on or off.';
                ApplicationArea = All;
                Image = Map;
                RunObject = page "obcfgav Supported Countries";
            }
            action(AssistedSetup)
            {
                Caption = 'Assisted Setup';
                ToolTip = 'Open the guided setup that saves the Google Maps API key.';
                ApplicationArea = All;
                Image = Setup;
                RunObject = page "obcfgav Setup Wizard";
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                actionref(TestConnection_Promoted; TestConnection)
                {
                }
                actionref(SupportedCountries_Promoted; SupportedCountries)
                {
                }
            }
        }
    }

    trigger OnOpenPage()
    begin
        Rec.Reset();
        if not Rec.Get() then begin
            Rec.Init();
            Rec.Insert();
        end;
        KeyGuidance := KeyGuidanceTxt;
        RefreshCredentialState();
    end;

    trigger OnAfterGetRecord()
    begin
        RefreshCredentialState();
    end;

    [NonDebuggable]
    local procedure SaveApiKey()
    begin
        if ApiKeyText <> MaskedPlaceholderTok then
            CredentialMgt.SetApiKey(ApiKeyText);
        RefreshCredentialState();
    end;

    [NonDebuggable]
    local procedure WarnIfDefaultCountryNotUsable()
    var
        CountryMgt: Codeunit "obcfgav Country Mgt.";
        Region: Code[2];
        CountryName: Text;
        ErrorText: Text;
    begin
        if Rec."US Country/Region Code" = '' then
            exit;
        if not CountryMgt.RegionForCheck(Rec."US Country/Region Code", Region, CountryName) then begin
            Message(ShowTextTok, CountryMgt.NoIsoCodeText(CountryName));
            exit;
        end;
        if not CountryMgt.CheckRegion(Region, CountryName, ErrorText) then
            Message(ShowTextTok, ErrorText);
    end;

    local procedure RefreshCredentialState()
    begin
        if CredentialMgt.HasApiKey() then
            ApiKeyText := MaskedPlaceholderTok
        else
            ApiKeyText := '';
    end;

    var
        CredentialMgt: Codeunit "obcfgav Credential Mgt.";
        AddressService: Codeunit "obcfgav Address Service";
        [NonDebuggable]
        ApiKeyText: Text;
        KeyGuidance: Text;
        PrivacyNoticeNotApprovedErr: Label 'The privacy notice for sending addresses to Google Maps has not been agreed to, so the connection was not tested.';
        ConnectionOkMsg: Label 'The connection to Google Maps works. The API key was accepted.';
        KeyGuidanceTxt: Label 'Use an API key that is restricted to the Address Validation API, and set a daily quota and a budget alert in the Google Cloud console.';
        MaskedPlaceholderTok: Label '********', Locked = true;
        ShowTextTok: Label '%1', Comment = '%1 = text already composed for the user, shown unchanged', Locked = true;
}
