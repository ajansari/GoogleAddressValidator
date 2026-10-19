namespace OnlyBCFans.GoogleAddress;

permissionset 92800 "OBCFGAV GAV, USE"
{
    Assignable = true;
    Caption = 'Google Address Validator - Use';

    Permissions =
        tabledata "obcfgav Setup" = R,
        table "obcfgav Setup" = X,
        codeunit "obcfgav Credential Mgt." = X,
        tabledata "obcfgav Address Buffer" = RIMD,
        table "obcfgav Address Buffer" = X,
        codeunit "obcfgav Address Service" = X,
        codeunit "obcfgav Google Address Client" = X,
        codeunit "obcfgav Http Transport Impl." = X,
        tabledata "obcfgav Validation Log" = ri,
        table "obcfgav Validation Log" = X,
        page "obcfgav Log Entries" = X,
        page "obcfgav Address Compare" = X,
        codeunit "obcfgav Address Validation" = X,
        codeunit "obcfgav Validation Writer" = X,
        codeunit "obcfgav Setup Registration" = X,
        codeunit "obcfgav Address Source" = X,
        codeunit "obcfgav Write Guard" = X,
        codeunit "obcfgav Upgrade Tags" = X,
        codeunit "obcfgav Address Sync Subscr." = X,
        tabledata "obcfgav Supported Country" = R,
        table "obcfgav Supported Country" = X,
        page "obcfgav Supported Countries" = X,
        codeunit "obcfgav Country Mgt." = X;
}
