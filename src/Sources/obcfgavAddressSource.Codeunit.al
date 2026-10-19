namespace OnlyBCFans.GoogleAddress;

using Microsoft.Bank.BankAccount;
using Microsoft.CRM.BusinessRelation;
using Microsoft.CRM.Contact;
using Microsoft.Foundation.Company;
using Microsoft.HumanResources.Employee;
using Microsoft.Inventory.Location;
using Microsoft.Projects.Resources.Resource;
using Microsoft.Purchases.Remittance;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;

codeunit 92809 "obcfgav Address Source"
{
    Access = Internal;

    procedure ValidatedFieldNo(): Integer
    begin
        exit(92800);
    end;

    procedure ShipToValidatedFieldNo(): Integer
    begin
        exit(92801);
    end;

    procedure GetMap(SourceTableNo: Integer; AddressType: Enum "obcfgav Address Type"; var Map: array[7] of Integer): Boolean
    var
        Customer: Record Customer;
        ShipToAddress: Record "Ship-to Address";
        CustomerBankAccount: Record "Customer Bank Account";
        Vendor: Record Vendor;
        OrderAddress: Record "Order Address";
        RemitAddress: Record "Remit Address";
        VendorBankAccount: Record "Vendor Bank Account";
        CompanyInformation: Record "Company Information";
        Location: Record Location;
        ResponsibilityCenter: Record "Responsibility Center";
        BankAccount: Record "Bank Account";
        Employee: Record Employee;
        AlternativeAddress: Record "Alternative Address";
        Contact: Record Contact;
        ContactAltAddress: Record "Contact Alt. Address";
        Resource: Record Resource;
    begin
        Clear(Map);

        if AddressType = Enum::"obcfgav Address Type"::"Ship-to" then begin
            if SourceTableNo <> Database::"Company Information" then
                exit(false);
            SetMap(Map, CompanyInformation.FieldNo("Ship-to Address"), CompanyInformation.FieldNo("Ship-to Address 2"), CompanyInformation.FieldNo("Ship-to City"), CompanyInformation.FieldNo("Ship-to County"), CompanyInformation.FieldNo("Ship-to Post Code"), CompanyInformation.FieldNo("Ship-to Country/Region Code"), ShipToValidatedFieldNo());
            exit(true);
        end;

        case SourceTableNo of
            Database::Customer:
                SetMap(Map, Customer.FieldNo(Address), Customer.FieldNo("Address 2"), Customer.FieldNo(City), Customer.FieldNo(County), Customer.FieldNo("Post Code"), Customer.FieldNo("Country/Region Code"), ValidatedFieldNo());
            Database::"Ship-to Address":
                SetMap(Map, ShipToAddress.FieldNo(Address), ShipToAddress.FieldNo("Address 2"), ShipToAddress.FieldNo(City), ShipToAddress.FieldNo(County), ShipToAddress.FieldNo("Post Code"), ShipToAddress.FieldNo("Country/Region Code"), ValidatedFieldNo());
            Database::"Customer Bank Account":
                SetMap(Map, CustomerBankAccount.FieldNo(Address), CustomerBankAccount.FieldNo("Address 2"), CustomerBankAccount.FieldNo(City), CustomerBankAccount.FieldNo(County), CustomerBankAccount.FieldNo("Post Code"), CustomerBankAccount.FieldNo("Country/Region Code"), ValidatedFieldNo());
            Database::Vendor:
                SetMap(Map, Vendor.FieldNo(Address), Vendor.FieldNo("Address 2"), Vendor.FieldNo(City), Vendor.FieldNo(County), Vendor.FieldNo("Post Code"), Vendor.FieldNo("Country/Region Code"), ValidatedFieldNo());
            Database::"Order Address":
                SetMap(Map, OrderAddress.FieldNo(Address), OrderAddress.FieldNo("Address 2"), OrderAddress.FieldNo(City), OrderAddress.FieldNo(County), OrderAddress.FieldNo("Post Code"), OrderAddress.FieldNo("Country/Region Code"), ValidatedFieldNo());
            Database::"Remit Address":
                SetMap(Map, RemitAddress.FieldNo(Address), RemitAddress.FieldNo("Address 2"), RemitAddress.FieldNo(City), RemitAddress.FieldNo(County), RemitAddress.FieldNo("Post Code"), RemitAddress.FieldNo("Country/Region Code"), ValidatedFieldNo());
            Database::"Vendor Bank Account":
                SetMap(Map, VendorBankAccount.FieldNo(Address), VendorBankAccount.FieldNo("Address 2"), VendorBankAccount.FieldNo(City), VendorBankAccount.FieldNo(County), VendorBankAccount.FieldNo("Post Code"), VendorBankAccount.FieldNo("Country/Region Code"), ValidatedFieldNo());
            Database::"Company Information":
                SetMap(Map, CompanyInformation.FieldNo(Address), CompanyInformation.FieldNo("Address 2"), CompanyInformation.FieldNo(City), CompanyInformation.FieldNo(County), CompanyInformation.FieldNo("Post Code"), CompanyInformation.FieldNo("Country/Region Code"), ValidatedFieldNo());
            Database::Location:
                SetMap(Map, Location.FieldNo(Address), Location.FieldNo("Address 2"), Location.FieldNo(City), Location.FieldNo(County), Location.FieldNo("Post Code"), Location.FieldNo("Country/Region Code"), ValidatedFieldNo());
            Database::"Responsibility Center":
                SetMap(Map, ResponsibilityCenter.FieldNo(Address), ResponsibilityCenter.FieldNo("Address 2"), ResponsibilityCenter.FieldNo(City), ResponsibilityCenter.FieldNo(County), ResponsibilityCenter.FieldNo("Post Code"), ResponsibilityCenter.FieldNo("Country/Region Code"), ValidatedFieldNo());
            Database::"Bank Account":
                SetMap(Map, BankAccount.FieldNo(Address), BankAccount.FieldNo("Address 2"), BankAccount.FieldNo(City), BankAccount.FieldNo(County), BankAccount.FieldNo("Post Code"), BankAccount.FieldNo("Country/Region Code"), ValidatedFieldNo());
            Database::Employee:
                SetMap(Map, Employee.FieldNo(Address), Employee.FieldNo("Address 2"), Employee.FieldNo(City), Employee.FieldNo(County), Employee.FieldNo("Post Code"), Employee.FieldNo("Country/Region Code"), ValidatedFieldNo());
            Database::"Alternative Address":
                SetMap(Map, AlternativeAddress.FieldNo(Address), AlternativeAddress.FieldNo("Address 2"), AlternativeAddress.FieldNo(City), AlternativeAddress.FieldNo(County), AlternativeAddress.FieldNo("Post Code"), AlternativeAddress.FieldNo("Country/Region Code"), ValidatedFieldNo());
            Database::Contact:
                SetMap(Map, Contact.FieldNo(Address), Contact.FieldNo("Address 2"), Contact.FieldNo(City), Contact.FieldNo(County), Contact.FieldNo("Post Code"), Contact.FieldNo("Country/Region Code"), ValidatedFieldNo());
            Database::"Contact Alt. Address":
                SetMap(Map, ContactAltAddress.FieldNo(Address), ContactAltAddress.FieldNo("Address 2"), ContactAltAddress.FieldNo(City), ContactAltAddress.FieldNo(County), ContactAltAddress.FieldNo("Post Code"), ContactAltAddress.FieldNo("Country/Region Code"), ValidatedFieldNo());
            Database::Resource:
                SetMap(Map, Resource.FieldNo(Address), Resource.FieldNo("Address 2"), Resource.FieldNo(City), Resource.FieldNo(County), Resource.FieldNo("Post Code"), Resource.FieldNo("Country/Region Code"), ValidatedFieldNo());
            else
                exit(false);
        end;
        exit(true);
    end;

    procedure IsSupported(SourceTableNo: Integer; AddressType: Enum "obcfgav Address Type"): Boolean
    var
        SourceRecRef: RecordRef;
        Map: array[7] of Integer;
        Supported: Boolean;
    begin
        if not GetMap(SourceTableNo, AddressType, Map) then
            exit(false);
        SourceRecRef.Open(SourceTableNo);
        Supported := SourceRecRef.FieldExist(Map[7]);
        SourceRecRef.Close();
        exit(Supported);
    end;

    procedure ReadableSourceFilter(): Text
    var
        SourceRecRef: RecordRef;
        Candidates: List of [Integer];
        TableNo: Integer;
        FilterText: Text;
    begin
        Candidates.Add(Database::Customer);
        Candidates.Add(Database::"Ship-to Address");
        Candidates.Add(Database::"Customer Bank Account");
        Candidates.Add(Database::Vendor);
        Candidates.Add(Database::"Order Address");
        Candidates.Add(Database::"Remit Address");
        Candidates.Add(Database::"Vendor Bank Account");
        Candidates.Add(Database::"Company Information");
        Candidates.Add(Database::Location);
        Candidates.Add(Database::"Responsibility Center");
        Candidates.Add(Database::"Bank Account");
        Candidates.Add(Database::Employee);
        Candidates.Add(Database::"Alternative Address");
        Candidates.Add(Database::Contact);
        Candidates.Add(Database::"Contact Alt. Address");
        Candidates.Add(Database::Resource);
        foreach TableNo in Candidates do begin
            SourceRecRef.Open(TableNo);
            if SourceRecRef.ReadPermission() then begin
                if FilterText <> '' then
                    FilterText += '|';
                FilterText += Format(TableNo, 0, 9);
            end;
            SourceRecRef.Close();
        end;
        if FilterText = '' then
            exit('0');
        exit(FilterText);
    end;

    procedure OpenSource(var SourceRecRef: RecordRef; SourceTableNo: Integer; SourceSystemId: Guid; AddressType: Enum "obcfgav Address Type"; ForUpdate: Boolean): Boolean
    var
        Map: array[7] of Integer;
        PrivacyFieldNo: Integer;
    begin
        if not GetMap(SourceTableNo, AddressType, Map) then
            exit(false);

        SourceRecRef.Open(SourceTableNo);
        if ForUpdate then
            SourceRecRef.LockTable()
        else begin
            SourceRecRef.SetLoadFields(Map[1], Map[2], Map[3], Map[4], Map[5], Map[6], Map[7]);
            PrivacyFieldNo := PrivacyBlockedFieldNo(SourceTableNo);
            if PrivacyFieldNo <> 0 then
                SourceRecRef.AddLoadFields(PrivacyFieldNo);
        end;
        exit(SourceRecRef.GetBySystemId(SourceSystemId));
    end;

    procedure GetValue(var SourceRecRef: RecordRef; AddressType: Enum "obcfgav Address Type"; Index: Integer): Text
    var
        SourceField: FieldRef;
        Map: array[7] of Integer;
    begin
        GetMap(SourceRecRef.Number, AddressType, Map);
        SourceField := SourceRecRef.Field(Map[Index]);
        exit(Format(SourceField.Value));
    end;

    procedure GetLength(var SourceRecRef: RecordRef; AddressType: Enum "obcfgav Address Type"; Index: Integer): Integer
    var
        SourceField: FieldRef;
        Map: array[7] of Integer;
    begin
        GetMap(SourceRecRef.Number, AddressType, Map);
        SourceField := SourceRecRef.Field(Map[Index]);
        exit(SourceField.Length);
    end;

    procedure FillOriginal(var SourceRecRef: RecordRef; AddressType: Enum "obcfgav Address Type"; var TempAddressBuffer: Record "obcfgav Address Buffer" temporary)
    var
        Customer: Record Customer;
        SystemIdField: FieldRef;
        CustomerNoField: FieldRef;
        SystemIdValue: Guid;
    begin
        TempAddressBuffer.Init();
        TempAddressBuffer."Source Table No." := SourceRecRef.Number;
        TempAddressBuffer."Address Type" := AddressType;
        SystemIdField := SourceRecRef.Field(SourceRecRef.SystemIdNo);
        SystemIdValue := SystemIdField.Value;
        TempAddressBuffer."Source SystemId" := SystemIdValue;
        TempAddressBuffer."Source Description" := Describe(SourceRecRef, AddressType);
        TempAddressBuffer."Record No." := RecordKeyText(SourceRecRef);
        TempAddressBuffer."Country/Region Code" := CopyStr(GetValue(SourceRecRef, AddressType, 6), 1, MaxStrLen(TempAddressBuffer."Country/Region Code"));
        if SourceRecRef.Number = Database::Customer then begin
            CustomerNoField := SourceRecRef.Field(Customer.FieldNo("No."));
            TempAddressBuffer."Customer No." := CopyStr(Format(CustomerNoField.Value), 1, MaxStrLen(TempAddressBuffer."Customer No."));
        end;
        TempAddressBuffer."Original Address" := CopyStr(GetValue(SourceRecRef, AddressType, 1), 1, MaxStrLen(TempAddressBuffer."Original Address"));
        TempAddressBuffer."Original Address 2" := CopyStr(GetValue(SourceRecRef, AddressType, 2), 1, MaxStrLen(TempAddressBuffer."Original Address 2"));
        TempAddressBuffer."Original City" := CopyStr(GetValue(SourceRecRef, AddressType, 3), 1, MaxStrLen(TempAddressBuffer."Original City"));
        TempAddressBuffer."Original State" := CopyStr(GetValue(SourceRecRef, AddressType, 4), 1, MaxStrLen(TempAddressBuffer."Original State"));
        TempAddressBuffer."Original ZIP Code" := CopyStr(GetValue(SourceRecRef, AddressType, 5), 1, MaxStrLen(TempAddressBuffer."Original ZIP Code"));
    end;

    procedure DiffersFromSnapshot(var SourceRecRef: RecordRef; AddressType: Enum "obcfgav Address Type"; TempAddressBuffer: Record "obcfgav Address Buffer" temporary): Boolean
    begin
        exit(
            (GetValue(SourceRecRef, AddressType, 1) <> TempAddressBuffer."Original Address") or
            (GetValue(SourceRecRef, AddressType, 2) <> TempAddressBuffer."Original Address 2") or
            (GetValue(SourceRecRef, AddressType, 3) <> TempAddressBuffer."Original City") or
            (GetValue(SourceRecRef, AddressType, 4) <> TempAddressBuffer."Original State") or
            (GetValue(SourceRecRef, AddressType, 5) <> TempAddressBuffer."Original ZIP Code"));
    end;

    procedure AssignSuggested(var SourceRecRef: RecordRef; AddressType: Enum "obcfgav Address Type"; TempAddressBuffer: Record "obcfgav Address Buffer" temporary)
    begin
        AssignText(SourceRecRef, AddressType, 1, TempAddressBuffer."Suggested Address");
        AssignText(SourceRecRef, AddressType, 2, TempAddressBuffer."Suggested Address 2");
        AssignText(SourceRecRef, AddressType, 3, TempAddressBuffer."Suggested City");
        AssignText(SourceRecRef, AddressType, 4, TempAddressBuffer."Suggested State");
        AssignText(SourceRecRef, AddressType, 5, TempAddressBuffer."Suggested ZIP Code");
        SetCountryIfBlank(SourceRecRef, AddressType, TempAddressBuffer);
        SetValidated(SourceRecRef, AddressType, true);
    end;

    procedure SetCountryIfBlank(var SourceRecRef: RecordRef; AddressType: Enum "obcfgav Address Type"; TempAddressBuffer: Record "obcfgav Address Buffer" temporary): Boolean
    var
        CountryMgt: Codeunit "obcfgav Country Mgt.";
        Region: Code[2];
        CountryCode: Code[10];
    begin
        if GetValue(SourceRecRef, AddressType, 6) <> '' then
            exit(false);
        Region := TempAddressBuffer."Result Region Code";
        if Region = '' then
            Region := TempAddressBuffer."Region Code";
        CountryCode := CountryMgt.BCCodeForRegion(Region);
        if (CountryCode = '') and (TempAddressBuffer."Region Code" <> '') then
            CountryCode := CountryMgt.BCCodeForRegion(TempAddressBuffer."Region Code");
        if CountryCode = '' then
            exit(false);
        AssignText(SourceRecRef, AddressType, 6, CountryCode);
        exit(true);
    end;

    procedure GetValidated(var SourceRecRef: RecordRef; AddressType: Enum "obcfgav Address Type"): Boolean
    var
        ValidatedField: FieldRef;
        Map: array[7] of Integer;
        Validated: Boolean;
    begin
        GetMap(SourceRecRef.Number, AddressType, Map);
        ValidatedField := SourceRecRef.Field(Map[7]);
        Validated := ValidatedField.Value;
        exit(Validated);
    end;

    procedure SetValidated(var SourceRecRef: RecordRef; AddressType: Enum "obcfgav Address Type"; NewValue: Boolean)
    var
        ValidatedField: FieldRef;
        Map: array[7] of Integer;
    begin
        GetMap(SourceRecRef.Number, AddressType, Map);
        ValidatedField := SourceRecRef.Field(Map[7]);
        ValidatedField.Value := NewValue;
    end;

    procedure SaveSource(var SourceRecRef: RecordRef; AddressWritten: Boolean)
    var
        Customer: Record Customer;
        Vendor: Record Vendor;
        BankAccount: Record "Bank Account";
        Employee: Record Employee;
        OldEmployee: Record Employee;
        Resource: Record Resource;
        BankContUpdate: Codeunit "BankCont-Update";
        EmployeeResourceUpdate: Codeunit "Employee/Resource Update";
    begin
        case SourceRecRef.Number of
            Database::Customer:
                if AddressWritten then begin
                    SourceRecRef.SetTable(Customer);
                    Customer.SetForceUpdateContact(true);
                    Customer.Modify(true);
                    exit;
                end;
            Database::Vendor:
                if AddressWritten then begin
                    SourceRecRef.SetTable(Vendor);
                    Vendor.SetForceUpdateContact(true);
                    Vendor.Modify(true);
                    exit;
                end;
            Database::"Bank Account":
                begin
                    SourceRecRef.Modify(true);
                    if AddressWritten then begin
                        SourceRecRef.SetTable(BankAccount);
                        BankContUpdate.OnModify(BankAccount);
                    end;
                    exit;
                end;
            Database::Employee:
                if AddressWritten then begin
                    SourceRecRef.SetTable(Employee);
                    OldEmployee.GetBySystemId(Employee.SystemId);
                    SourceRecRef.Modify(true);
                    if Resource.ReadPermission() then
                        EmployeeResourceUpdate.HumanResToRes(OldEmployee, Employee);
                    exit;
                end;
        end;
        SourceRecRef.Modify(true);
    end;

    procedure RecordKeyText(var SourceRecRef: RecordRef): Text[100]
    begin
        exit(CopyStr(JoinKeyParts(SourceRecRef, KeyPartSeparatorTok), 1, 100));
    end;

    local procedure JoinKeyParts(var SourceRecRef: RecordRef; Separator: Text): Text
    var
        KeyField: FieldRef;
        SourceKey: KeyRef;
        KeyText: Text;
        KeyPart: Text;
        Index: Integer;
    begin
        SourceKey := SourceRecRef.KeyIndex(1);
        for Index := 1 to SourceKey.FieldCount() do begin
            KeyField := SourceKey.FieldIndex(Index);
            KeyPart := Format(KeyField.Value);
            if KeyPart <> '' then begin
                if KeyText <> '' then
                    KeyText += Separator;
                KeyText += KeyPart;
            end;
        end;
        exit(KeyText);
    end;

    procedure Describe(var SourceRecRef: RecordRef; AddressType: Enum "obcfgav Address Type"): Text[250]
    var
        KeyText: Text;
        Description: Text;
    begin
        KeyText := JoinKeyParts(SourceRecRef, ' ');
        if KeyText <> '' then
            KeyText := ' ' + KeyText;
        Description := StrSubstNo(DescriptionTok, SourceRecRef.Caption, KeyText);
        if AddressType = Enum::"obcfgav Address Type"::"Ship-to" then
            Description := StrSubstNo(BlockDescriptionTok, Description, Format(AddressType));
        exit(CopyStr(Description, 1, 250));
    end;

    procedure IsPrivacyBlocked(var SourceRecRef: RecordRef): Boolean
    var
        ShipToAddress: Record "Ship-to Address";
        CustomerBankAccount: Record "Customer Bank Account";
        OrderAddress: Record "Order Address";
        RemitAddress: Record "Remit Address";
        VendorBankAccount: Record "Vendor Bank Account";
        AlternativeAddress: Record "Alternative Address";
        ContactAltAddress: Record "Contact Alt. Address";
    begin
        if IsTrue(SourceRecRef, PrivacyBlockedFieldNo(SourceRecRef.Number)) then
            exit(true);

        case SourceRecRef.Number of
            Database::"Ship-to Address":
                exit(IsParentBlocked(Database::Customer, GetCode(SourceRecRef, ShipToAddress.FieldNo("Customer No."))));
            Database::"Customer Bank Account":
                exit(IsParentBlocked(Database::Customer, GetCode(SourceRecRef, CustomerBankAccount.FieldNo("Customer No."))));
            Database::"Order Address":
                exit(IsParentBlocked(Database::Vendor, GetCode(SourceRecRef, OrderAddress.FieldNo("Vendor No."))));
            Database::"Remit Address":
                exit(IsParentBlocked(Database::Vendor, GetCode(SourceRecRef, RemitAddress.FieldNo("Vendor No."))));
            Database::"Vendor Bank Account":
                exit(IsParentBlocked(Database::Vendor, GetCode(SourceRecRef, VendorBankAccount.FieldNo("Vendor No."))));
            Database::"Alternative Address":
                exit(IsParentBlocked(Database::Employee, GetCode(SourceRecRef, AlternativeAddress.FieldNo("Employee No."))));
            Database::"Contact Alt. Address":
                exit(IsParentBlocked(Database::Contact, GetCode(SourceRecRef, ContactAltAddress.FieldNo("Contact No."))));
        end;
        exit(false);
    end;

    local procedure SetMap(var Map: array[7] of Integer; AddressNo: Integer; Address2No: Integer; CityNo: Integer; CountyNo: Integer; PostCodeNo: Integer; CountryNo: Integer; ValidatedNo: Integer)
    begin
        Map[1] := AddressNo;
        Map[2] := Address2No;
        Map[3] := CityNo;
        Map[4] := CountyNo;
        Map[5] := PostCodeNo;
        Map[6] := CountryNo;
        Map[7] := ValidatedNo;
    end;

    local procedure AssignText(var SourceRecRef: RecordRef; AddressType: Enum "obcfgav Address Type"; Index: Integer; NewValue: Text)
    var
        TargetField: FieldRef;
        Map: array[7] of Integer;
    begin
        GetMap(SourceRecRef.Number, AddressType, Map);
        TargetField := SourceRecRef.Field(Map[Index]);
        TargetField.Value := CopyStr(NewValue, 1, TargetField.Length);
    end;

    local procedure PrivacyBlockedFieldNo(SourceTableNo: Integer): Integer
    var
        Customer: Record Customer;
        Vendor: Record Vendor;
        Contact: Record Contact;
        Employee: Record Employee;
        Resource: Record Resource;
    begin
        case SourceTableNo of
            Database::Customer:
                exit(Customer.FieldNo("Privacy Blocked"));
            Database::Vendor:
                exit(Vendor.FieldNo("Privacy Blocked"));
            Database::Contact:
                exit(Contact.FieldNo("Privacy Blocked"));
            Database::Employee:
                exit(Employee.FieldNo("Privacy Blocked"));
            Database::Resource:
                exit(Resource.FieldNo("Privacy Blocked"));
        end;
        exit(0);
    end;

    local procedure IsTrue(var SourceRecRef: RecordRef; FieldNo: Integer): Boolean
    var
        TestedField: FieldRef;
        Result: Boolean;
    begin
        if FieldNo = 0 then
            exit(false);
        TestedField := SourceRecRef.Field(FieldNo);
        Result := TestedField.Value;
        exit(Result);
    end;

    local procedure GetCode(var SourceRecRef: RecordRef; FieldNo: Integer): Code[20]
    var
        CodeField: FieldRef;
    begin
        CodeField := SourceRecRef.Field(FieldNo);
        exit(CopyStr(Format(CodeField.Value), 1, 20));
    end;

    local procedure IsParentBlocked(ParentTableNo: Integer; ParentNo: Code[20]): Boolean
    var
        ParentRecRef: RecordRef;
        NoField: FieldRef;
        Blocked: Boolean;
    begin
        if ParentNo = '' then
            exit(false);
        ParentRecRef.Open(ParentTableNo);
        ParentRecRef.SetLoadFields(PrivacyBlockedFieldNo(ParentTableNo));
        NoField := ParentRecRef.Field(1);
        NoField.SetRange(ParentNo);
        if ParentRecRef.FindFirst() then
            Blocked := IsTrue(ParentRecRef, PrivacyBlockedFieldNo(ParentTableNo));
        ParentRecRef.Close();
        exit(Blocked);
    end;

    var
        DescriptionTok: Label '%1%2', Locked = true, Comment = '%1 = table caption, %2 = key values each preceded by a space';
        KeyPartSeparatorTok: Label ' / ', Locked = true;
        BlockDescriptionTok: Label '%1 (%2)', Locked = true, Comment = '%1 = description, %2 = address type';
}
