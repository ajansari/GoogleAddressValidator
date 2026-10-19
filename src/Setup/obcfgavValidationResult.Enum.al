namespace OnlyBCFans.GoogleAddress;

enum 92800 "obcfgav Validation Result"
{
    Extensible = false;
    Caption = 'Address Validation Result';

    value(0; " ")
    {
        Caption = ' ';
    }
    value(1; Confirmed)
    {
        Caption = 'Confirmed';
    }
    value(2; "Suggestion Accepted")
    {
        Caption = 'Suggestion Accepted';
    }
    value(3; "Suggestion Ignored")
    {
        Caption = 'Suggestion Ignored';
    }
    value(4; "Not Found")
    {
        Caption = 'Not Found';
    }
    value(5; Error)
    {
        Caption = 'Error';
    }
}
