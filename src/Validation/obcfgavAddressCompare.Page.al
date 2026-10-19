namespace OnlyBCFans.GoogleAddress;

page 92803 "obcfgav Address Compare"
{
    PageType = StandardDialog;
    Caption = 'Suggested Address';
    DataCaptionExpression = RecordCaption;
    SourceTable = "obcfgav Address Buffer";
    ApplicationArea = All;
    Editable = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    DeleteAllowed = false;

    layout
    {
        area(Content)
        {
            group(Instructions)
            {
                ShowCaption = false;

                field(instruction; InstructionText)
                {
                    Caption = 'Instructions';
                    ToolTip = 'Specifies how to accept or ignore the suggested address.';
                    ApplicationArea = All;
                    ShowCaption = false;
                    MultiLine = true;
                }
            }
            grid(Compare)
            {
                GridLayout = Columns;

                group(CurrentBC)
                {
                    Caption = 'Current (BC)';

                    field(originalAddress; Rec."Original Address")
                    {
                        Caption = 'Address';
                        ToolTip = 'Specifies the street address currently on the record.';
                        ApplicationArea = All;
                    }
                    field(originalAddress2; Rec."Original Address 2")
                    {
                        Caption = 'Address 2';
                        ToolTip = 'Specifies the second address line currently on the record.';
                        ApplicationArea = All;
                    }
                    field(originalCity; Rec."Original City")
                    {
                        Caption = 'City';
                        ToolTip = 'Specifies the city currently on the record.';
                        ApplicationArea = All;
                    }
                    field(originalState; Rec."Original State")
                    {
                        Caption = 'State / Province';
                        ToolTip = 'Specifies the state currently on the record.';
                        ApplicationArea = All;
                    }
                    field(originalZipCode; Rec."Original ZIP Code")
                    {
                        Caption = 'ZIP / Postal Code';
                        ToolTip = 'Specifies the ZIP / Postal Code currently on the record.';
                        ApplicationArea = All;
                    }
                }
                group(Suggested)
                {
                    Caption = 'Suggested';

                    field(suggestedAddress; Rec."Suggested Address")
                    {
                        Caption = 'Suggested Address';
                        ToolTip = 'Specifies the street address suggested by the address validation service. It is shown in bold when it differs from the current address.';
                        ApplicationArea = All;
                        ShowCaption = false;
                        StyleExpr = AddressStyle;
                    }
                    field(suggestedAddress2; Rec."Suggested Address 2")
                    {
                        Caption = 'Suggested Address 2';
                        ToolTip = 'Specifies the second address line suggested by the address validation service. It is shown in bold when it differs from the current address.';
                        ApplicationArea = All;
                        ShowCaption = false;
                        StyleExpr = Address2Style;
                    }
                    field(suggestedCity; Rec."Suggested City")
                    {
                        Caption = 'Suggested City';
                        ToolTip = 'Specifies the city suggested by the address validation service. It is shown in bold when it differs from the current city.';
                        ApplicationArea = All;
                        ShowCaption = false;
                        StyleExpr = CityStyle;
                    }
                    field(suggestedState; Rec."Suggested State")
                    {
                        Caption = 'Suggested State / Province';
                        ToolTip = 'Specifies the state suggested by the address validation service. It is shown in bold when it differs from the current state.';
                        ApplicationArea = All;
                        ShowCaption = false;
                        StyleExpr = StateStyle;
                    }
                    field(suggestedZipCode; Rec."Suggested ZIP Code")
                    {
                        Caption = 'Suggested ZIP / Postal Code';
                        ToolTip = 'Specifies the ZIP / Postal Code suggested by the address validation service. It is shown in bold when it differs from the current ZIP / Postal Code.';
                        ApplicationArea = All;
                        ShowCaption = false;
                        StyleExpr = ZipStyle;
                    }
                }
            }
            group(AttributionGroup)
            {
                ShowCaption = false;

                field(attribution; AttributionText)
                {
                    Caption = 'Attribution';
                    ToolTip = 'Specifies which address validation service made the suggestion.';
                    ApplicationArea = All;
                    ShowCaption = false;
                }
                field(countryFill; CountryFillText)
                {
                    Caption = 'Country/Region';
                    ToolTip = 'Specifies the Country/Region Code that will be filled in on the record when you accept the suggestion. It is only shown when the record has no country yet.';
                    ApplicationArea = All;
                    ShowCaption = false;
                    Visible = CountryFillText <> '';
                }
            }
            group(Notes)
            {
                Caption = 'Delivery notes';

                field(deliveryWarning; DeliveryWarning)
                {
                    Caption = 'Delivery warning';
                    ToolTip = 'Specifies a delivery warning about this address.';
                    ApplicationArea = All;
                    ShowCaption = false;
                    Style = Attention;
                    StyleExpr = true;
                    Visible = DeliveryWarning <> '';
                }
                field(deliveryNotes; DeliveryNotes)
                {
                    Caption = 'Delivery notes';
                    ToolTip = 'Specifies additional information about this address.';
                    ApplicationArea = All;
                    ShowCaption = false;
                    MultiLine = true;
                }
                field(acceptBlockedReason; AcceptBlockedReason)
                {
                    Caption = 'Reason you can''t accept';
                    ToolTip = 'Specifies why the suggested address can''t be accepted.';
                    ApplicationArea = All;
                    ShowCaption = false;
                    Style = Unfavorable;
                    StyleExpr = true;
                    Visible = not CanAccept;
                }
            }
        }
    }

    procedure SetData(var TempAddressBuffer: Record "obcfgav Address Buffer" temporary; NewCanAccept: Boolean; NewAcceptBlockedReason: Text; ProviderName: Text)
    var
        StreetDiffers: Boolean;
    begin
        Rec.Copy(TempAddressBuffer, true);
        RecordCaption := TempAddressBuffer."Source Description";
        CanAccept := NewCanAccept;
        AcceptBlockedReason := NewAcceptBlockedReason;
        InstructionText := InstructionTxt;
        AttributionText := StrSubstNo(AttributionTxt, ProviderName);
        CountryFillText := FillCountryText(TempAddressBuffer);

        StreetDiffers := AddressValidation.ValuesDiffer(
            TempAddressBuffer."Original Address" + ' ' + TempAddressBuffer."Original Address 2",
            TempAddressBuffer."Suggested Address" + ' ' + TempAddressBuffer."Suggested Address 2");
        AddressStyle := GetStyle(StreetDiffers);
        Address2Style := GetStyle(StreetDiffers);
        CityStyle := GetStyle(AddressValidation.ValuesDiffer(TempAddressBuffer."Original City", TempAddressBuffer."Suggested City"));
        StateStyle := GetStyle(AddressValidation.ValuesDiffer(TempAddressBuffer."Original State", TempAddressBuffer."Suggested State"));
        ZipStyle := GetStyle(AddressValidation.ValuesDiffer(TempAddressBuffer."Original ZIP Code", TempAddressBuffer."Suggested ZIP Code"));

        DeliveryWarning := AddressValidation.DeliveryWarning(TempAddressBuffer);

        DeliveryNotes := '';
        if TempAddressBuffer."Has Replaced" then
            AddNote(ReplacedTxt);
        if TempAddressBuffer."Has Inferred" then
            AddNote(InferredTxt);
        if TempAddressBuffer."Has Spell Corrected" then
            AddNote(SpellCorrectedTxt);
        if TempAddressBuffer."Has Unconfirmed" then
            AddNote(UnconfirmedTxt);
        if TempAddressBuffer.Vacant then
            AddNote(VacantTxt);
        if TempAddressBuffer.Business then
            AddNote(BusinessTxt);
        if TempAddressBuffer."PO Box" then
            AddNote(PoBoxTxt);
        if (not TempAddressBuffer."Not Found") and (TempAddressBuffer."Provider Message" <> '') then
            AddNote(TempAddressBuffer."Provider Message");
    end;

    local procedure FillCountryText(var TempAddressBuffer: Record "obcfgav Address Buffer" temporary): Text
    var
        Region: Code[2];
        CountryCode: Code[10];
    begin
        if TempAddressBuffer."Country/Region Code" <> '' then
            exit('');
        Region := TempAddressBuffer."Result Region Code";
        if Region = '' then
            Region := TempAddressBuffer."Region Code";
        CountryCode := CountryMgt.BCCodeForRegion(Region);
        if (CountryCode = '') and (TempAddressBuffer."Region Code" <> '') then
            CountryCode := CountryMgt.BCCodeForRegion(TempAddressBuffer."Region Code");
        if CountryCode = '' then
            exit('');
        exit(StrSubstNo(CountryFillTxt, CountryMgt.DisplayName(CountryCode)));
    end;

    local procedure GetStyle(Differs: Boolean): Text
    begin
        if Differs then
            exit(Format(PageStyle::Strong));
        exit(Format(PageStyle::Standard));
    end;

    local procedure AddNote(Note: Text)
    var
        LineBreak: Text[1];
    begin
        if DeliveryNotes <> '' then begin
            LineBreak[1] := 10;
            DeliveryNotes += LineBreak;
        end;
        DeliveryNotes += Note;
    end;

    var
        AddressValidation: Codeunit "obcfgav Address Validation";
        CountryMgt: Codeunit "obcfgav Country Mgt.";
        CanAccept: Boolean;
        AcceptBlockedReason: Text;
        InstructionText: Text;
        AttributionText: Text;
        CountryFillText: Text;
        DeliveryNotes: Text;
        RecordCaption: Text;
        DeliveryWarning: Text;
        AddressStyle: Text;
        Address2Style: Text;
        CityStyle: Text;
        StateStyle: Text;
        ZipStyle: Text;
        InstructionTxt: Label 'Changed values are shown in bold. Choose OK to accept the suggested address, or Cancel to keep the current address.';
        CountryFillTxt: Label 'The Country/Region will be set to %1.', Comment = '%1 = name of the country or region that will be filled in';
        ReplacedTxt: Label 'Part of the address was replaced, for example the ZIP / Postal Code.';
        InferredTxt: Label 'Missing parts of the address were added.';
        SpellCorrectedTxt: Label 'The spelling of part of the address was corrected.';
        UnconfirmedTxt: Label 'Some parts of the address could not be confirmed.';
        VacantTxt: Label 'USPS data reports that this address is vacant.';
        BusinessTxt: Label 'This is a business address.';
        PoBoxTxt: Label 'This is a PO box.';
        AttributionTxt: Label 'Suggestion from %1', Comment = '%1 = address validation provider name, for example Google Maps';
}
