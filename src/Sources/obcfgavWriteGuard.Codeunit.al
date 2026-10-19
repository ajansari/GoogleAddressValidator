namespace OnlyBCFans.GoogleAddress;

using Microsoft.CRM.Contact;

codeunit 92808 "obcfgav Write Guard"
{
    Access = Internal;
    EventSubscriberInstance = Manual;

    [EventSubscriber(ObjectType::Table, Database::Contact, 'OnBeforeLaunchDuplicateForm', '', false, false)]
    local procedure SuppressDuplicateForm(var Contact: Record Contact; var IsHandled: Boolean)
    begin
        IsHandled := true;
    end;
}
