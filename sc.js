var Win32_ShadowCopy = GetObject("winmgmts:\\\\.\\root\\cimv2:Win32_ShadowCopy");

Win32_ShadowCopy.Create(
  "E:\\",
  "ClientAccessible"
);
