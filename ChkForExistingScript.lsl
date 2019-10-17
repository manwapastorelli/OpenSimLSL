/*
BSD 3-Clause License
Copyright (c) 2019, Sara Payne
All rights reserved.
Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:
1. Redistributions of source code must retain the above copyright notice, this
   list of conditions and the following disclaimer.
2. Redistributions in binary form must reproduce the above copyright notice,
   this list of conditions and the following disclaimer in the documentation
   and/or other materials provided with the distribution.
3. Neither the name of the copyright holder nor the names of its
   contributors may be used to endorse or promote products derived from
   this software without specific prior written permission.
THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

/*
This script should not be considered a standalone script, but rather the method should be added to other complete scripts. 

Add this method to another script and call it at the top of your state entry section. When the script starts up it will look for a duplicate
copy of its self and remove the old one. 
*/

CheckForExistingScript()
{   //checks to see if another copy of this script alreayd exists, if it does remove it. 
    string name = llGetScriptName(); // gets the current script name
    integer length = llStringLength(name); // how many charcters are in this script name
    string lastTwoChars = llGetSubString(name, -2 ,-1); // finds the last two characters in the name
    if (lastTwoChars == " 1" ) 
    {   // come here if the name ends with a space then the number 1 (like its been auto adjusted due to a duplicate name already existing)
        string mainScriptName = llGetSubString(name, 0,length-3); //get the script name without the space and 1 at the end
        integer check = llGetInventoryType(mainScriptName); //gets the inventory type of an item with name minus the tail if it exists
        if (check == INVENTORY_SCRIPT) 
        {   //come here if a script matching the name without the tail exists come here
            llRemoveInventory(mainScriptName); //remove the old script
            llOwnerSay("Duplicate script detected and removed");
        }//close if duplicate exists
    }//close if this script name ends in " 1"
    integer numScripts = llGetInventoryNumber(INVENTORY_SCRIPT); //get the number of scripts in the item after the above check
    if ( numScripts > 1)
    {   //come here if there are still multiple scripts in the item
        integer scriptIndex;
        for (scriptIndex = numScripts-1; scriptIndex >=0; --scriptIndex)
        {   //loop through all scripts in this object in reverse order so if removing we don't get adujust index issues 
            string currentScriptName = llGetInventoryName(INVENTORY_SCRIPT, scriptIndex); //gets the name of the current script index
            if (currentScriptName != name)
            {   //come here if we are not checking this script!. (Dont remove this script)
                //integer isDuplicate = contains(currentScriptName, name);
                integer isDuplicate = ~llSubStringIndex(currentScriptName, name); 
                //returns true if the name of this script is contained inside the name of the script we are checking
                //eg this script is "MainScript" and the script we are checking is "MainScript 1"
                if (isDuplicate) 
                {   //come here if the found script is a duplicate of this script
                    llRemoveInventory(currentScriptName); //remove the duplicate script
                    llOwnerSay("Duplicate script detected and removed");
                }//close if script is a duplicte
            }//close if we are dealing with a script other than this script 
        }//close loop through scripts in the object
    }//close if we still have more than 1 script in the objevt 
}//close check for existing script


default
{
    state_entry()
    {
       CheckForExistingScript(); //calls the method
    }
}
