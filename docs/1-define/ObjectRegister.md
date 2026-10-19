# Object Register — Google Address Validator

Maintained as objects are planned and built. Never use an ID outside the allocated ranges.

**Allocated ranges (from 1.3.0.0, AJ Ansari 2026-10-19):** main app **92800–92829**, test app **92830–92849**. Every ID is allocated **per object type** (Standards §5.0, Ops § Object IDs): the first object of each type takes 92800 (test app 92830), the next the following number, with no gaps. Until 1.2.x the apps used 60093–60192 (main) and 60123–60133 (test) with one shared number space; the **Was** column gives every object's pre-1.3 ID so older documents and the ChangeLog can be read. Field numbers on the standard tables the app extends are 92800 (Address Validated, on 16 tables) and 92801 (Ship-to Validated, Company Information only); they were 60093 and 60094.

**Allocation check (run 2026-10-19, main app):** table 92800–92803 (4), page 92800–92804 (5), codeunit 92800–92816 (17), enum 92800–92803 (4), permission set 92800–92801 (2), table extension 92800–92815 (16), page extension 92800–92815 (16); no gaps, every type starts at 92800. Test app: codeunit 92830–92838 (9). Two interfaces (`obcfgav Http Transport`, `obcfgav Address Provider`) take no ID. Unallocated per type: 30 minus the count above in the main app (at least 13 per type), 20 minus 9 for test codeunits.

Status: **built and compiled 0 errors / 0 warnings** (main app 1.3.0.0, test app 0.0.0.24, 2026-10-19); not yet installed in a tenant after the renumbering.

## Main app

### Tables

| ID | Name | Was | File |
|---|---|---|---|
| 92800 | obcfgav Setup | 60095 | `src/Setup/obcfgavSetup.Table.al` |
| 92801 | obcfgav Validation Log | 60109 | `src/Validation/obcfgavValidationLog.Table.al` |
| 92802 | obcfgav Address Buffer | 60111 | `src/Validation/obcfgavAddressBuffer.Table.al` |
| 92803 | obcfgav Supported Country | 60141 | `src/Setup/obcfgavSupportedCountry.Table.al` |

### Pages

| ID | Name | Was | File |
|---|---|---|---|
| 92800 | obcfgav Setup | 60096 | `src/Setup/obcfgavSetup.Page.al` |
| 92801 | obcfgav Setup Wizard | 60097 | `src/Setup/obcfgavSetupWizard.Page.al` |
| 92802 | obcfgav Log Entries | 60110 | `src/Validation/obcfgavLogEntries.Page.al` |
| 92803 | obcfgav Address Compare | 60112 | `src/Validation/obcfgavAddressCompare.Page.al` |
| 92804 | obcfgav Supported Countries | 60142 | `src/Setup/obcfgavSupportedCountries.Page.al` |

### Codeunits

| ID | Name | Was | File |
|---|---|---|---|
| 92800 | obcfgav Credential Mgt. | 60098 | `src/Setup/obcfgavCredentialMgt.Codeunit.al` |
| 92801 | obcfgav Install | 60099 | `src/Setup/obcfgavInstall.Codeunit.al` |
| 92802 | obcfgav Setup Registration | 60100 | `src/Setup/obcfgavSetupRegistration.Codeunit.al` |
| 92803 | obcfgav Address Validation | 60113 | `src/Validation/obcfgavAddressValidation.Codeunit.al` |
| 92804 | obcfgav Address Service | 60114 | `src/Validation/obcfgavAddressService.Codeunit.al` |
| 92805 | obcfgav Http Transport Impl. | 60115 | `src/Validation/obcfgavHttpTransportImpl.Codeunit.al` |
| 92806 | obcfgav Validation Writer | 60118 | `src/Validation/obcfgavValidationWriter.Codeunit.al` |
| 92807 | obcfgav Google Address Client | 60119 | `src/Validation/obcfgavGoogleAddressClient.Codeunit.al` |
| 92808 | obcfgav Write Guard | 60120 | `src/Sources/obcfgavWriteGuard.Codeunit.al` |
| 92809 | obcfgav Address Source | 60135 | `src/Sources/obcfgavAddressSource.Codeunit.al` |
| 92810 | obcfgav Upgrade Tags | 60136 | `src/Upgrade/obcfgavUpgradeTags.Codeunit.al` |
| 92811 | obcfgav Upgrade Log Source | 60137 | `src/Upgrade/obcfgavUpgradeLogSource.Codeunit.al` |
| 92812 | obcfgav Upgrade Contact Flag | 60138 | `src/Upgrade/obcfgavUpgradeContactFlag.Codeunit.al` |
| 92813 | obcfgav Address Sync Subscr. | 60139 | `src/Sources/obcfgavAddressSyncSubscr.Codeunit.al` |
| 92814 | obcfgav Upgrade Record No. | 60140 | `src/Upgrade/obcfgavUpgradeRecordNo.Codeunit.al` |
| 92815 | obcfgav Country Mgt. | 60147 | `src/Sources/obcfgavCountryMgt.Codeunit.al` |
| 92816 | obcfgav Upgrade Countries | 60148 | `src/Upgrade/obcfgavUpgradeCountries.Codeunit.al` |

### Enums

| ID | Name | Was | File |
|---|---|---|---|
| 92800 | obcfgav Validation Result | 60093 | `src/Setup/obcfgavValidationResult.Enum.al` |
| 92801 | obcfgav Address Provider | 60094 | `src/Setup/obcfgavAddressProvider.Enum.al` |
| 92802 | obcfgav Address Type | 60134 | `src/Sources/obcfgavAddressType.Enum.al` |
| 92803 | obcfgav Blank Country Handling | 60149 | `src/Setup/obcfgavBlankCountryHandling.Enum.al` |

### Permission sets

| ID | Name | Was | File |
|---|---|---|---|
| 92800 | OBCFGAV GAV, USE | 60101 | `src/Setup/OBCFGAVGAVUSE.PermissionSet.al` |
| 92801 | OBCFGAV GAV, ADMIN | 60102 | `src/Setup/OBCFGAVGAVADMIN.PermissionSet.al` |

### Table extensions

| ID | Name | Was | File |
|---|---|---|---|
| 92800 | obcfgav Customer | 60116 | `src/Validation/obcfgavCustomer.TableExt.al` |
| 92801 | obcfgav Ship-to Address | 60143 | `src/Sources/obcfgavShiptoAddress.TableExt.al` |
| 92802 | obcfgav Customer Bank Account | 60145 | `src/Sources/obcfgavCustomerBankAccount.TableExt.al` |
| 92803 | obcfgav Vendor | 60152 | `src/Sources/obcfgavVendor.TableExt.al` |
| 92804 | obcfgav Order Address | 60154 | `src/Sources/obcfgavOrderAddress.TableExt.al` |
| 92805 | obcfgav Remit Address | 60156 | `src/Sources/obcfgavRemitAddress.TableExt.al` |
| 92806 | obcfgav Vendor Bank Account | 60158 | `src/Sources/obcfgavVendorBankAccount.TableExt.al` |
| 92807 | obcfgav Company Information | 60165 | `src/Sources/obcfgavCompanyInformation.TableExt.al` |
| 92808 | obcfgav Location | 60167 | `src/Sources/obcfgavLocation.TableExt.al` |
| 92809 | obcfgav Responsibility Center | 60169 | `src/Sources/obcfgavResponsibilityCenter.TableExt.al` |
| 92810 | obcfgav Bank Account | 60171 | `src/Sources/obcfgavBankAccount.TableExt.al` |
| 92811 | obcfgav Employee | 60178 | `src/Sources/obcfgavEmployee.TableExt.al` |
| 92812 | obcfgav Alternative Address | 60180 | `src/Sources/obcfgavAlternativeAddress.TableExt.al` |
| 92813 | obcfgav Contact | 60182 | `src/Sources/obcfgavContact.TableExt.al` |
| 92814 | obcfgav Contact Alt. Address | 60184 | `src/Sources/obcfgavContactAltAddress.TableExt.al` |
| 92815 | obcfgav Resource | 60186 | `src/Sources/obcfgavResource.TableExt.al` |

### Page extensions

| ID | Name | Was | File |
|---|---|---|---|
| 92800 | obcfgav Customer Card | 60117 | `src/Validation/obcfgavCustomerCard.PageExt.al` |
| 92801 | obcfgav Ship-to Address Card | 60144 | `src/Sources/obcfgavShiptoAddressCard.PageExt.al` |
| 92802 | obcfgav Cust. Bank Acc. Card | 60146 | `src/Sources/obcfgavCustBankAccCard.PageExt.al` |
| 92803 | obcfgav Vendor Card | 60153 | `src/Sources/obcfgavVendorCard.PageExt.al` |
| 92804 | obcfgav Order Address Card | 60155 | `src/Sources/obcfgavOrderAddressCard.PageExt.al` |
| 92805 | obcfgav Remit Address Card | 60157 | `src/Sources/obcfgavRemitAddressCard.PageExt.al` |
| 92806 | obcfgav Vendor Bank Acc. Card | 60159 | `src/Sources/obcfgavVendorBankAccCard.PageExt.al` |
| 92807 | obcfgav Company Info. Card | 60166 | `src/Sources/obcfgavCompanyInfoCard.PageExt.al` |
| 92808 | obcfgav Location Card | 60168 | `src/Sources/obcfgavLocationCard.PageExt.al` |
| 92809 | obcfgav Resp. Center Card | 60170 | `src/Sources/obcfgavRespCenterCard.PageExt.al` |
| 92810 | obcfgav Bank Account Card | 60172 | `src/Sources/obcfgavBankAccountCard.PageExt.al` |
| 92811 | obcfgav Employee Card | 60179 | `src/Sources/obcfgavEmployeeCard.PageExt.al` |
| 92812 | obcfgav Alt. Address Card | 60181 | `src/Sources/obcfgavAltAddressCard.PageExt.al` |
| 92813 | obcfgav Contact Card | 60183 | `src/Sources/obcfgavContactCard.PageExt.al` |
| 92814 | obcfgav Cont. Alt. Addr. Card | 60185 | `src/Sources/obcfgavContAltAddrCard.PageExt.al` |
| 92815 | obcfgav Resource Card | 60187 | `src/Sources/obcfgavResourceCard.PageExt.al` |

## Test app (separate extension, `USPSAddressValidator.Tests`)

### Codeunits

| ID | Name | Was | File |
|---|---|---|---|
| 92830 | obcfgav Fake Http Transport | 60123 | `src/obcfgavFakeHttpTransport.Codeunit.al` |
| 92831 | obcfgav Test Library | 60124 | `src/obcfgavTestLibrary.Codeunit.al` |
| 92832 | obcfgav Validation Tests | 60125 | `src/obcfgavValidationTests.Codeunit.al` |
| 92833 | obcfgav Provider Tests | 60126 | `src/obcfgavProviderTests.Codeunit.al` |
| 92834 | obcfgav Addr Validated Tests | 60127 | `src/obcfgavAddrValidatedTests.Codeunit.al` |
| 92835 | obcfgav Fake Address Provider | 60128 | `src/obcfgavFakeAddressProvider.Codeunit.al` |
| 92836 | obcfgav Source Tests | 60129 | `src/obcfgavSourceTests.Codeunit.al` |
| 92837 | obcfgav Sync Tests | 60130 | `src/obcfgavSyncTests.Codeunit.al` |
| 92838 | obcfgav Country Tests | 60131 | `src/obcfgavCountryTests.Codeunit.al` |
