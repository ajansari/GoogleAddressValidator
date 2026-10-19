namespace OnlyBCFans.GoogleAddress;

page 92804 "obcfgav Supported Countries"
{
    PageType = List;
    Caption = 'Google Address Validation Supported Countries';
    AdditionalSearchTerms = 'Google Address Validation, Google Maps, supported countries, address validation countries, region codes';
    SourceTable = "obcfgav Supported Country";
    UsageCategory = Administration;
    ApplicationArea = All;
    InsertAllowed = false;
    DeleteAllowed = false;
    Editable = true;

    layout
    {
        area(Content)
        {
            repeater(Countries)
            {
                field(regionCode; Rec."Region Code")
                {
                    Caption = 'Region Code';
                    ToolTip = 'Specifies the two-letter country or region code that Google Maps uses (ISO 3166). It is matched with the ISO Code of the Country/Region on the record.';
                    ApplicationArea = All;
                    Editable = false;
                }
                field(name; Rec.Name)
                {
                    Caption = 'Name';
                    ToolTip = 'Specifies the name of the country or region.';
                    ApplicationArea = All;
                    Editable = false;
                }
                field(enabled; Rec.Enabled)
                {
                    Caption = 'Enabled';
                    ToolTip = 'Specifies whether addresses in this country or region can be validated. Turn it off to refuse validation for it.';
                    ApplicationArea = All;
                }
                field(preview; Rec.Preview)
                {
                    Caption = 'Preview';
                    ToolTip = 'Specifies that Google lists this country or region as a preview that has not yet reached general availability. Results can change.';
                    ApplicationArea = All;
                    Editable = false;
                }
                field(residentialData; Rec."Residential Data")
                {
                    Caption = 'Residential and Commercial Data';
                    ToolTip = 'Specifies whether Google tells apart residential and commercial addresses in this country or region.';
                    ApplicationArea = All;
                    Editable = false;
                }
                field(uspsDeliveryData; Rec."USPS Delivery Data")
                {
                    Caption = 'USPS Delivery Data';
                    ToolTip = 'Specifies that the result also carries United States Postal Service delivery data (standardized address and deliverability). Only the United States and Puerto Rico have it.';
                    ApplicationArea = All;
                    Editable = false;
                }
            }
        }
    }

    trigger OnOpenPage()
    var
        CountryMgt: Codeunit "obcfgav Country Mgt.";
    begin
        if Rec.IsEmpty() and Rec.WritePermission() then
            CountryMgt.SeedSupportedCountries();
        CurrPage.Editable(Rec.WritePermission());
    end;
}
