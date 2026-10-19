namespace OnlyBCFans.GoogleAddress;

using Microsoft.Foundation.Address;

table 92800 "obcfgav Setup"
{
    Caption = 'Google Address Validation Setup';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Primary Key"; Code[10])
        {
            Caption = 'Primary Key';
        }
        field(2; Enabled; Boolean)
        {
            Caption = 'Enabled';
            InitValue = false;
        }
        field(3; Provider; Enum "obcfgav Address Provider")
        {
            Caption = 'Provider';
            InitValue = Google;
        }
        field(4; "US Country/Region Code"; Code[10])
        {
            Caption = 'Default Country/Region Code';
            TableRelation = "Country/Region";
        }
        field(6; "Blank Country Handling"; Enum "obcfgav Blank Country Handling")
        {
            Caption = 'Blank Country Handling';
            InitValue = "Let Google decide";
        }
        field(5; "Timeout (Seconds)"; Integer)
        {
            Caption = 'Timeout (Seconds)';
            InitValue = 10;
            MinValue = 1;
            MaxValue = 60;
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
