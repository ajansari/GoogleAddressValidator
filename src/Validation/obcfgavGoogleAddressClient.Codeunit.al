namespace OnlyBCFans.GoogleAddress;

codeunit 92807 "obcfgav Google Address Client" implements "obcfgav Address Provider"
{
    Access = Internal;

    procedure ValidateAddress(var TempAddressBuffer: Record "obcfgav Address Buffer" temporary; Transport: Interface "obcfgav Http Transport"; TimeoutMs: Integer): Boolean
    var
        Request: HttpRequestMessage;
        HttpStatus: Integer;
        ResponseBody: Text;
    begin
        BuildRequest(BuildValidateBody(TempAddressBuffer), Request);
        if not Transport.Send(Request, TimeoutMs, HttpStatus, ResponseBody) then begin
            SetFailure(TempAddressBuffer, 0, NotRespondingErr, '');
            exit(false);
        end;
        exit(HandleResponse(HttpStatus, ResponseBody, TempAddressBuffer));
    end;

    procedure TestConnection(Transport: Interface "obcfgav Http Transport"; TimeoutMs: Integer; var ErrorText: Text): Boolean
    var
        Request: HttpRequestMessage;
        HttpStatus: Integer;
        ResponseBody: Text;
        ErrorMessage: Text;
        Reason: Text;
    begin
        ErrorText := '';
        BuildRequest(BuildProbeBody(), Request);
        if not Transport.Send(Request, TimeoutMs, HttpStatus, ResponseBody) then begin
            ErrorText := StrSubstNo(TestConnectionFailedNoMessageErr, NotRespondingErr);
            exit(false);
        end;
        if HttpStatus = 200 then
            exit(true);
        ReadError(ResponseBody, ErrorMessage, Reason);
        if (HttpStatus = 400) and (Reason <> ApiKeyInvalidTok) then
            exit(true);
        if ErrorMessage = '' then
            ErrorText := StrSubstNo(TestConnectionFailedNoMessageErr, MapError(HttpStatus, Reason, ErrorMessage))
        else
            ErrorText := StrSubstNo(TestConnectionFailedErr, MapError(HttpStatus, Reason, ErrorMessage), ErrorMessage);
        exit(false);
    end;

    procedure HasCredentials(): Boolean
    begin
        exit(CredentialMgt.HasApiKey());
    end;

    procedure DisplayName(): Text
    begin
        exit(GoogleMapsTok);
    end;

    [NonDebuggable]
    local procedure BuildRequest(BodyText: Text; var Request: HttpRequestMessage)
    var
        Headers: HttpHeaders;
        Content: HttpContent;
        ContentHeaders: HttpHeaders;
    begin
        Request.Method(PostTok);
        Request.SetRequestUri(EndpointTok);
        Request.GetHeaders(Headers);
        Headers.Add(ApiKeyHeaderTok, CredentialMgt.GetApiKey());
        Content.WriteFrom(BodyText);
        Content.GetHeaders(ContentHeaders);
        if ContentHeaders.Contains(ContentTypeTok) then
            ContentHeaders.Remove(ContentTypeTok);
        ContentHeaders.Add(ContentTypeTok, JsonMediaTypeTok);
        Request.Content(Content);
    end;

    local procedure BuildValidateBody(var TempAddressBuffer: Record "obcfgav Address Buffer" temporary): Text
    var
        JBody: JsonObject;
        JAddress: JsonObject;
        JLines: JsonArray;
        BodyText: Text;
        Line: Text;
        Value: Text;
    begin
        Line := DelChr(TempAddressBuffer."Original Address", '<>', ' ');
        if Line <> '' then
            JLines.Add(Line);
        Line := DelChr(TempAddressBuffer."Original Address 2", '<>', ' ');
        if Line <> '' then
            JLines.Add(Line);

        if TempAddressBuffer."Region Code" <> '' then
            JAddress.Add(RegionCodeTok, TempAddressBuffer."Region Code");
        JAddress.Add(AddressLinesTok, JLines);
        Value := DelChr(TempAddressBuffer."Original City", '<>', ' ');
        if Value <> '' then
            JAddress.Add(LocalityTok, Value);
        Value := UpperCase(DelChr(TempAddressBuffer."Original State", '<>', ' '));
        if Value <> '' then
            JAddress.Add(AdministrativeAreaTok, Value);
        Value := DelChr(TempAddressBuffer."Original ZIP Code", '<>', ' ');
        if Value <> '' then
            JAddress.Add(PostalCodeTok, Value);

        JBody.Add(AddressTok, JAddress);
        if CountryMgt.IsUnitedStatesLike(TempAddressBuffer."Region Code") then
            JBody.Add(EnableUspsCassTok, true);
        JBody.WriteTo(BodyText);
        exit(BodyText);
    end;

    local procedure BuildProbeBody(): Text
    var
        JBody: JsonObject;
        JAddress: JsonObject;
        JLines: JsonArray;
        BodyText: Text;
    begin
        JAddress.Add(RegionCodeTok, RegionUSTok);
        JAddress.Add(AddressLinesTok, JLines);
        JBody.Add(AddressTok, JAddress);
        JBody.WriteTo(BodyText);
        exit(BodyText);
    end;

    local procedure HandleResponse(HttpStatus: Integer; ResponseBody: Text; var TempAddressBuffer: Record "obcfgav Address Buffer" temporary): Boolean
    var
        ErrorMessage: Text;
        Reason: Text;
    begin
        if HttpStatus = 200 then
            exit(HandleSuccess(ResponseBody, TempAddressBuffer));

        ReadError(ResponseBody, ErrorMessage, Reason);
        SetFailure(TempAddressBuffer, HttpStatus, MapError(HttpStatus, Reason, ErrorMessage), ErrorMessage);
        exit(false);
    end;

    local procedure MapError(HttpStatus: Integer; Reason: Text; ErrorMessage: Text): Text
    begin
        case HttpStatus of
            400:
                begin
                    if Reason = ApiKeyInvalidTok then
                        exit(ApiKeyRejectedErr);
                    exit(StrSubstNo(CouldNotReadErr, ErrorMessage));
                end;
            401:
                exit(ApiKeyRejectedErr);
            403:
                begin
                    if Reason = ServiceDisabledTok then
                        exit(ApiDisabledErr);
                    if Reason = BillingDisabledTok then
                        exit(BillingDisabledErr);
                    if StartsWith(Reason, ApiKeyPrefixTok) and EndsWith(Reason, BlockedSuffixTok) then
                        exit(ApiKeyRestrictedErr);
                    exit(StrSubstNo(AccessDeniedErr, ErrorMessage));
                end;
            429:
                exit(QuotaErr);
            500 .. 599:
                exit(NotRespondingErr);
        end;
        exit(UnexpectedResponseErr);
    end;

    local procedure HandleSuccess(ResponseBody: Text; var TempAddressBuffer: Record "obcfgav Address Buffer" temporary): Boolean
    var
        JRoot: JsonObject;
        JResult: JsonObject;
        JVerdict: JsonObject;
        JAddress: JsonObject;
        JUsps: JsonObject;
        JMetadata: JsonObject;
        UspsMessage: Text;
        Reason: Text;
        Granularity: Text;
    begin
        if not JRoot.ReadFrom(ResponseBody) then begin
            SetFailure(TempAddressBuffer, 200, UnexpectedResponseErr, '');
            exit(false);
        end;
        if not GetObject(JRoot, ResultTok, JResult) then begin
            SetFailure(TempAddressBuffer, 200, UnexpectedResponseErr, '');
            exit(false);
        end;
        if not GetObject(JResult, VerdictTok, JVerdict) then begin
            SetFailure(TempAddressBuffer, 200, UnexpectedResponseErr, '');
            exit(false);
        end;

        TempAddressBuffer."HTTP Status" := 200;
        ReadVerdict(JVerdict, TempAddressBuffer);

        if GetObject(JResult, AddressTok, JAddress) then begin
            ReadAddress(JAddress, TempAddressBuffer);
            ReadResultRegion(JAddress, TempAddressBuffer);
        end;
        if GetObject(JResult, UspsDataTok, JUsps) then
            UspsMessage := ReadUspsData(JUsps, TempAddressBuffer);
        if GetObject(JResult, MetadataTok, JMetadata) then begin
            TempAddressBuffer.Business := GetBoolean(JMetadata, BusinessTok);
            TempAddressBuffer."PO Box" := GetBoolean(JMetadata, PoBoxTok);
        end;
        if (TempAddressBuffer."Region Code" <> '') and (TempAddressBuffer."Result Region Code" <> '') and
           (TempAddressBuffer."Result Region Code" <> TempAddressBuffer."Region Code") and
           not (CountryMgt.IsUnitedStatesLike(TempAddressBuffer."Region Code") and CountryMgt.IsUnitedStatesLike(TempAddressBuffer."Result Region Code"))
        then begin
            SetFailure(
                TempAddressBuffer, 200,
                StrSubstNo(RegionMismatchErr, CountryMgt.DisplayNameForRegion(TempAddressBuffer."Result Region Code"), CountryMgt.DisplayNameForRegion(TempAddressBuffer."Region Code")),
                StrSubstNo(ProviderMessageTxt, TempAddressBuffer."Validation Granularity", TempAddressBuffer."Next Action", TempAddressBuffer."Missing Components"));
            TempAddressBuffer."Not Found" := true;
            exit(false);
        end;
        ReadSuggestedAddress(JAddress, JUsps, TempAddressBuffer);

        Granularity := TempAddressBuffer."Validation Granularity";
        if (Granularity = PremiseTok) or (Granularity = SubPremiseTok) then begin
            if SuggestionComplete(TempAddressBuffer) then begin
                TempAddressBuffer."Provider Message" := CopyStr(UspsMessage, 1, MaxStrLen(TempAddressBuffer."Provider Message"));
                exit(true);
            end;
            SetFailure(TempAddressBuffer, 200, UnexpectedResponseErr, UspsMessage);
            exit(false);
        end;

        if TempAddressBuffer."Missing Components" <> '' then
            Reason := StrSubstNo(MissingPartsTxt, FriendlyComponents(TempAddressBuffer."Missing Components"))
        else
            Reason := CheckAgainTxt;
        SetFailure(
            TempAddressBuffer, 200, DelChr(StrSubstNo(NotValidatedMsg, Reason), '>', ' '),
            StrSubstNo(ProviderMessageTxt, Granularity, TempAddressBuffer."Next Action", TempAddressBuffer."Missing Components") + AppendMessage(UspsMessage));
        TempAddressBuffer."Not Found" := true;
        exit(false);
    end;

    local procedure FriendlyComponents(Components: Text): Text
    var
        Parts: List of [Text];
        Friendly: List of [Text];
        Part: Text;
        Name: Text;
        Result: Text;
        Index: Integer;
    begin
        Parts := Components.Split(SeparatorTok);
        foreach Part in Parts do begin
            Name := FriendlyComponent(DelChr(Part, '<>', ' '));
            if (Name <> '') and not Friendly.Contains(Name) then
                Friendly.Add(Name);
        end;

        for Index := 1 to Friendly.Count() do
            case true of
                Index = 1:
                    Result := Friendly.Get(Index);
                Index = Friendly.Count():
                    Result += AndTxt + Friendly.Get(Index);
                else
                    Result += SeparatorTok + Friendly.Get(Index);
            end;
        exit(Result);
    end;

    local procedure FriendlyComponent(ComponentType: Text): Text
    begin
        case ComponentType of
            'street_number':
                exit(StreetNumberTxt);
            'route':
                exit(StreetNameTxt);
            'subpremise':
                exit(SuiteTxt);
            'premise':
                exit(BuildingTxt);
            'locality':
                exit(CityNameTxt);
            'sublocality', 'sublocality_level_1', 'neighborhood':
                exit(NeighborhoodTxt);
            'administrative_area_level_1':
                exit(StateNameTxt);
            'administrative_area_level_2':
                exit(CountyNameTxt);
            'postal_code':
                exit(ZipNameTxt);
            'postal_code_suffix':
                exit(ZipPlusFourTxt);
            'country':
                exit(CountryNameTxt);
            'floor':
                exit(FloorTxt);
            'post_box':
                exit(PoBoxNameTxt);
        end;
        exit(ComponentType.Replace('_', ' '));
    end;

    local procedure SecondAddressLine(JPostal: JsonObject): Text
    var
        JToken: JsonToken;
        JLines: JsonArray;
        Index: Integer;
        Result: Text;
        Line: Text;
    begin
        if JPostal.Get(AddressLinesTok, JToken) then
            if JToken.IsArray() then begin
                JLines := JToken.AsArray();
                for Index := 1 to JLines.Count() - 1 do begin
                    Line := GetLine(JPostal, Index);
                    if Line <> '' then begin
                        if Result <> '' then
                            Result += ' ';
                        Result += Line;
                    end;
                end;
            end;
        if Result = '' then
            Result := GetText(JPostal, SublocalityTok);
        exit(Result);
    end;

    local procedure ReadResultRegion(JAddress: JsonObject; var TempAddressBuffer: Record "obcfgav Address Buffer" temporary)
    var
        JPostal: JsonObject;
    begin
        if not GetObject(JAddress, PostalAddressTok, JPostal) then
            exit;
        TempAddressBuffer."Result Region Code" := CopyStr(UpperCase(GetText(JPostal, RegionCodeTok)), 1, MaxStrLen(TempAddressBuffer."Result Region Code"));
    end;

    local procedure ResultRegion(var TempAddressBuffer: Record "obcfgav Address Buffer" temporary): Code[2]
    begin
        if TempAddressBuffer."Result Region Code" <> '' then
            exit(TempAddressBuffer."Result Region Code");
        exit(TempAddressBuffer."Region Code");
    end;

    local procedure SuggestionComplete(var TempAddressBuffer: Record "obcfgav Address Buffer" temporary): Boolean
    var
        Region: Code[2];
    begin
        Region := ResultRegion(TempAddressBuffer);
        if TempAddressBuffer."Suggested Address" = '' then
            exit(false);
        if (Region = '') or CountryMgt.NeedsStateAndPostalCode(Region) then
            exit((TempAddressBuffer."Suggested City" <> '') and (TempAddressBuffer."Suggested State" <> '') and (TempAddressBuffer."Suggested ZIP Code" <> ''));
        if (TempAddressBuffer."Suggested State" = '') and (TempAddressBuffer."Original State" <> '') then
            TempAddressBuffer."Suggested State" := TempAddressBuffer."Original State";
        if (TempAddressBuffer."Suggested City" = '') and (TempAddressBuffer."Original City" <> '') then
            TempAddressBuffer."Suggested City" := TempAddressBuffer."Original City";
        if (TempAddressBuffer."Suggested ZIP Code" = '') and (TempAddressBuffer."Original ZIP Code" <> '') then
            TempAddressBuffer."Suggested ZIP Code" := TempAddressBuffer."Original ZIP Code";
        exit((TempAddressBuffer."Suggested City" <> '') or (TempAddressBuffer."Suggested ZIP Code" <> ''));
    end;

    local procedure ReadVerdict(JVerdict: JsonObject; var TempAddressBuffer: Record "obcfgav Address Buffer" temporary)
    begin
        TempAddressBuffer."Validation Granularity" := CopyStr(GetText(JVerdict, ValidationGranularityTok), 1, MaxStrLen(TempAddressBuffer."Validation Granularity"));
        TempAddressBuffer."Next Action" := CopyStr(GetText(JVerdict, PossibleNextActionTok), 1, MaxStrLen(TempAddressBuffer."Next Action"));
        TempAddressBuffer."Address Complete" := GetBoolean(JVerdict, AddressCompleteTok);
        TempAddressBuffer."Has Replaced" := GetBoolean(JVerdict, HasReplacedTok);
        TempAddressBuffer."Has Inferred" := GetBoolean(JVerdict, HasInferredTok);
        TempAddressBuffer."Has Spell Corrected" := GetBoolean(JVerdict, HasSpellCorrectedTok);
        TempAddressBuffer."Has Unconfirmed" := GetBoolean(JVerdict, HasUnconfirmedTok);
    end;

    local procedure ReadAddress(JAddress: JsonObject; var TempAddressBuffer: Record "obcfgav Address Buffer" temporary)
    var
        Missing: Text;
    begin
        AppendComponentTypes(JAddress, MissingComponentTypesTok, Missing);
        AppendComponentTypes(JAddress, UnconfirmedComponentTypesTok, Missing);
        TempAddressBuffer."Missing Components" := CopyStr(Missing, 1, MaxStrLen(TempAddressBuffer."Missing Components"));
    end;

    local procedure AppendComponentTypes(JAddress: JsonObject; ArrayName: Text; var Components: Text)
    var
        JToken: JsonToken;
        JItem: JsonToken;
        ItemText: Text;
    begin
        if not JAddress.Get(ArrayName, JToken) then
            exit;
        if not JToken.IsArray() then
            exit;
        foreach JItem in JToken.AsArray() do
            if JItem.IsValue() then
                if not JItem.AsValue().IsNull() then begin
                    ItemText := JItem.AsValue().AsText();
                    if ItemText <> '' then begin
                        if Components <> '' then
                            Components += SeparatorTok;
                        Components += ItemText;
                    end;
                end;
    end;

    local procedure ReadUspsData(JUsps: JsonObject; var TempAddressBuffer: Record "obcfgav Address Buffer" temporary): Text
    begin
        TempAddressBuffer."DPV Confirmation" := CopyStr(GetText(JUsps, DpvConfirmationTok), 1, MaxStrLen(TempAddressBuffer."DPV Confirmation"));
        TempAddressBuffer.Vacant := UpperCase(GetText(JUsps, DpvVacantTok)) = YesTok;
        exit(GetText(JUsps, ErrorMessageTok));
    end;

    local procedure ReadSuggestedAddress(JAddress: JsonObject; JUsps: JsonObject; var TempAddressBuffer: Record "obcfgav Address Buffer" temporary)
    var
        JStandardized: JsonObject;
        JPostal: JsonObject;
        ZipCode: Text;
        ZipExtension: Text;
    begin
        // Source A: USPS-standardized address, when Google returned one
        if GetObject(JUsps, StandardizedAddressTok, JStandardized) then
            if GetText(JStandardized, FirstAddressLineTok) <> '' then begin
                SetSuggested(
                    TempAddressBuffer,
                    GetText(JStandardized, FirstAddressLineTok), GetText(JStandardized, SecondAddressLineTok),
                    GetText(JStandardized, CityTok), GetText(JStandardized, StateTok), '');
                ZipCode := GetText(JStandardized, ZipCodeTok);
                ZipExtension := GetText(JStandardized, ZipCodeExtensionTok);
                if (ZipCode <> '') and (ZipExtension <> '') then
                    ZipCode += DashTok + ZipExtension;
                TempAddressBuffer."Suggested ZIP Code" := CopyStr(ZipCode, 1, MaxStrLen(TempAddressBuffer."Suggested ZIP Code"));
                exit;
            end;

        // Source B: Google's postal address
        if not GetObject(JAddress, PostalAddressTok, JPostal) then
            exit;
        SetSuggested(
            TempAddressBuffer, GetLine(JPostal, 0), SecondAddressLine(JPostal),
            GetText(JPostal, LocalityTok), GetText(JPostal, AdministrativeAreaTok), '');
        ZipCode := GetText(JPostal, PostalCodeTok);
        if ((ResultRegion(TempAddressBuffer) = '') or CountryMgt.IsUnitedStatesLike(ResultRegion(TempAddressBuffer))) and
           (StrLen(ZipCode) = 9) and (DelChr(ZipCode, '=', '0123456789') = '')
        then
            ZipCode := CopyStr(ZipCode, 1, 5) + DashTok + CopyStr(ZipCode, 6, 4);
        TempAddressBuffer."Suggested ZIP Code" := CopyStr(ZipCode, 1, MaxStrLen(TempAddressBuffer."Suggested ZIP Code"));
    end;

    local procedure SetSuggested(var TempAddressBuffer: Record "obcfgav Address Buffer" temporary; Address: Text; Address2: Text; City: Text; State: Text; ZipCode: Text)
    begin
        TempAddressBuffer."Suggested Address" := CopyStr(Address, 1, MaxStrLen(TempAddressBuffer."Suggested Address"));
        TempAddressBuffer."Suggested Address 2" := CopyStr(Address2, 1, MaxStrLen(TempAddressBuffer."Suggested Address 2"));
        TempAddressBuffer."Suggested City" := CopyStr(City, 1, MaxStrLen(TempAddressBuffer."Suggested City"));
        TempAddressBuffer."Suggested State" := CopyStr(State, 1, MaxStrLen(TempAddressBuffer."Suggested State"));
        TempAddressBuffer."Suggested ZIP Code" := CopyStr(ZipCode, 1, MaxStrLen(TempAddressBuffer."Suggested ZIP Code"));
    end;

    local procedure GetLine(JPostal: JsonObject; Index: Integer): Text
    var
        JToken: JsonToken;
        JLine: JsonToken;
    begin
        if not JPostal.Get(AddressLinesTok, JToken) then
            exit('');
        if not JToken.IsArray() then
            exit('');
        if not JToken.AsArray().Get(Index, JLine) then
            exit('');
        if not JLine.IsValue() then
            exit('');
        if JLine.AsValue().IsNull() then
            exit('');
        exit(JLine.AsValue().AsText());
    end;

    local procedure ReadError(ResponseBody: Text; var ErrorMessage: Text; var Reason: Text)
    var
        JRoot: JsonObject;
        JError: JsonObject;
        JToken: JsonToken;
        JDetail: JsonToken;
        TypeText: Text;
    begin
        ErrorMessage := '';
        Reason := '';
        if not JRoot.ReadFrom(ResponseBody) then
            exit;
        if not GetObject(JRoot, ErrorTok, JError) then
            exit;
        ErrorMessage := GetText(JError, MessageTok);
        if not JError.Get(DetailsTok, JToken) then
            exit;
        if not JToken.IsArray() then
            exit;
        foreach JDetail in JToken.AsArray() do
            if JDetail.IsObject() then begin
                TypeText := GetText(JDetail.AsObject(), TypeKeyTok);
                if EndsWith(TypeText, ErrorInfoSuffixTok) then begin
                    Reason := GetText(JDetail.AsObject(), ReasonTok);
                    exit;
                end;
            end;
    end;

    local procedure StartsWith(Value: Text; Prefix: Text): Boolean
    begin
        exit(CopyStr(Value, 1, StrLen(Prefix)) = Prefix);
    end;

    local procedure EndsWith(Value: Text; Suffix: Text): Boolean
    begin
        if StrLen(Value) < StrLen(Suffix) then
            exit(false);
        exit(CopyStr(Value, StrLen(Value) - StrLen(Suffix) + 1) = Suffix);
    end;

    local procedure AppendMessage(MessageText: Text): Text
    begin
        if MessageText = '' then
            exit('');
        exit(MessageSeparatorTok + MessageText);
    end;

    local procedure GetObject(JObject: JsonObject; PropertyName: Text; var Result: JsonObject): Boolean
    var
        JToken: JsonToken;
    begin
        Clear(Result);
        if not JObject.Get(PropertyName, JToken) then
            exit(false);
        if not JToken.IsObject() then
            exit(false);
        Result := JToken.AsObject();
        exit(true);
    end;

    local procedure GetText(JObject: JsonObject; PropertyName: Text): Text
    var
        JToken: JsonToken;
        JValue: JsonValue;
    begin
        if not JObject.Get(PropertyName, JToken) then
            exit('');
        if not JToken.IsValue() then
            exit('');
        JValue := JToken.AsValue();
        if JValue.IsNull() then
            exit('');
        exit(JValue.AsText());
    end;

    local procedure GetBoolean(JObject: JsonObject; PropertyName: Text): Boolean
    begin
        exit(UpperCase(GetText(JObject, PropertyName)) = TrueTok);
    end;

    local procedure SetFailure(var TempAddressBuffer: Record "obcfgav Address Buffer" temporary; HttpStatus: Integer; UserMessage: Text; ProviderMessage: Text)
    begin
        TempAddressBuffer."HTTP Status" := HttpStatus;
        TempAddressBuffer."Not Found" := false;
        TempAddressBuffer."User Message" := CopyStr(UserMessage, 1, MaxStrLen(TempAddressBuffer."User Message"));
        TempAddressBuffer."Provider Message" := CopyStr(ProviderMessage, 1, MaxStrLen(TempAddressBuffer."Provider Message"));
    end;

    var
        CountryMgt: Codeunit "obcfgav Country Mgt.";
        CredentialMgt: Codeunit "obcfgav Credential Mgt.";
        NotValidatedMsg: Label 'Google Maps couldn''t confirm this address. %1', Comment = '%1 = reason, for example the missing parts of the address (can be blank)';
        RegionMismatchErr: Label 'Google Maps found this address in %1, but the record says %2. Check the country and try again.', Comment = '%1 = country Google found, %2 = country on the record';
        MissingPartsTxt: Label 'Please check the %1, then try again.', Comment = '%1 = list of address parts that could not be confirmed, for example street number and ZIP Code';
        CheckAgainTxt: Label 'Please check it and try again.';
        AndTxt: Label ' and ';
        StreetNumberTxt: Label 'street number';
        StreetNameTxt: Label 'street name';
        SuiteTxt: Label 'apartment or suite number';
        BuildingTxt: Label 'building';
        CityNameTxt: Label 'city';
        NeighborhoodTxt: Label 'neighborhood';
        StateNameTxt: Label 'state or province';
        CountyNameTxt: Label 'county';
        ZipNameTxt: Label 'ZIP / postal code';
        ZipPlusFourTxt: Label 'ZIP+4 extension';
        CountryNameTxt: Label 'country';
        FloorTxt: Label 'floor';
        PoBoxNameTxt: Label 'PO box';
        ApiKeyRejectedErr: Label 'Google Maps rejected the API key. Contact your administrator.';
        ApiDisabledErr: Label 'The Address Validation API is not enabled in the Google Cloud project of this API key. Contact your administrator.';
        BillingDisabledErr: Label 'Billing is not enabled for the Google Cloud project of this API key. Contact your administrator.';
        ApiKeyRestrictedErr: Label 'The API key is not allowed to call the Address Validation API. Check the key''s restrictions. Contact your administrator.';
        AccessDeniedErr: Label 'Google Maps refused the request: %1', Comment = '%1 = message returned by Google';
        CouldNotReadErr: Label 'Google Maps could not read the address: %1', Comment = '%1 = message returned by Google';
        QuotaErr: Label 'The Google Maps request limit has been reached. Try again later.';
        NotRespondingErr: Label 'Google Maps is not responding. Try again later.';
        UnexpectedResponseErr: Label 'Unexpected response from Google Maps. Contact your administrator.';
        TestConnectionFailedNoMessageErr: Label 'The connection to Google Maps failed. %1', Comment = '%1 = reason shown to the user';
        TestConnectionFailedErr: Label 'The connection to Google Maps failed. %1 Google message: %2', Comment = '%1 = reason shown to the user, %2 = message returned by Google (can be blank)';
        ProviderMessageTxt: Label 'validationGranularity=%1; possibleNextAction=%2; missing=%3', Comment = '%1 = validation granularity, %2 = next action, %3 = missing components (can be blank)', Locked = true;
        GoogleMapsTok: Label 'Google Maps', Locked = true;
        EndpointTok: Label 'https://addressvalidation.googleapis.com/v1:validateAddress', Locked = true;
        ApiKeyHeaderTok: Label 'X-Goog-Api-Key', Locked = true;
        ContentTypeTok: Label 'Content-Type', Locked = true;
        JsonMediaTypeTok: Label 'application/json', Locked = true;
        PostTok: Label 'POST', Locked = true;
        AddressTok: Label 'address', Locked = true;
        RegionCodeTok: Label 'regionCode', Locked = true;
        SublocalityTok: Label 'sublocality', Locked = true;
        RegionUSTok: Label 'US', Locked = true;
        AddressLinesTok: Label 'addressLines', Locked = true;
        LocalityTok: Label 'locality', Locked = true;
        AdministrativeAreaTok: Label 'administrativeArea', Locked = true;
        PostalCodeTok: Label 'postalCode', Locked = true;
        EnableUspsCassTok: Label 'enableUspsCass', Locked = true;
        ResultTok: Label 'result', Locked = true;
        VerdictTok: Label 'verdict', Locked = true;
        ValidationGranularityTok: Label 'validationGranularity', Locked = true;
        PossibleNextActionTok: Label 'possibleNextAction', Locked = true;
        AddressCompleteTok: Label 'addressComplete', Locked = true;
        HasReplacedTok: Label 'hasReplacedComponents', Locked = true;
        HasInferredTok: Label 'hasInferredComponents', Locked = true;
        HasSpellCorrectedTok: Label 'hasSpellCorrectedComponents', Locked = true;
        HasUnconfirmedTok: Label 'hasUnconfirmedComponents', Locked = true;
        MissingComponentTypesTok: Label 'missingComponentTypes', Locked = true;
        UnconfirmedComponentTypesTok: Label 'unconfirmedComponentTypes', Locked = true;
        PostalAddressTok: Label 'postalAddress', Locked = true;
        UspsDataTok: Label 'uspsData', Locked = true;
        StandardizedAddressTok: Label 'standardizedAddress', Locked = true;
        FirstAddressLineTok: Label 'firstAddressLine', Locked = true;
        SecondAddressLineTok: Label 'secondAddressLine', Locked = true;
        CityTok: Label 'city', Locked = true;
        StateTok: Label 'state', Locked = true;
        ZipCodeTok: Label 'zipCode', Locked = true;
        ZipCodeExtensionTok: Label 'zipCodeExtension', Locked = true;
        DpvConfirmationTok: Label 'dpvConfirmation', Locked = true;
        DpvVacantTok: Label 'dpvVacant', Locked = true;
        ErrorMessageTok: Label 'errorMessage', Locked = true;
        MetadataTok: Label 'metadata', Locked = true;
        BusinessTok: Label 'business', Locked = true;
        PoBoxTok: Label 'poBox', Locked = true;
        ErrorTok: Label 'error', Locked = true;
        MessageTok: Label 'message', Locked = true;
        DetailsTok: Label 'details', Locked = true;
        TypeKeyTok: Label '@type', Locked = true;
        ReasonTok: Label 'reason', Locked = true;
        PremiseTok: Label 'PREMISE', Locked = true;
        SubPremiseTok: Label 'SUB_PREMISE', Locked = true;
        ApiKeyInvalidTok: Label 'API_KEY_INVALID', Locked = true;
        ServiceDisabledTok: Label 'SERVICE_DISABLED', Locked = true;
        BillingDisabledTok: Label 'BILLING_DISABLED', Locked = true;
        ApiKeyPrefixTok: Label 'API_KEY_', Locked = true;
        BlockedSuffixTok: Label '_BLOCKED', Locked = true;
        ErrorInfoSuffixTok: Label 'google.rpc.ErrorInfo', Locked = true;
        YesTok: Label 'Y', Locked = true;
        TrueTok: Label 'TRUE', Locked = true;
        DashTok: Label '-', Locked = true;
        SeparatorTok: Label ', ', Locked = true;
        MessageSeparatorTok: Label '; ', Locked = true;
}
