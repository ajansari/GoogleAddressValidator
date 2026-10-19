namespace OnlyBCFans.GoogleAddress;

using Microsoft.Bank.BankAccount;
using Microsoft.CRM.BusinessRelation;
using Microsoft.CRM.Contact;
using Microsoft.HumanResources.Employee;
using Microsoft.Projects.Resources.Resource;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;

codeunit 92813 "obcfgav Address Sync Subscr."
{
    Access = Internal;

    trigger OnRun()
    var
        SourceRecRef: RecordRef;
    begin
        if not AddressSource.OpenSource(SourceRecRef, SourceTableNo, SourceSystemId, AddressType, true) then
            exit;

        case SourceTableNo of
            Database::Customer:
                UpdateLinkedContactOfCustomer(SourceRecRef);
            Database::Vendor:
                UpdateLinkedContactOfVendor(SourceRecRef);
            Database::"Bank Account":
                UpdateLinkedContactOfBankAccount(SourceRecRef);
            Database::Employee:
                UpdateResourceOfEmployee(SourceRecRef);
        end;
    end;

    procedure Init(NewSourceTableNo: Integer; NewSourceSystemId: Guid; NewAddressType: Enum "obcfgav Address Type")
    begin
        SourceTableNo := NewSourceTableNo;
        SourceSystemId := NewSourceSystemId;
        AddressType := NewAddressType;
    end;

    local procedure UpdateLinkedContactOfCustomer(var SourceRecRef: RecordRef)
    var
        Customer: Record Customer;
        Contact: Record Contact;
        CustContUpdate: Codeunit "CustCont-Update";
    begin
        if not Contact.WritePermission() then
            exit;
        SourceRecRef.SetTable(Customer);
        if not LinkedContactFlagDiffers(Enum::"Contact Business Relation Link To Table"::Customer, Customer."No.", Customer."obcfgav Address Validated") then
            exit;
        BindSubscription(WriteGuard);
        CustContUpdate.OnModify(Customer);
        UnbindSubscription(WriteGuard);
    end;

    local procedure UpdateLinkedContactOfVendor(var SourceRecRef: RecordRef)
    var
        Vendor: Record Vendor;
        Contact: Record Contact;
        VendContUpdate: Codeunit "VendCont-Update";
    begin
        if not Contact.WritePermission() then
            exit;
        SourceRecRef.SetTable(Vendor);
        if not LinkedContactFlagDiffers(Enum::"Contact Business Relation Link To Table"::Vendor, Vendor."No.", Vendor."obcfgav Address Validated") then
            exit;
        BindSubscription(WriteGuard);
        VendContUpdate.OnModify(Vendor);
        UnbindSubscription(WriteGuard);
    end;

    local procedure UpdateLinkedContactOfBankAccount(var SourceRecRef: RecordRef)
    var
        BankAccount: Record "Bank Account";
        Contact: Record Contact;
        BankContUpdate: Codeunit "BankCont-Update";
    begin
        if not Contact.WritePermission() then
            exit;
        SourceRecRef.SetTable(BankAccount);
        if not LinkedContactFlagDiffers(Enum::"Contact Business Relation Link To Table"::"Bank Account", BankAccount."No.", BankAccount."obcfgav Address Validated") then
            exit;
        BindSubscription(WriteGuard);
        BankContUpdate.OnModify(BankAccount);
        UnbindSubscription(WriteGuard);
    end;

    local procedure UpdateResourceOfEmployee(var SourceRecRef: RecordRef)
    var
        Employee: Record Employee;
        OldEmployee: Record Employee;
        Resource: Record Resource;
        EmployeeResourceUpdate: Codeunit "Employee/Resource Update";
    begin
        if not Resource.ReadPermission() then
            exit;
        SourceRecRef.SetTable(Employee);
        if Employee."Resource No." = '' then
            exit;
        Resource.SetLoadFields("obcfgav Address Validated");
        if Resource.Get(Employee."Resource No.") then
            if Resource."obcfgav Address Validated" = Employee."obcfgav Address Validated" then
                exit;
        OldEmployee := Employee;
        OldEmployee."obcfgav Address Validated" := not Employee."obcfgav Address Validated";
        EmployeeResourceUpdate.HumanResToRes(OldEmployee, Employee);
    end;

    [EventSubscriber(ObjectType::Table, Database::Contact, 'OnBeforeIsUpdateNeeded', '', false, false)]
    local procedure ContactFlagChangeCountsAsUpdate(var Contact: Record Contact; xContact: Record Contact; var UpdateNeeded: Boolean)
    begin
        if Contact."obcfgav Address Validated" <> xContact."obcfgav Address Validated" then
            UpdateNeeded := true;
    end;

    [EventSubscriber(ObjectType::Table, Database::Contact, 'OnAfterSyncAddress', '', false, false)]
    local procedure FlagFollowsCompanyAddressToPersons(var Contact: Record Contact; RecContact: Record Contact; var ContChanged: Boolean; var ContactBeforeModify: Record Contact)
    begin
        if not SameContactAddress(Contact, RecContact) then
            exit;
        if Contact."obcfgav Address Validated" = RecContact."obcfgav Address Validated" then
            exit;
        if SameContactAddress(ContactBeforeModify, RecContact) and
           (ContactBeforeModify."obcfgav Address Validated" = RecContact."obcfgav Address Validated")
        then
            exit;

        Contact."obcfgav Address Validated" := RecContact."obcfgav Address Validated";
        ContChanged := true;
    end;

    [EventSubscriber(ObjectType::Table, Database::Contact, 'OnAfterInheritCompanyToPersonData', '', false, false)]
    local procedure PersonTakesCompanyFlag(var Contact: Record Contact; xContact: Record Contact; NewCompanyContact: Record Contact)
    begin
        if SameContactAddress(Contact, NewCompanyContact) then
            Contact."obcfgav Address Validated" := NewCompanyContact."obcfgav Address Validated";
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"CustVendBank-Update", 'OnAfterUpdateEmployee', '', false, false)]
    local procedure EmployeeTakesContactFlag(var Employee: Record Employee; Contact: Record Contact)
    var
        OldEmployee: Record Employee;
        Resource: Record Resource;
        EmployeeResourceUpdate: Codeunit "Employee/Resource Update";
    begin
        if Employee."No." = '' then
            exit;
        if not SameEmployeeAddress(Employee, Contact) then
            exit;
        if Employee."obcfgav Address Validated" = Contact."obcfgav Address Validated" then
            exit;

        OldEmployee := Employee;
        Employee."obcfgav Address Validated" := Contact."obcfgav Address Validated";
        Employee.Modify(false);
        if Resource.ReadPermission() then
            EmployeeResourceUpdate.HumanResToRes(OldEmployee, Employee);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Employee/Resource Update", 'OnAfterUpdateResource', '', false, false)]
    local procedure ResourceTakesEmployeeFlag(var Resource: Record Resource; Employee: Record Employee)
    begin
        if (Resource.Address = Employee.Address) and
           (Resource."Address 2" = Employee."Address 2") and
           (Resource.City = Employee.City) and
           (Resource.County = Employee.County) and
           (Resource."Post Code" = Employee."Post Code") and
           (Resource."Country/Region Code" = Employee."Country/Region Code")
        then
            Resource."obcfgav Address Validated" := Employee."obcfgav Address Validated";
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Employee/Resource Update", 'OnAfterCalculateResourceUpdateNeeded', '', false, false)]
    local procedure EmployeeFlagChangeCountsAsUpdate(Employee: Record Employee; xEmployee: Record Employee; var UpdateNeeded: Boolean)
    begin
        if Employee."obcfgav Address Validated" <> xEmployee."obcfgav Address Validated" then
            UpdateNeeded := true;
    end;

    local procedure LinkedContactFlagDiffers(LinkToTable: Enum "Contact Business Relation Link To Table"; No: Code[20]; Flag: Boolean): Boolean
    var
        ContactBusinessRelation: Record "Contact Business Relation";
        Contact: Record Contact;
    begin
        ContactBusinessRelation.SetCurrentKey("Link to Table", "No.");
        ContactBusinessRelation.SetRange("Link to Table", LinkToTable);
        ContactBusinessRelation.SetRange("No.", No);
        if not ContactBusinessRelation.FindFirst() then
            exit(false);
        Contact.SetLoadFields("obcfgav Address Validated");
        if not Contact.Get(ContactBusinessRelation."Contact No.") then
            exit(false);
        exit(Contact."obcfgav Address Validated" <> Flag);
    end;

    local procedure SameContactAddress(Contact: Record Contact; OtherContact: Record Contact): Boolean
    begin
        exit(
            (Contact.Address = OtherContact.Address) and
            (Contact."Address 2" = OtherContact."Address 2") and
            (Contact.City = OtherContact.City) and
            (Contact.County = OtherContact.County) and
            (Contact."Post Code" = OtherContact."Post Code") and
            (Contact."Country/Region Code" = OtherContact."Country/Region Code"));
    end;

    local procedure SameEmployeeAddress(Employee: Record Employee; Contact: Record Contact): Boolean
    begin
        exit(
            (Employee.Address = Contact.Address) and
            (Employee."Address 2" = Contact."Address 2") and
            (Employee.City = Contact.City) and
            (Employee.County = Contact.County) and
            (Employee."Post Code" = Contact."Post Code") and
            (Employee."Country/Region Code" = Contact."Country/Region Code"));
    end;

    var
        AddressSource: Codeunit "obcfgav Address Source";
        WriteGuard: Codeunit "obcfgav Write Guard";
        SourceSystemId: Guid;
        SourceTableNo: Integer;
        AddressType: Enum "obcfgav Address Type";
}
