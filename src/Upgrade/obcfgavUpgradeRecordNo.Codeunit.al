namespace OnlyBCFans.GoogleAddress;

using System.Upgrade;

codeunit 92814 "obcfgav Upgrade Record No."
{
    Subtype = Upgrade;
    Access = Internal;
    Permissions = tabledata "obcfgav Validation Log" = rm;

    trigger OnUpgradePerCompany()
    var
        UpgradeTag: Codeunit "Upgrade Tag";
        UpgradeTags: Codeunit "obcfgav Upgrade Tags";
    begin
        if UpgradeTag.HasUpgradeTag(UpgradeTags.GetRecordNoTag()) then
            exit;

        UpgradeRecordNo();
        UpgradeTag.SetUpgradeTag(UpgradeTags.GetRecordNoTag());
    end;

    local procedure UpgradeRecordNo()
    var
        Log: Record "obcfgav Validation Log";
        RecordNo: Text;
    begin
        Log.SetLoadFields("Record No.", "Customer No.", "Source Table No.", "Source SystemId");
        if Log.FindSet(true) then
            repeat
                if Log."Record No." = '' then begin
                    RecordNo := ReadRecordNo(Log);
                    if RecordNo <> '' then begin
                        Log."Record No." := CopyStr(RecordNo, 1, MaxStrLen(Log."Record No."));
                        Log.Modify(false);
                    end;
                end;
            until Log.Next() = 0;
    end;

    local procedure ReadRecordNo(Log: Record "obcfgav Validation Log"): Text
    var
        AddressSource: Codeunit "obcfgav Address Source";
        SourceRecRef: RecordRef;
        RecordNo: Text;
    begin
        if Log."Customer No." <> '' then
            exit(Log."Customer No.");

        if (Log."Source Table No." = 0) or IsNullGuid(Log."Source SystemId") then
            exit('');

        SourceRecRef.Open(Log."Source Table No.");
        if SourceRecRef.ReadPermission() then begin
            SourceRecRef.SetLoadFields(SourceRecRef.SystemIdNo());
            if SourceRecRef.GetBySystemId(Log."Source SystemId") then
                RecordNo := AddressSource.RecordKeyText(SourceRecRef);
        end;
        SourceRecRef.Close();
        exit(RecordNo);
    end;
}
