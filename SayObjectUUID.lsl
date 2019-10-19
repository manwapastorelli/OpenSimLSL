default
{
    state_entry()
    {
        llOwnerSay((string) llGetKey());
        llRemoveInventory(llGetScriptName());
    }
}