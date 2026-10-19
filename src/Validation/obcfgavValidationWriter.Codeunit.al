namespace OnlyBCFans.GoogleAddress;

codeunit 92806 "obcfgav Validation Writer"
{
    Access = Internal;
    Permissions = tabledata "obcfgav Validation Log" = i;

    trigger OnRun()
    begin
        case Outcome of
            Outcome::"Suggestion Accepted":
                WriteAcceptedSuggestion();
            Outcome::Confirmed:
                SetAddressValidated(true);
            Outcome::"Not Found":
                SetAddressValidated(false);
        end;

        InsertLogEntry(Outcome, TempAddressBuffer, Accepted);
    end;

    procedure Init(NewOutcome: Enum "obcfgav Validation Result"; var TempResult: Record "obcfgav Address Buffer" temporary; NewAccepted: Boolean; NewCanModify: Boolean)
    begin
        Outcome := NewOutcome;
        TempAddressBuffer := TempResult;
        Accepted := NewAccepted;
        CanModify := NewCanModify;
        AddressChanged := false;
    end;

    procedure WasAddressChanged(): Boolean
    begin
        exit(AddressChanged);
    end;

    procedure InsertLogEntry(LogResult: Enum "obcfgav Validation Result"; var TempResult: Record "obcfgav Address Buffer" temporary; LogAccepted: Boolean)
    var
        Log: Record "obcfgav Validation Log";
        KeepSuggestion: Boolean;
    begin
        KeepSuggestion := LogResult in [LogResult::"Suggestion Accepted", LogResult::Confirmed];
        Log.Init();
        Log."Customer No." := TempResult."Customer No.";
        Log."Source Table No." := TempResult."Source Table No.";
        Log."Address Type" := TempResult."Address Type";
        Log."Source SystemId" := TempResult."Source SystemId";
        Log."Source Description" := TempResult."Source Description";
        Log."Record No." := TempResult."Record No.";
        Log."Checked At" := CurrentDateTime();
        Log."User ID" := CopyStr(UserId(), 1, MaxStrLen(Log."User ID"));
        Log.Result := LogResult;
        Log.Accepted := LogAccepted;
        Log."Original Address" := TempResult."Original Address";
        Log."Original Address 2" := TempResult."Original Address 2";
        Log."Original City" := TempResult."Original City";
        Log."Original State" := TempResult."Original State";
        Log."Original ZIP Code" := TempResult."Original ZIP Code";
        if KeepSuggestion then begin
            Log."Suggested Address" := TempResult."Suggested Address";
            Log."Suggested Address 2" := TempResult."Suggested Address 2";
            Log."Suggested City" := TempResult."Suggested City";
            Log."Suggested State" := TempResult."Suggested State";
            Log."Suggested ZIP Code" := TempResult."Suggested ZIP Code";
        end;
        Log."DPV Confirmation" := TempResult."DPV Confirmation";
        Log."Validation Granularity" := TempResult."Validation Granularity";
        Log."Next Action" := TempResult."Next Action";
        Log."Provider Message" := CopyStr(TempResult."Provider Message", 1, MaxStrLen(Log."Provider Message"));
        Log."HTTP Status" := TempResult."HTTP Status";
        Log.Provider := TempResult.Provider;
        Log."Address Complete" := TempResult."Address Complete";
        Log.Insert(true);
    end;

    local procedure WriteAcceptedSuggestion()
    var
        SourceRecRef: RecordRef;
    begin
        OpenSourceForUpdate(SourceRecRef);

        if AddressSource.DiffersFromSnapshot(SourceRecRef, TempAddressBuffer."Address Type", TempAddressBuffer) then begin
            AddressChanged := true;
            Outcome := Outcome::"Suggestion Ignored";
            Accepted := false;
            exit;
        end;

        AddressSource.AssignSuggested(SourceRecRef, TempAddressBuffer."Address Type", TempAddressBuffer);
        BindSubscription(WriteGuard);
        AddressSource.SaveSource(SourceRecRef, true);
        UnbindSubscription(WriteGuard);
    end;

    local procedure SetAddressValidated(NewValue: Boolean)
    var
        SourceRecRef: RecordRef;
        CountryChanged: Boolean;
    begin
        if not CanModify then
            exit;

        OpenSourceForUpdate(SourceRecRef);
        if NewValue then
            CountryChanged := AddressSource.SetCountryIfBlank(SourceRecRef, TempAddressBuffer."Address Type", TempAddressBuffer);
        if (AddressSource.GetValidated(SourceRecRef, TempAddressBuffer."Address Type") = NewValue) and not CountryChanged then
            exit;

        AddressSource.SetValidated(SourceRecRef, TempAddressBuffer."Address Type", NewValue);
        AddressSource.SaveSource(SourceRecRef, CountryChanged);
    end;

    local procedure OpenSourceForUpdate(var SourceRecRef: RecordRef)
    begin
        if not AddressSource.OpenSource(SourceRecRef, TempAddressBuffer."Source Table No.", TempAddressBuffer."Source SystemId", TempAddressBuffer."Address Type", true) then
            Error(SourceNotFoundErr, SourceRecRef.Caption);
    end;

    var
        TempAddressBuffer: Record "obcfgav Address Buffer" temporary;
        AddressSource: Codeunit "obcfgav Address Source";
        WriteGuard: Codeunit "obcfgav Write Guard";
        Outcome: Enum "obcfgav Validation Result";
        Accepted: Boolean;
        CanModify: Boolean;
        AddressChanged: Boolean;
        SourceNotFoundErr: Label 'The %1 record no longer exists, so nothing was updated.', Comment = '%1 = table caption';
}
