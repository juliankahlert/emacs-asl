/* A self-contained SSDT for syntax highlighting and iASL smoke tests. */
DefinitionBlock ("", "SSDT", 2, "EMASL", "EXAMPLE", 0x00000001)
{
    Scope (\_SB)
    {
        Device (ASL0)
        {
            Name (_HID, "ACPI0004")
            Name (_UID, One)
            Name (BUFF, Buffer (4) { 0x10, 0x20, 0x30, 0x40 })

            Method (_STA, 0, NotSerialized)
            {
                If (LEqual (SizeOf (BUFF), 4))
                {
                    Return (0x0F)
                }
                Else
                {
                    Return (Zero)
                }
            }
        }
    }
}
