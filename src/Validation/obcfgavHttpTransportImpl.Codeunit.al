namespace OnlyBCFans.GoogleAddress;

codeunit 92805 "obcfgav Http Transport Impl." implements "obcfgav Http Transport"
{
    Access = Public;

    [NonDebuggable]
    procedure Send(var Request: HttpRequestMessage; TimeoutMs: Integer; var HttpStatus: Integer; var ResponseBody: Text): Boolean
    var
        Client: HttpClient;
        Response: HttpResponseMessage;
    begin
        HttpStatus := 0;
        ResponseBody := '';
        Client.Timeout(TimeoutMs);
        if not Client.Send(Request, Response) then
            exit(false);
        HttpStatus := Response.HttpStatusCode();
        Response.Content().ReadAs(ResponseBody);
        exit(true);
    end;
}
