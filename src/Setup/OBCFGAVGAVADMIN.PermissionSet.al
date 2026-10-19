namespace OnlyBCFans.GoogleAddress;

permissionset 92801 "OBCFGAV GAV, ADMIN"
{
    Assignable = true;
    Caption = 'Google Address Validator Admin';
    IncludedPermissionSets = "OBCFGAV GAV, USE";

    Permissions =
        tabledata "obcfgav Setup" = RIMD,
        page "obcfgav Setup" = X,
        tabledata "obcfgav Validation Log" = RD,
        tabledata "obcfgav Supported Country" = RIMD,
        page "obcfgav Setup Wizard" = X,
        codeunit "obcfgav Setup Registration" = X;
}
