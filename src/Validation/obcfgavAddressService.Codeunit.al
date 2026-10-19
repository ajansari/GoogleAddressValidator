namespace OnlyBCFans.GoogleAddress;

codeunit 92804 "obcfgav Address Service"
{
    Access = Public;

    procedure SetTransport(NewTransport: Interface "obcfgav Http Transport")
    var
        CallerModuleInfo: ModuleInfo;
    begin
        NavApp.GetCallerModuleInfo(CallerModuleInfo);
        CredentialMgt.CheckCallerAllowed(CallerModuleInfo);
        Transport := NewTransport;
        TransportSet := true;
    end;

    procedure SetProvider(NewProvider: Interface "obcfgav Address Provider")
    var
        CallerModuleInfo: ModuleInfo;
    begin
        NavApp.GetCallerModuleInfo(CallerModuleInfo);
        CredentialMgt.CheckCallerAllowed(CallerModuleInfo);
        Provider := NewProvider;
        ProviderSet := true;
    end;

    procedure ValidateAddress(var TempAddressBuffer: Record "obcfgav Address Buffer" temporary): Boolean
    var
        CallerModuleInfo: ModuleInfo;
        Success: Boolean;
    begin
        NavApp.GetCallerModuleInfo(CallerModuleInfo);
        CredentialMgt.CheckCallerAllowed(CallerModuleInfo);
        Success := RunValidation(TempAddressBuffer);
        SaveBuffer(TempAddressBuffer);
        exit(Success);
    end;

    procedure TestConnection(var ErrorText: Text): Boolean
    var
        ActiveProvider: Interface "obcfgav Address Provider";
        CallerModuleInfo: ModuleInfo;
    begin
        NavApp.GetCallerModuleInfo(CallerModuleInfo);
        CredentialMgt.CheckCallerAllowed(CallerModuleInfo);
        ErrorText := '';
        if not LoadSetup() then begin
            ErrorText := SetupIncompleteErr;
            exit(false);
        end;
        if not ResolveProvider(ActiveProvider) then begin
            ErrorText := SetupIncompleteErr;
            exit(false);
        end;
        if not ActiveProvider.HasCredentials() then begin
            ErrorText := MissingApiKeyErr;
            exit(false);
        end;
        exit(ActiveProvider.TestConnection(GetTransport(), Setup."Timeout (Seconds)" * 1000, ErrorText));
    end;

    internal procedure SetupIncompleteText(): Text
    begin
        exit(SetupIncompleteErr);
    end;

    procedure ProviderDisplayName(): Text
    var
        ActiveProvider: Interface "obcfgav Address Provider";
    begin
        if not LoadSetup() then
            exit('');
        if not ResolveProvider(ActiveProvider) then
            exit('');
        exit(ActiveProvider.DisplayName());
    end;

    local procedure RunValidation(var TempAddressBuffer: Record "obcfgav Address Buffer" temporary): Boolean
    var
        ActiveProvider: Interface "obcfgav Address Provider";
    begin
        ClearResult(TempAddressBuffer);
        if not LoadSetup() then begin
            SetFailure(TempAddressBuffer, SetupIncompleteErr);
            exit(false);
        end;
        if not ResolveProvider(ActiveProvider) then begin
            SetFailure(TempAddressBuffer, SetupIncompleteErr);
            exit(false);
        end;
        if not ActiveProvider.HasCredentials() then begin
            SetFailure(TempAddressBuffer, MissingApiKeyErr);
            exit(false);
        end;
        TempAddressBuffer.Provider := Setup.Provider;
        exit(ActiveProvider.ValidateAddress(TempAddressBuffer, GetTransport(), Setup."Timeout (Seconds)" * 1000));
    end;

    local procedure LoadSetup(): Boolean
    begin
        if not Setup.Get() then
            exit(false);
        exit(Setup.Provider <> Setup.Provider::" ");
    end;

    local procedure ResolveProvider(var ActiveProvider: Interface "obcfgav Address Provider"): Boolean
    begin
        if ProviderSet then begin
            ActiveProvider := Provider;
            exit(true);
        end;
        case Setup.Provider of
            Setup.Provider::Google:
                begin
                    ActiveProvider := GoogleClient;
                    exit(true);
                end;
        end;
        exit(false);
    end;

    local procedure GetTransport(): Interface "obcfgav Http Transport"
    var
        DefaultTransport: Codeunit "obcfgav Http Transport Impl.";
    begin
        if not TransportSet then
            exit(DefaultTransport);
        exit(Transport);
    end;

    local procedure ClearResult(var TempAddressBuffer: Record "obcfgav Address Buffer" temporary)
    begin
        TempAddressBuffer."Suggested Address" := '';
        TempAddressBuffer."Suggested Address 2" := '';
        TempAddressBuffer."Suggested City" := '';
        TempAddressBuffer."Suggested State" := '';
        TempAddressBuffer."Suggested ZIP Code" := '';
        TempAddressBuffer."DPV Confirmation" := '';
        TempAddressBuffer.Vacant := false;
        TempAddressBuffer.Business := false;
        TempAddressBuffer."Validation Granularity" := '';
        TempAddressBuffer."Next Action" := '';
        TempAddressBuffer."Provider Message" := '';
        TempAddressBuffer."HTTP Status" := 0;
        TempAddressBuffer."Not Found" := false;
        TempAddressBuffer."User Message" := '';
        TempAddressBuffer."Address Complete" := false;
        TempAddressBuffer."Has Replaced" := false;
        TempAddressBuffer."Has Inferred" := false;
        TempAddressBuffer."Has Spell Corrected" := false;
        TempAddressBuffer."Has Unconfirmed" := false;
        TempAddressBuffer."PO Box" := false;
        TempAddressBuffer."Missing Components" := '';
    end;

    local procedure SetFailure(var TempAddressBuffer: Record "obcfgav Address Buffer" temporary; UserMessage: Text)
    begin
        TempAddressBuffer."HTTP Status" := 0;
        TempAddressBuffer."Not Found" := false;
        TempAddressBuffer."User Message" := CopyStr(UserMessage, 1, MaxStrLen(TempAddressBuffer."User Message"));
        TempAddressBuffer."Provider Message" := '';
    end;

    local procedure SaveBuffer(var TempAddressBuffer: Record "obcfgav Address Buffer" temporary)
    begin
        if not TempAddressBuffer.Insert() then
            TempAddressBuffer.Modify();
    end;

    var
        Setup: Record "obcfgav Setup";
        CredentialMgt: Codeunit "obcfgav Credential Mgt.";
        GoogleClient: Codeunit "obcfgav Google Address Client";
        Transport: Interface "obcfgav Http Transport";
        Provider: Interface "obcfgav Address Provider";
        TransportSet: Boolean;
        ProviderSet: Boolean;
        SetupIncompleteErr: Label 'Address validation is not set up. Contact your administrator.';
        MissingApiKeyErr: Label 'Enter the API key first.';
}
