namespace OnlyBCFans.GoogleAddress;

using Microsoft.Foundation.Address;

codeunit 92815 "obcfgav Country Mgt."
{
    Access = Internal;
    Permissions = tabledata "obcfgav Supported Country" = ri;

    procedure SeedSupportedCountries()
    var
        SupportedCountry: Record "obcfgav Supported Country";
        Pairs: List of [Text];
        Parts: List of [Text];
        Pair: Text;
        RegionCode: Code[2];
    begin
        Pairs := CountryListTok.Split(';');
        foreach Pair in Pairs do begin
            Parts := Pair.Split('=');
            RegionCode := CopyStr(Parts.Get(1), 1, MaxStrLen(RegionCode));
            if not SupportedCountry.Get(RegionCode) then begin
                SupportedCountry.Init();
                SupportedCountry."Region Code" := RegionCode;
                SupportedCountry.Name := CopyStr(Parts.Get(2), 1, MaxStrLen(SupportedCountry.Name));
                SupportedCountry.Enabled := true;
                SupportedCountry.Preview := RegionCode in ['IN', 'JP'];
                SupportedCountry."Residential Data" := not (RegionCode in ['CO', 'IT', 'SG']);
                SupportedCountry."USPS Delivery Data" := RegionCode in ['US', 'PR'];
                SupportedCountry.Insert();
            end;
        end;
    end;

    procedure ResolveRegion(CountryCode: Code[10]; var Region: Code[2]): Boolean
    var
        CountryRegion: Record "Country/Region";
    begin
        Clear(Region);
        if CountryCode = '' then
            exit(false);
        if CountryRegion.Get(CountryCode) then
            if CountryRegion."ISO Code" <> '' then begin
                Region := CopyStr(CountryRegion."ISO Code", 1, MaxStrLen(Region));
                exit(true);
            end;
        if CountryCode = 'UK' then begin
            Region := 'GB';
            exit(true);
        end;
        if StrLen(CountryCode) = 2 then begin
            Region := CopyStr(CountryCode, 1, MaxStrLen(Region));
            exit(true);
        end;
        exit(false);
    end;

    procedure RegionForCheck(CountryCode: Code[10]; var Region: Code[2]; var CountryName: Text): Boolean
    var
        Setup: Record "obcfgav Setup";
    begin
        Clear(Region);
        CountryName := '';
        if CountryCode <> '' then begin
            CountryName := DisplayName(CountryCode);
            exit(ResolveRegion(CountryCode, Region));
        end;
        if Setup.Get() then
            if Setup."US Country/Region Code" <> '' then begin
                CountryName := DisplayName(Setup."US Country/Region Code");
                exit(ResolveRegion(Setup."US Country/Region Code", Region));
            end;
        exit(true);
    end;

    procedure RegionForRecord(CountryCode: Code[10]; State: Text; PostalCode: Text; var Region: Code[2]; var CountryName: Text; var Inferred: Boolean): Boolean
    var
        Setup: Record "obcfgav Setup";
    begin
        Clear(Region);
        Inferred := false;
        CountryName := '';
        if CountryCode <> '' then begin
            CountryName := DisplayName(CountryCode);
            exit(ResolveRegion(CountryCode, Region));
        end;
        if Setup.Get() then
            if Setup."Blank Country Handling" = Setup."Blank Country Handling"::"Use default country" then begin
                if Setup."US Country/Region Code" = '' then
                    exit(true);
                CountryName := DisplayName(Setup."US Country/Region Code");
                exit(ResolveRegion(Setup."US Country/Region Code", Region));
            end;
        if HasUsableCanadianPostalCode(PostalCode) then
            Region := 'CA'
        else
            if LooksLikeUnitedStates(State, PostalCode) then
                Region := 'US';
        if Region <> '' then begin
            Inferred := true;
            CountryName := DisplayNameForRegion(Region);
        end;
        exit(true);
    end;

    procedure HasUsableCanadianPostalCode(PostCode: Text): Boolean
    var
        Compact: Text;
        Index: Integer;
    begin
        Compact := UpperCase(DelChr(PostCode, '=', ' -'));
        if StrLen(Compact) <> 6 then
            exit(false);
        for Index := 1 to 6 do
            if Index mod 2 = 1 then begin
                if DelChr(CopyStr(Compact, Index, 1), '=', 'ABCDEFGHIJKLMNOPQRSTUVWXYZ') <> '' then
                    exit(false);
            end else
                if DelChr(CopyStr(Compact, Index, 1), '=', '0123456789') <> '' then
                    exit(false);
        exit(true);
    end;

    procedure LooksLikeUnitedStates(State: Text; PostalCode: Text): Boolean
    var
        Digits: Text;
    begin
        State := UpperCase(DelChr(State, '<>', ' '));
        if StrLen(State) <> 2 then
            exit(false);
        if StrPos(UsStatesTok, ',' + State + ',') = 0 then
            exit(false);
        Digits := DelChr(PostalCode, '=', ' -');
        if not (StrLen(Digits) in [5, 9]) then
            exit(false);
        exit(DelChr(Digits, '=', '0123456789') = '');
    end;

    procedure CheckRegion(Region: Code[2]; CountryName: Text; var ErrorText: Text): Boolean
    var
        SupportedCountry: Record "obcfgav Supported Country";
    begin
        ErrorText := '';
        if CountryName = '' then
            CountryName := Region;
        if not SupportedCountry.Get(Region) then begin
            ErrorText := StrSubstNo(NotCoveredErr, CountryName);
            exit(false);
        end;
        if not SupportedCountry.Enabled then begin
            ErrorText := StrSubstNo(NotEnabledErr, CountryName);
            exit(false);
        end;
        exit(true);
    end;

    procedure NoIsoCodeText(CountryName: Text): Text
    begin
        exit(StrSubstNo(NoIsoCodeErr, CountryName));
    end;

    procedure NotCoveredText(CountryName: Text): Text
    begin
        exit(StrSubstNo(NotCoveredErr, CountryName));
    end;

    procedure DisplayName(CountryCode: Code[10]): Text
    var
        CountryRegion: Record "Country/Region";
    begin
        if CountryRegion.Get(CountryCode) then
            if CountryRegion.Name <> '' then
                exit(CountryRegion.Name);
        exit(CountryCode);
    end;

    procedure DisplayNameForRegion(Region: Code[2]): Text
    var
        SupportedCountry: Record "obcfgav Supported Country";
    begin
        if SupportedCountry.Get(Region) then
            exit(SupportedCountry.Name);
        exit(Region);
    end;

    procedure BCCodeForRegion(Region: Code[2]): Code[10]
    var
        CountryRegion: Record "Country/Region";
        Setup: Record "obcfgav Setup";
        DefaultRegion: Code[2];
    begin
        if Region = '' then
            exit('');
        if Setup.Get() then
            if Setup."US Country/Region Code" <> '' then
                if ResolveRegion(Setup."US Country/Region Code", DefaultRegion) then
                    if DefaultRegion = Region then
                        exit(Setup."US Country/Region Code");
        CountryRegion.SetRange("ISO Code", Region);
        if CountryRegion.FindFirst() then
            exit(CountryRegion.Code);
        CountryRegion.Reset();
        if CountryRegion.Get(Region) then
            exit(CountryRegion.Code);
        exit('');
    end;

    procedure IsUnitedStatesLike(Region: Code[2]): Boolean
    begin
        exit(Region in ['US', 'PR']);
    end;

    procedure IsCanada(Region: Code[2]): Boolean
    begin
        exit(Region = 'CA');
    end;

    procedure NeedsStateAndPostalCode(Region: Code[2]): Boolean
    begin
        exit(IsUnitedStatesLike(Region) or IsCanada(Region));
    end;

    var
        UsStatesTok: Label ',AL,AK,AZ,AR,CA,CO,CT,DE,DC,FL,GA,HI,ID,IL,IN,IA,KS,KY,LA,ME,MD,MA,MI,MN,MS,MO,MT,NE,NV,NH,NJ,NM,NY,NC,ND,OH,OK,OR,PA,RI,SC,SD,TN,TX,UT,VT,VA,WA,WV,WI,WY,PR,AA,AE,AP,', Locked = true;
        CountryListTok: Label 'AR=Argentina;AT=Austria;AU=Australia;BE=Belgium;BG=Bulgaria;BR=Brazil;CA=Canada;CH=Switzerland;CL=Chile;CO=Colombia;CZ=Czechia;DE=Germany;DK=Denmark;EE=Estonia;ES=Spain;FI=Finland;FR=France;GB=United Kingdom;HR=Croatia;HU=Hungary;IE=Ireland;IN=India;IT=Italy;JP=Japan;LT=Lithuania;LU=Luxembourg;LV=Latvia;MX=Mexico;MY=Malaysia;NL=Netherlands;NO=Norway;NZ=New Zealand;PL=Poland;PR=Puerto Rico;PT=Portugal;SE=Sweden;SG=Singapore;SI=Slovenia;SK=Slovakia;US=United States', Locked = true;
        NotCoveredErr: Label 'Google Maps can''t validate addresses in %1.', Comment = '%1 = name of the country or region';
        NoIsoCodeErr: Label 'Google Maps can''t tell which country %1 is. Fill in the ISO Code of this country or region on the Countries/Regions page and try again.', Comment = '%1 = name of the country or region';
        NotEnabledErr: Label 'Address validation isn''t turned on for %1. Ask your administrator to turn it on in Google Address Validation Supported Countries.', Comment = '%1 = name of the country or region';
}
