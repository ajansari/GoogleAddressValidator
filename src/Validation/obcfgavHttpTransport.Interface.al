namespace OnlyBCFans.GoogleAddress;

interface "obcfgav Http Transport"
{
    /// <summary>
    /// Sends Request with the given timeout. Returns false when no HTTP response arrived (timeout, no connection, blocked by the environment); HttpStatus is 0 then.
    /// </summary>
    procedure Send(var Request: HttpRequestMessage; TimeoutMs: Integer; var HttpStatus: Integer; var ResponseBody: Text): Boolean;
}
