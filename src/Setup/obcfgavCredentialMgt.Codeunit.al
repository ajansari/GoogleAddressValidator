namespace OnlyBCFans.GoogleAddress;

using System.Environment;
using System.Environment.Configuration;

codeunit 92800 "obcfgav Credential Mgt."
{
    Access = Public;

    [NonDebuggable]
    procedure SetApiKey(NewValue: SecretText)
    var
        CallerModuleInfo: ModuleInfo;
    begin
        NavApp.GetCallerModuleInfo(CallerModuleInfo);
        CheckCallerAllowed(CallerModuleInfo);
        StoreCredential(ApiKeyStorageTok, NewValue);
        MarkSetupCompleteIfReady();
    end;

    procedure HasApiKey(): Boolean
    begin
        exit(IsolatedStorage.Contains(ApiKeyStorageTok, DataScope::Company));
    end;

    [NonDebuggable]
    internal procedure GetApiKey(): SecretText
    var
        Value: SecretText;
    begin
        if IsolatedStorage.Get(ApiKeyStorageTok, DataScope::Company, Value) then;
        exit(Value);
    end;

    [NonDebuggable]
    local procedure StoreCredential(StorageKey: Text; Value: SecretText)
    begin
        if Value.IsEmpty() then begin
            if IsolatedStorage.Contains(StorageKey, DataScope::Company) then
                IsolatedStorage.Delete(StorageKey, DataScope::Company);
            exit;
        end;
        if EncryptionEnabled() then
            IsolatedStorage.SetEncrypted(StorageKey, Value, DataScope::Company)
        else
            IsolatedStorage.Set(StorageKey, Value, DataScope::Company);
    end;

    local procedure MarkSetupCompleteIfReady()
    var
        GuidedExperience: Codeunit "Guided Experience";
    begin
        if HasApiKey() then
            GuidedExperience.CompleteAssistedSetup(ObjectType::Page, Page::"obcfgav Setup Wizard");
    end;

    /// <summary>
    /// Raises an error unless the caller is this app, or the test app in a sandbox.
    /// The caller module must be read by the public procedure itself (NavApp.GetCallerModuleInfo),
    /// never inside a helper, otherwise it always names this app.
    /// </summary>
    internal procedure CheckCallerAllowed(CallerModuleInfo: ModuleInfo)
    var
        EnvironmentInformation: Codeunit "Environment Information";
        CurrentModuleInfo: ModuleInfo;
        TestAppId: Guid;
    begin
        NavApp.GetCurrentModuleInfo(CurrentModuleInfo);
        if CallerModuleInfo.Id = CurrentModuleInfo.Id then
            exit;
        Evaluate(TestAppId, TestAppIdTok);
        if (CallerModuleInfo.Id = TestAppId) and EnvironmentInformation.IsSandbox() then
            exit;
        Error(CallerNotAllowedErr);
    end;

    var
        ApiKeyStorageTok: Label 'OBCFGAV-ApiKey', Locked = true;
        TestAppIdTok: Label 'ebe1c8ca-a413-4f2b-9de7-37d8c1ae4d5a', Locked = true;
        CallerNotAllowedErr: Label 'This procedure can only be called by the Google Address Validator app.';
}
