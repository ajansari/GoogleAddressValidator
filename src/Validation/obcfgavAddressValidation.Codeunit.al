namespace OnlyBCFans.GoogleAddress;

using Microsoft.Sales.Customer;
using System.Privacy;
using System.Security.AccessControl;
using System.Security.User;

codeunit 92803 "obcfgav Address Validation"
{
    Access = Public;

    procedure SetTransport(NewTransport: Interface "obcfgav Http Transport")
    var
        CallerModuleInfo: ModuleInfo;
    begin
        NavApp.GetCallerModuleInfo(CallerModuleInfo);
        CredentialMgt.CheckCallerAllowed(CallerModuleInfo);
        AddressService.SetTransport(NewTransport);
    end;

    procedure SetProvider(NewProvider: Interface "obcfgav Address Provider")
    var
        CallerModuleInfo: ModuleInfo;
    begin
        NavApp.GetCallerModuleInfo(CallerModuleInfo);
        CredentialMgt.CheckCallerAllowed(CallerModuleInfo);
        AddressService.SetProvider(NewProvider);
    end;

    procedure ValidateCustomerAddress(CustomerNo: Code[20])
    var
        Outcome: Enum "obcfgav Validation Result";
        CallerModuleInfo: ModuleInfo;
        UserMessage: Text;
    begin
        NavApp.GetCallerModuleInfo(CallerModuleInfo);
        CredentialMgt.CheckCallerAllowed(CallerModuleInfo);
        if not TryValidateCustomerAddress(CustomerNo, Outcome, UserMessage) then
            Error(ShowTextTok, UserMessage);

        if UserMessage <> '' then
            Message(ShowTextTok, UserMessage);
    end;

    procedure TryValidateCustomerAddress(CustomerNo: Code[20]; var Outcome: Enum "obcfgav Validation Result"; var UserMessage: Text): Boolean
    var
        Customer: Record Customer;
        CallerModuleInfo: ModuleInfo;
    begin
        NavApp.GetCallerModuleInfo(CallerModuleInfo);
        CredentialMgt.CheckCallerAllowed(CallerModuleInfo);
        Clear(Outcome);
        UserMessage := '';

        Customer.SetLoadFields("No.");
        if not Customer.Get(CustomerNo) then begin
            UserMessage := NoCustomerErr;
            exit(false);
        end;
        exit(RunValidation(Database::Customer, Customer.SystemId, Enum::"obcfgav Address Type"::Main, Outcome, UserMessage));
    end;

    /// <summary>
    /// Checks the address of one master-data record or address block. Caller-checked. Commits and opens a modal comparison dialog, so it is for interactive use only.
    /// </summary>
    procedure ValidateAddress(SourceTableNo: Integer; SourceSystemId: Guid; AddressType: Enum "obcfgav Address Type")
    var
        Outcome: Enum "obcfgav Validation Result";
        CallerModuleInfo: ModuleInfo;
        UserMessage: Text;
    begin
        NavApp.GetCallerModuleInfo(CallerModuleInfo);
        CredentialMgt.CheckCallerAllowed(CallerModuleInfo);
        if not RunValidation(SourceTableNo, SourceSystemId, AddressType, Outcome, UserMessage) then
            Error(ShowTextTok, UserMessage);

        if UserMessage <> '' then
            Message(ShowTextTok, UserMessage);
    end;

    /// <summary>
    /// Same as ValidateAddress, but returns the outcome and the user message instead of showing them. Caller-checked. Commits and opens a modal comparison dialog.
    /// </summary>
    procedure TryValidateAddress(SourceTableNo: Integer; SourceSystemId: Guid; AddressType: Enum "obcfgav Address Type"; var Outcome: Enum "obcfgav Validation Result"; var UserMessage: Text): Boolean
    var
        CallerModuleInfo: ModuleInfo;
    begin
        NavApp.GetCallerModuleInfo(CallerModuleInfo);
        CredentialMgt.CheckCallerAllowed(CallerModuleInfo);
        exit(RunValidation(SourceTableNo, SourceSystemId, AddressType, Outcome, UserMessage));
    end;

    procedure ValuesDiffer(BCValue: Text; ProviderValue: Text): Boolean
    begin
        exit(Normalize(BCValue) <> Normalize(ProviderValue));
    end;

    /// <summary>
    /// Kept for callers of version 1.0.0.0. Use CanModifySource for other tables.
    /// </summary>
    procedure CanModifyCustomers(): Boolean
    begin
        exit(CanModifySource(Database::Customer));
    end;

    procedure CanModifySource(SourceTableNo: Integer): Boolean
    var
        TempExpandedPermission: Record "Expanded Permission" temporary;
        UserPermissions: Codeunit "User Permissions";
    begin
        TempExpandedPermission := UserPermissions.GetEffectivePermission(TempExpandedPermission."Object Type"::"Table Data", SourceTableNo);
        exit(TempExpandedPermission."Modify Permission" = TempExpandedPermission."Modify Permission"::Yes);
    end;

    local procedure RunValidation(SourceTableNo: Integer; SourceSystemId: Guid; AddressType: Enum "obcfgav Address Type"; var Outcome: Enum "obcfgav Validation Result"; var UserMessage: Text): Boolean
    var
        TempAddressBuffer: Record "obcfgav Address Buffer" temporary;
        AddressCompare: Page "obcfgav Address Compare";
        SourceRecRef: RecordRef;
        Region: Code[2];
        RegionInferred: Boolean;
        AddressFound: Boolean;
        CanAccept: Boolean;
        BlockReason: Text;
        DeliveryNote: Text;
        ResultErrorText: Text;
    begin
        Clear(Outcome);
        UserMessage := '';

        if not AddressSource.IsSupported(SourceTableNo, AddressType) then begin
            UserMessage := UnsupportedSourceErr;
            exit(false);
        end;

        CanModify := CanModifySource(SourceTableNo);
        if not AddressSource.OpenSource(SourceRecRef, SourceTableNo, SourceSystemId, AddressType, false) then begin
            if SourceTableNo = Database::Customer then
                UserMessage := NoCustomerErr
            else
                UserMessage := NoRecordErr;
            exit(false);
        end;
        if AddressSource.IsPrivacyBlocked(SourceRecRef) then begin
            UserMessage := PrivacyBlockedErr;
            exit(false);
        end;
        if not CheckPreconditions(SourceRecRef, AddressType, Region, RegionInferred, UserMessage) then
            exit(false);
        if not ConfirmPrivacyNotice() then begin
            UserMessage := PrivacyNoticeNotApprovedErr;
            exit(false);
        end;

        AddressSource.FillOriginal(SourceRecRef, AddressType, TempAddressBuffer);
        TempAddressBuffer."Region Code" := Region;
        AddressFound := AddressService.ValidateAddress(TempAddressBuffer);
        if RegionInferred and not AddressFound and TempAddressBuffer."Not Found" then begin
            Region := '';
            AddressSource.FillOriginal(SourceRecRef, AddressType, TempAddressBuffer);
            AddressFound := AddressService.ValidateAddress(TempAddressBuffer);
        end;
        Commit();

        if AddressFound and (Region = '') and (TempAddressBuffer."Result Region Code" <> '') then
            if not CountryMgt.CheckRegion(TempAddressBuffer."Result Region Code", CountryMgt.DisplayNameForRegion(TempAddressBuffer."Result Region Code"), ResultErrorText) then begin
                TempAddressBuffer."Not Found" := true;
                TempAddressBuffer."User Message" := CopyStr(ResultErrorText, 1, MaxStrLen(TempAddressBuffer."User Message"));
                AddressFound := false;
            end;

        if not AddressFound then
            exit(HandleProviderFailure(TempAddressBuffer, Outcome, UserMessage));

        if not AnyValueDiffers(TempAddressBuffer) then begin
            if not RunWriter(Outcome::Confirmed, TempAddressBuffer, false, Outcome, UserMessage) then
                exit(false);
            DeliveryNote := DeliveryWarning(TempAddressBuffer);
            if DeliveryNote = '' then
                UserMessage := StrSubstNo(ConfirmedMsg, AddressService.ProviderDisplayName())
            else
                UserMessage := StrSubstNo(ConfirmedNoteMsg, AddressService.ProviderDisplayName(), DeliveryNote);
            exit(true);
        end;

        if CanModify then
            CanAccept := FitsSourceFields(SourceRecRef, AddressType, TempAddressBuffer, BlockReason)
        else
            BlockReason := NoPermissionMessage(SourceRecRef);

        AddressCompare.SetData(TempAddressBuffer, CanAccept, BlockReason, AddressService.ProviderDisplayName());
        AddressCompare.LookupMode(false);
        if (AddressCompare.RunModal() = Action::OK) and CanAccept then
            exit(RunWriter(Outcome::"Suggestion Accepted", TempAddressBuffer, true, Outcome, UserMessage));

        exit(RunWriter(Outcome::"Suggestion Ignored", TempAddressBuffer, false, Outcome, UserMessage));
    end;

    local procedure ConfirmPrivacyNotice(): Boolean
    var
        SetupRegistration: Codeunit "obcfgav Setup Registration";
        PrivacyNotice: Codeunit "Privacy Notice";
    begin
        SetupRegistration.EnsurePrivacyNotice();
        Commit();
        exit(PrivacyNotice.ConfirmPrivacyNoticeApproval(SetupRegistration.PrivacyNoticeId()));
    end;

    local procedure CheckPreconditions(var SourceRecRef: RecordRef; AddressType: Enum "obcfgav Address Type"; var Region: Code[2]; var Inferred: Boolean; var ErrorText: Text): Boolean
    var
        Setup: Record "obcfgav Setup";
        CountryCode: Code[10];
        CountryName: Text;
        Street: Text;
        City: Text;
        State: Text;
        Zip: Text;
    begin
        Clear(Region);
        if not Setup.Get() then begin
            ErrorText := AddressService.SetupIncompleteText();
            exit(false);
        end;
        if not Setup.Enabled or (Setup.Provider = Setup.Provider::" ") or not CredentialMgt.HasApiKey() then begin
            ErrorText := AddressService.SetupIncompleteText();
            exit(false);
        end;

        Street := AddressSource.GetValue(SourceRecRef, AddressType, 1);
        City := AddressSource.GetValue(SourceRecRef, AddressType, 3);
        State := AddressSource.GetValue(SourceRecRef, AddressType, 4);
        Zip := AddressSource.GetValue(SourceRecRef, AddressType, 5);

        CountryCode := CopyStr(AddressSource.GetValue(SourceRecRef, AddressType, 6), 1, MaxStrLen(CountryCode));
        if not CountryMgt.RegionForRecord(CountryCode, State, Zip, Region, CountryName, Inferred) then begin
            ErrorText := CountryMgt.NoIsoCodeText(CountryName);
            exit(false);
        end;
        if Region <> '' then
            if not CountryMgt.CheckRegion(Region, CountryName, ErrorText) then
                exit(false);

        case true of
            CountryMgt.IsUnitedStatesLike(Region):
                begin
                    if (Street = '') or (not HasUsableZip(Zip) and ((City = '') or (State = ''))) then begin
                        ErrorText := AddressIncompleteErr;
                        exit(false);
                    end;
                    if (State <> '') and not IsStateCode(State) then begin
                        ErrorText := StateCodeErr;
                        exit(false);
                    end;
                end;
            CountryMgt.IsCanada(Region):
                begin
                    if (Street = '') or (not CountryMgt.HasUsableCanadianPostalCode(Zip) and ((City = '') or (State = ''))) then begin
                        ErrorText := AddressIncompleteErr;
                        exit(false);
                    end;
                    if (State <> '') and not IsStateCode(State) then begin
                        ErrorText := StateCodeErr;
                        exit(false);
                    end;
                end;
            else
                if (Street = '') or ((City = '') and (Zip = '')) then begin
                    ErrorText := AddressIncompleteErr;
                    exit(false);
                end;
        end;

        exit(true);
    end;

    local procedure HasUsableZip(PostCode: Text): Boolean
    var
        Trimmed: Text;
        FirstFive: Text;
    begin
        Trimmed := DelChr(PostCode, '<>', ' ');
        if StrLen(Trimmed) < 5 then
            exit(false);
        FirstFive := CopyStr(Trimmed, 1, 5);
        exit(DelChr(FirstFive, '=', '0123456789') = '');
    end;

    local procedure IsStateCode(Value: Text): Boolean
    var
        Trimmed: Text;
    begin
        Trimmed := UpperCase(DelChr(Value, '<>', ' '));
        if StrLen(Trimmed) <> 2 then
            exit(false);
        exit(DelChr(Trimmed, '=', 'ABCDEFGHIJKLMNOPQRSTUVWXYZ') = '');
    end;

    local procedure AnyValueDiffers(TempAddressBuffer: Record "obcfgav Address Buffer" temporary): Boolean
    begin
        exit(
            ValuesDiffer(
                TempAddressBuffer."Original Address" + ' ' + TempAddressBuffer."Original Address 2",
                TempAddressBuffer."Suggested Address" + ' ' + TempAddressBuffer."Suggested Address 2") or
            ValuesDiffer(TempAddressBuffer."Original City", TempAddressBuffer."Suggested City") or
            ValuesDiffer(TempAddressBuffer."Original State", TempAddressBuffer."Suggested State") or
            ValuesDiffer(TempAddressBuffer."Original ZIP Code", TempAddressBuffer."Suggested ZIP Code"));
    end;

    internal procedure DeliveryWarning(TempAddressBuffer: Record "obcfgav Address Buffer" temporary): Text
    begin
        if (TempAddressBuffer."DPV Confirmation" = DpvMissingSecondaryTok) or (TempAddressBuffer."Next Action" = ConfirmAddSubpremisesTok) then
            exit(DeliveryMissingSuiteTxt);
        if TempAddressBuffer."DPV Confirmation" = DpvUnconfirmedSecondaryTok then
            exit(DeliveryUnconfirmedSuiteTxt);
        if TempAddressBuffer."DPV Confirmation" = DpvNotConfirmedTok then
            exit(DeliveryNotDeliverableTxt);
        exit('');
    end;

    local procedure Normalize(Value: Text): Text
    var
        Result: Text;
    begin
        Result := UpperCase(DelChr(Value, '=', '.,'));
        while StrPos(Result, '  ') > 0 do
            Result := Result.Replace('  ', ' ');
        exit(DelChr(Result, '<>', ' '));
    end;

    local procedure FitsSourceFields(var SourceRecRef: RecordRef; AddressType: Enum "obcfgav Address Type"; TempAddressBuffer: Record "obcfgav Address Buffer" temporary; var BlockReason: Text): Boolean
    begin
        if not Fits(TempAddressBuffer."Suggested Address", AddressSource.GetLength(SourceRecRef, AddressType, 1), AddressCaptionTxt, BlockReason) then
            exit(false);
        if not Fits(TempAddressBuffer."Suggested Address 2", AddressSource.GetLength(SourceRecRef, AddressType, 2), Address2CaptionTxt, BlockReason) then
            exit(false);
        if not Fits(TempAddressBuffer."Suggested City", AddressSource.GetLength(SourceRecRef, AddressType, 3), CityCaptionTxt, BlockReason) then
            exit(false);
        if not Fits(TempAddressBuffer."Suggested State", AddressSource.GetLength(SourceRecRef, AddressType, 4), StateCaptionTxt, BlockReason) then
            exit(false);
        if not Fits(TempAddressBuffer."Suggested ZIP Code", AddressSource.GetLength(SourceRecRef, AddressType, 5), ZipCaptionTxt, BlockReason) then
            exit(false);
        exit(true);
    end;

    local procedure Fits(Value: Text; MaxLength: Integer; FieldCaption: Text; var BlockReason: Text): Boolean
    begin
        if StrLen(Value) <= MaxLength then
            exit(true);
        BlockReason := StrSubstNo(ValueTooLongTxt, FieldCaption, MaxLength);
        exit(false);
    end;

    local procedure NoPermissionMessage(var SourceRecRef: RecordRef): Text
    begin
        if SourceRecRef.Number = Database::Customer then
            exit(NoPermissionTxt);
        exit(StrSubstNo(NoPermissionRecordTxt, SourceRecRef.Caption));
    end;

    local procedure HandleProviderFailure(var TempAddressBuffer: Record "obcfgav Address Buffer" temporary; var Outcome: Enum "obcfgav Validation Result"; var UserMessage: Text): Boolean
    var
        Writer: Codeunit "obcfgav Validation Writer";
    begin
        UserMessage := TempAddressBuffer."User Message";
        if TempAddressBuffer."Not Found" then
            exit(RunWriter(Outcome::"Not Found", TempAddressBuffer, false, Outcome, UserMessage));

        Writer.InsertLogEntry(Outcome::Error, TempAddressBuffer, false);
        Commit();
        Outcome := Outcome::Error;
        exit(false);
    end;

    local procedure RunWriter(WriteOutcome: Enum "obcfgav Validation Result"; var TempAddressBuffer: Record "obcfgav Address Buffer" temporary; WriteAccepted: Boolean; var Outcome: Enum "obcfgav Validation Result"; var UserMessage: Text): Boolean
    var
        Writer: Codeunit "obcfgav Validation Writer";
    begin
        Writer.Init(WriteOutcome, TempAddressBuffer, WriteAccepted, CanModify);
        if not Writer.Run() then
            exit(LogWriteFailure(TempAddressBuffer, Outcome, UserMessage));

        Commit();
        Outcome := WriteOutcome;
        if Writer.WasAddressChanged() then begin
            Outcome := Outcome::"Suggestion Ignored";
            if TempAddressBuffer."Source Table No." = Database::Customer then
                UserMessage := AddressChangedMsg
            else
                UserMessage := AddressChangedRecordMsg;
        end;
        RunLinkedSync(TempAddressBuffer, WriteOutcome);
        exit(true);
    end;

    local procedure RunLinkedSync(var TempAddressBuffer: Record "obcfgav Address Buffer" temporary; WriteOutcome: Enum "obcfgav Validation Result")
    var
        LinkedSync: Codeunit "obcfgav Address Sync Subscr.";
    begin
        if not CanModify then
            exit;
        if not (WriteOutcome in [WriteOutcome::Confirmed, WriteOutcome::"Not Found"]) then
            exit;

        LinkedSync.Init(TempAddressBuffer."Source Table No.", TempAddressBuffer."Source SystemId", TempAddressBuffer."Address Type");
        if LinkedSync.Run() then
            Commit()
        else
            ClearLastError();
    end;

    local procedure LogWriteFailure(var TempAddressBuffer: Record "obcfgav Address Buffer" temporary; var Outcome: Enum "obcfgav Validation Result"; var UserMessage: Text): Boolean
    var
        Writer: Codeunit "obcfgav Validation Writer";
    begin
        UserMessage := GetLastErrorText();
        TempAddressBuffer."Provider Message" := CopyStr(UserMessage, 1, MaxStrLen(TempAddressBuffer."Provider Message"));
        Writer.InsertLogEntry(Outcome::Error, TempAddressBuffer, false);
        Commit();
        Outcome := Outcome::Error;
        exit(false);
    end;

    var
        AddressService: Codeunit "obcfgav Address Service";
        AddressSource: Codeunit "obcfgav Address Source";
        CountryMgt: Codeunit "obcfgav Country Mgt.";
        CredentialMgt: Codeunit "obcfgav Credential Mgt.";
        CanModify: Boolean;
        DpvMissingSecondaryTok: Label 'D', Locked = true;
        DpvUnconfirmedSecondaryTok: Label 'S', Locked = true;
        DpvNotConfirmedTok: Label 'N', Locked = true;
        NoCustomerErr: Label 'The customer was not found.';
        NoRecordErr: Label 'The record was not found.';
        UnsupportedSourceErr: Label 'Address validation is not available for this record.';
        PrivacyBlockedErr: Label 'Address validation is not available for this record because it is blocked due to privacy.';
        AddressIncompleteErr: Label 'Enter a street address and either a ZIP / postal code or a city (in the US and Canada, a city needs its state or province too).';
        StateCodeErr: Label 'Enter the 2-letter state or province code in the State field.';
        ConfirmedMsg: Label 'The address is confirmed by %1. No changes are needed.', Comment = '%1 = address validation provider name';
        ConfirmedNoteMsg: Label 'The address is confirmed by %1. No changes are needed. Note: %2', Comment = '%1 = address validation provider name, %2 = delivery note';
        AddressChangedMsg: Label 'The customer''s address was changed while the suggested address was open, so nothing was updated. Run Validate Address again.';
        AddressChangedRecordMsg: Label 'The address was changed while the suggested address was open, so nothing was updated. Run Validate Address again.';
        NoPermissionTxt: Label 'You can''t accept the suggested address because you don''t have permission to change customers. Choose OK or Cancel to close without changes.';
        NoPermissionRecordTxt: Label 'You can''t accept the suggested address because you don''t have permission to change %1 records. Choose OK or Cancel to close without changes.', Comment = '%1 = table caption, for example Vendor';
        ValueTooLongTxt: Label 'You can''t accept the suggested address because the suggested value for %1 is longer than %2 characters. Choose OK or Cancel to close without changes.', Comment = '%1 = field caption (Address, Address 2, City, State or ZIP Code), %2 = maximum length';
        AddressCaptionTxt: Label 'Address';
        Address2CaptionTxt: Label 'Address 2';
        CityCaptionTxt: Label 'City';
        StateCaptionTxt: Label 'State / Province';
        ZipCaptionTxt: Label 'ZIP / Postal Code';
        DeliveryMissingSuiteTxt: Label 'The suite or apartment number is missing.';
        DeliveryUnconfirmedSuiteTxt: Label 'The suite or apartment number could not be confirmed.';
        DeliveryNotDeliverableTxt: Label 'USPS could not confirm this address as deliverable.';
        PrivacyNoticeNotApprovedErr: Label 'The privacy notice for sending addresses to Google Maps has not been agreed to, so nothing was sent.';
        ConfirmAddSubpremisesTok: Label 'CONFIRM_ADD_SUBPREMISES', Locked = true;
        ShowTextTok: Label '%1', Comment = '%1 = text already composed for the user, shown unchanged', Locked = true;
}
