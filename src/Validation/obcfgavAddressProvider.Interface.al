namespace OnlyBCFans.GoogleAddress;

interface "obcfgav Address Provider"
{
    /// <summary>
    /// Validates the original address in the buffer and fills the suggested values and outcome fields. Returns true when the address is validated; false when it is not found or the call failed (the buffer carries the user message).
    /// </summary>
    procedure ValidateAddress(var TempAddressBuffer: Record "obcfgav Address Buffer" temporary; Transport: Interface "obcfgav Http Transport"; TimeoutMs: Integer): Boolean;

    /// <summary>
    /// Checks that the saved credentials and the provider project are accepted. ErrorText is filled when the check fails.
    /// </summary>
    procedure TestConnection(Transport: Interface "obcfgav Http Transport"; TimeoutMs: Integer; var ErrorText: Text): Boolean;

    procedure HasCredentials(): Boolean;

    /// <summary>
    /// The provider name shown in attribution and messages.
    /// </summary>
    procedure DisplayName(): Text;
}
