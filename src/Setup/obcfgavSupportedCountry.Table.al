namespace OnlyBCFans.GoogleAddress;

table 92803 "obcfgav Supported Country"
{
    Caption = 'Google Address Validation Supported Country';
    DataClassification = CustomerContent;
    LookupPageId = "obcfgav Supported Countries";
    DrillDownPageId = "obcfgav Supported Countries";

    fields
    {
        field(1; "Region Code"; Code[2])
        {
            Caption = 'Region Code';
            NotBlank = true;
        }
        field(2; Name; Text[50])
        {
            Caption = 'Name';
        }
        field(3; Enabled; Boolean)
        {
            Caption = 'Enabled';
            InitValue = true;
        }
        field(4; Preview; Boolean)
        {
            Caption = 'Preview';
        }
        field(5; "Residential Data"; Boolean)
        {
            Caption = 'Residential and Commercial Data';
        }
        field(6; "USPS Delivery Data"; Boolean)
        {
            Caption = 'USPS Delivery Data';
        }
    }

    keys
    {
        key(PK; "Region Code")
        {
            Clustered = true;
        }
    }
}
