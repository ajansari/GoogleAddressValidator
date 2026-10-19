namespace OnlyBCFans.GoogleAddress;

table 92802 "obcfgav Address Buffer"
{
    Caption = 'Address Buffer';
    DataClassification = CustomerContent;
    TableType = Temporary;

    fields
    {
        field(1; "Primary Key"; Integer)
        {
            Caption = 'Primary Key';
        }
        field(2; "Customer No."; Code[20])
        {
            Caption = 'Customer No.';
        }
        field(3; "Original Address"; Text[100])
        {
            Caption = 'Original Address';
        }
        field(4; "Original Address 2"; Text[50])
        {
            Caption = 'Original Address 2';
        }
        field(5; "Original City"; Text[30])
        {
            Caption = 'Original City';
        }
        field(6; "Original State"; Text[30])
        {
            Caption = 'Original State';
        }
        field(7; "Original ZIP Code"; Code[20])
        {
            Caption = 'Original ZIP Code';
        }
        field(8; "Suggested Address"; Text[250])
        {
            Caption = 'Suggested Address';
        }
        field(9; "Suggested Address 2"; Text[250])
        {
            Caption = 'Suggested Address 2';
        }
        field(10; "Suggested City"; Text[250])
        {
            Caption = 'Suggested City';
        }
        field(11; "Suggested State"; Text[250])
        {
            Caption = 'Suggested State';
        }
        field(12; "Suggested ZIP Code"; Text[250])
        {
            Caption = 'Suggested ZIP Code';
        }
        field(13; "DPV Confirmation"; Code[10])
        {
            Caption = 'DPV Confirmation';
        }
        field(14; Vacant; Boolean)
        {
            Caption = 'Vacant';
        }
        field(15; Business; Boolean)
        {
            Caption = 'Business';
        }
        field(16; "Validation Granularity"; Text[30])
        {
            Caption = 'Validation Granularity';
        }
        field(17; "Next Action"; Text[30])
        {
            Caption = 'Next Action';
        }
        field(18; "Provider Message"; Text[2048])
        {
            Caption = 'Provider Message';
        }
        field(19; "HTTP Status"; Integer)
        {
            Caption = 'HTTP Status';
        }
        field(20; "Not Found"; Boolean)
        {
            Caption = 'Not Found';
        }
        field(21; "User Message"; Text[2048])
        {
            Caption = 'User Message';
        }
        field(22; Provider; Enum "obcfgav Address Provider")
        {
            Caption = 'Provider';
        }
        field(23; "Address Complete"; Boolean)
        {
            Caption = 'Address Complete';
        }
        field(24; "Has Replaced"; Boolean)
        {
            Caption = 'Has Replaced';
        }
        field(25; "Has Inferred"; Boolean)
        {
            Caption = 'Has Inferred';
        }
        field(26; "Has Spell Corrected"; Boolean)
        {
            Caption = 'Has Spell Corrected';
        }
        field(27; "Has Unconfirmed"; Boolean)
        {
            Caption = 'Has Unconfirmed';
        }
        field(28; "PO Box"; Boolean)
        {
            Caption = 'PO Box';
        }
        field(29; "Missing Components"; Text[250])
        {
            Caption = 'Missing Components';
        }
        field(30; "Source Table No."; Integer)
        {
            Caption = 'Source Table No.';
        }
        field(31; "Address Type"; Enum "obcfgav Address Type")
        {
            Caption = 'Address Type';
        }
        field(32; "Source SystemId"; Guid)
        {
            Caption = 'Source SystemId';
        }
        field(33; "Source Description"; Text[250])
        {
            Caption = 'Source';
        }
        field(34; "Record No."; Text[100])
        {
            Caption = 'Record No.';
        }
        field(35; "Country/Region Code"; Code[10])
        {
            Caption = 'Country/Region Code';
        }
        field(36; "Region Code"; Code[2])
        {
            Caption = 'Region Code';
        }
        field(37; "Result Region Code"; Code[2])
        {
            Caption = 'Result Region Code';
        }
    }

    keys
    {
        key(PK; "Primary Key")
        {
            Clustered = true;
        }
    }
}
