namespace OnlyBCFans.GoogleAddress;

page 92801 "obcfgav Setup Wizard"
{
    PageType = NavigatePage;
    Caption = 'Set Up Google Address Validation';
    ApplicationArea = All;
    SourceTable = "obcfgav Setup";
    SourceTableTemporary = true;

    layout
    {
        area(Content)
        {
            group(WelcomeStep)
            {
                Caption = 'Welcome';
                Visible = Step = 0;

                field(welcomeText; WelcomeText)
                {
                    Caption = 'Welcome';
                    ToolTip = 'Specifies what you enter in this wizard.';
                    ApplicationArea = All;
                    Editable = false;
                    MultiLine = true;
                    ShowCaption = false;
                }
                field(scopeText; ScopeText)
                {
                    Caption = 'Scope';
                    ToolTip = 'Specifies what you set up elsewhere.';
                    ApplicationArea = All;
                    Editable = false;
                    MultiLine = true;
                    ShowCaption = false;
                }
            }
            group(CredentialsStep)
            {
                Caption = 'Google Maps API Key';
                Visible = Step = 1;

                field(apiKey; ApiKeyText)
                {
                    Caption = 'API Key';
                    ToolTip = 'Specifies the API key from your Google Cloud project. Billing and the Address Validation API must be enabled for that project.';
                    ApplicationArea = All;
                    ExtendedDatatype = Masked;

                    trigger OnValidate()
                    begin
                        UpdateControls();
                    end;
                }
            }
            group(CountryStep)
            {
                Caption = 'Countries';
                Visible = Step = 2;

                field(countryText; CountryText)
                {
                    Caption = 'Countries';
                    ToolTip = 'Specifies what you choose on this page.';
                    ApplicationArea = All;
                    Editable = false;
                    MultiLine = true;
                    ShowCaption = false;
                }
                field(defaultCountry; Rec."US Country/Region Code")
                {
                    Caption = 'Default Country/Region Code';
                    ToolTip = 'Specifies the country or region that is assumed for a record whose Country/Region Code is blank when Blank Country Handling is Use default country, for example US. Leave it blank when your records belong to several countries.';
                    ApplicationArea = All;

                    trigger OnValidate()
                    begin
                        WarnIfDefaultCountryNotUsable();
                    end;
                }
                field(blankCountryHandling; Rec."Blank Country Handling")
                {
                    Caption = 'Blank Country Handling';
                    ToolTip = 'Specifies what happens when a record has no Country/Region Code. Let Google decide: the country is worked out from the address. Use default country: every such record is checked as an address in the default country.';
                    ApplicationArea = All;
                }
            }
            group(FinishStep)
            {
                Caption = 'That''s it!';
                Visible = Step = 3;

                field(finishText; FinishText)
                {
                    Caption = 'Finish';
                    ToolTip = 'Specifies the last step of this wizard.';
                    ApplicationArea = All;
                    Editable = false;
                    MultiLine = true;
                    ShowCaption = false;
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(ActionBack)
            {
                Caption = 'Back';
                ToolTip = 'Go to the previous step.';
                ApplicationArea = All;
                Enabled = BackEnabled;
                Image = PreviousRecord;
                InFooterBar = true;

                trigger OnAction()
                begin
                    Step -= 1;
                    UpdateControls();
                end;
            }
            action(ActionNext)
            {
                Caption = 'Next';
                ToolTip = 'Go to the next step.';
                ApplicationArea = All;
                Enabled = NextEnabled;
                Image = NextRecord;
                InFooterBar = true;

                trigger OnAction()
                begin
                    Step += 1;
                    UpdateControls();
                end;
            }
            action(ActionFinish)
            {
                Caption = 'Finish';
                ToolTip = 'Save the API key and the country choices and close the wizard.';
                ApplicationArea = All;
                Enabled = FinishEnabled;
                Image = Approve;
                InFooterBar = true;

                trigger OnAction()
                begin
                    FinishWizard();
                    CurrPage.Close();
                end;
            }
        }
    }

    trigger OnOpenPage()
    var
        Setup: Record "obcfgav Setup";
    begin
        WelcomeText := WizardWelcomeTxt;
        ScopeText := WizardScopeTxt;
        CountryText := WizardCountryTxt;
        FinishText := WizardFinishTxt;
        if Setup.Get() then
            Rec := Setup
        else
            Rec.Init();
        Rec.Insert();
        if CredentialMgt.HasApiKey() then
            ApiKeyText := MaskedPlaceholderTok;
        Step := 0;
        UpdateControls();
    end;

    local procedure UpdateControls()
    begin
        BackEnabled := Step > 0;
        NextEnabled := (Step in [0, 2]) or ((Step = 1) and (ApiKeyText <> ''));
        FinishEnabled := Step = 3;
    end;

    [NonDebuggable]
    local procedure FinishWizard()
    var
        Setup: Record "obcfgav Setup";
    begin
        if ApiKeyText <> MaskedPlaceholderTok then
            CredentialMgt.SetApiKey(ApiKeyText);
        if not Setup.Get() then begin
            Setup.Init();
            Setup.Insert();
        end;
        Setup."US Country/Region Code" := Rec."US Country/Region Code";
        Setup."Blank Country Handling" := Rec."Blank Country Handling";
        Setup.Modify();
    end;

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

    var
        CredentialMgt: Codeunit "obcfgav Credential Mgt.";
        [NonDebuggable]
        ApiKeyText: Text;
        WelcomeText: Text;
        ScopeText: Text;
        CountryText: Text;
        FinishText: Text;
        Step: Integer;
        BackEnabled: Boolean;
        NextEnabled: Boolean;
        FinishEnabled: Boolean;
        WizardWelcomeTxt: Label 'Enter the API key from your Google Cloud project. Billing and the Address Validation API must be enabled for that project. The key is stored securely for this company and isn''t shown again after you save it. One key works for every country Google supports.';
        WizardScopeTxt: Label 'You turn the service on, test the connection and turn countries on or off on the Google Address Validation Setup page. After installation all supported countries are on, which means addresses in those countries, including those of employees and contacts, can be sent to Google when a user validates. Turn off the countries you don''t want.';
        WizardCountryTxt: Label 'Choose the Default Country/Region Code and what happens when a record has no country. Leave the default country blank if your records belong to several countries. You can change both later on the Google Address Validation Setup page, where you can also turn individual countries on or off.';
        WizardFinishTxt: Label 'Choose Finish to save the API key and the country choices.';
        MaskedPlaceholderTok: Label '********', Locked = true;
        ShowTextTok: Label '%1', Comment = '%1 = text already composed for the user, shown unchanged', Locked = true;
}
