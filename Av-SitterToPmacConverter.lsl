/*
BSD 3-Clause License
Copyright (c) 2020, Sara Payne
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
INSTRUCTIONS
============
Simply add the script into a prim which contains a AVpos notecard. It will convert those cards into PMAC menu cards.

IMPORTANT
=========
Please work on a copy, this script does not convert all AV-Sitter features to PMAC

Single Menus
------------
PMAC handles singles differently, when a singles menu is used in PMAC, no one else can sit. To try and work around this, the script looks for singles poses with matching button names from each sitter. If found it will turn the two or more matching singles poses into a set of 2 or more that work like Av-Sitter SYNCS. (Couples poses). Any with unmatching names will be added to the singles menu in PMAC.

Menu And Button Names
----------------------
AV-Sitter can have many configurations. Animations get grouped together based on menu and button names. In each sitter, the Menu Name must match. When matching menu names are found, it drops down to line by line checking, only pairing matching button names.

What is not supported
=====================
Any kind of animation sequence - this may come laterAny kind of props support - this may come laterAny of the extra menus used with Av-Sitter plugins such as textures.
*/

integer menuCardNumber = 2; //used at the end when writing the new menu cards
string AvPosCardName = "AVpos"; //name of the Av-sitter positions card
integer debug = FALSE; //turns this on to see debug output, this generates a LOT of local chat output
//if you use the debug option it's suggested you comment them out section by sec
   
ConvertRotationsAndFixOffset()
{   //AvSitter uses x,y,z rotations, PMAC uses quaternion rotations, so convert them. 
    list tempList = [];
    integer lineNumber;
    integer notecardLines = osGetNumberOfNotecardLines(AvPosCardName);
    for (lineNumber = 0; lineNumber < notecardLines; lineNumber++)
    {   //loops through each line of the notecard
        string initial = osGetNotecardLine(AvPosCardName, lineNumber);
        string noTimes = RemoveTimes(initial);
        integer braceIndex = llSubStringIndex(noTimes, "}");
        string fixedRotation;
        string fixedOffset;
        if (braceIndex != -1)
        {   //only deal with lines wich contain a } (pos/rot line)
            fixedRotation = ConvertLineToRotationsAndFixOffset(noTimes); //convert this line to real rotations
        }
        else 
        {   //only deal with lines that do not contain a } (pos/rot line)
            fixedRotation = noTimes;
        }
        tempList += fixedRotation; //add the line to the temp list
    }
    //write the temp list to a notecard
    WriteNotecard("FixedRotations", tempList);
} 

WriteNotecard(string name, list contents)
{   //writes a notecard with the supplied name and contents
    //The conversion script relies on the contents of notecards, Ensure the notecards are deleted and saved before continuing 
    integer inventoryType;
    if (llGetInventoryType(name) == INVENTORY_NOTECARD)
    {
        llRemoveInventory(name);
        inventoryType = llGetInventoryType(name);
        while (inventoryType > -1) //-1 means it doesn't exist 
        {   //wait to make sure the removal is complete before going on
            inventoryType = llGetInventoryType(name);
        }
    }
    osMakeNotecard(name, contents);
    inventoryType = llGetInventoryType(name);
    while (inventoryType != INVENTORY_NOTECARD)
    {   //wait for the write to finish before going on
        inventoryType = llGetInventoryType(name);
    }
}

DebugOwnerSayListContents(string name, list toDisplay)
{   //outputs the contents of a list nicely to local chat for the owner.
    string output = "Debug:ListContents:" + "\n" + "ListName: " + name;
    llOwnerSay(output);
    integer index;
    for (index = 0; index < llGetListLength(toDisplay); index++)
    {   //loop through every line of the list outputting to local chat
        llOwnerSay(llList2String(toDisplay, index));  
    }
}

list ReverseListOrder(list inputList)
{   //reverses the order of a list. 
    list reverseList;
    integer index;
    for (index = llGetListLength(inputList)-1; index >= 0 ; index--)
    {   //loops through the list backwards, adding each line to a new list
        reverseList += llList2String(inputList, index);
    }
    return reverseList;
}

string ConvertLineToRotationsAndFixOffset (string inputString)
{   //takes in the AVpos format and outputs PMAC format
    string name = "{"+ NameFromPositionsLine(inputString) + "}";
    vector posVec = (vector)PosFromPositionsLine(inputString);
    vector rotVec = (vector)RotFromPositionsLine (inputString);
    vector fixedOffset = posVec - <0,0,0.3>;
    rotation rotRot = llEuler2Rot(rotVec * DEG_TO_RAD); //the actual conversion
    string fixedString = name + (string)fixedOffset + (string)rotRot;
    return fixedString;
}

list GetSpecificNotecardCards (string searchString)
{   //uses a partial name string to return all matching notecards from the items inventory
    list sitterNotecards;
    integer numOfNotecards = llGetInventoryNumber(INVENTORY_NOTECARD);
    integer index;
    for (index = 0; index < numOfNotecards; index++)
    {   //loops through every notecard in the inventory
        string notecardName = llGetInventoryName(INVENTORY_NOTECARD, index);
        string testName = llGetSubString(notecardName, 0, llStringLength(searchString)-1);
        if (testName == searchString)
        {   //if we find a match add it to the list
            sitterNotecards += notecardName;
        }
    }
    return sitterNotecards;
}

string MenuNameFromMenuLine(string inputString)
{
    integer spaceChar = llSubStringIndex(inputString, " ");//find the space character
    string menuName = llStringTrim(llGetSubString(inputString, spaceChar +1, -1), STRING_TRIM); //remove everythign before the space
    return menuName;
}

string NameFromPositionsLine(string inputString)
{
    integer charBracket = llSubStringIndex(inputString, "}"); //find the } character
    string nValue = llGetSubString(inputString, 1, charBracket-1); //remove curley brackets and position data
    return nValue;
}

string PosFromPositionsLine(string inputString)
{
    integer charLess = llSubStringIndex (inputString, "<"); // find the first < character
    integer charMore = llSubStringIndex (inputString, ">"); // find the first > character
    string vValue = llGetSubString (inputString, charLess, charMore); // removed everything except the vector
    return vValue; 
}

string RotFromPositionsLine (string inputString)
{
    integer charMore = llSubStringIndex (inputString, ">"); // find the first > character
    string rotValue = llGetSubString (inputString, charMore+1, -1); //remove everything except the rotation vector
    return rotValue; 
}

string RemoveTimes(string inputString)
{
    integer charStart = llSubStringIndex(inputString, "◆");//find the position of the real start of the line and discard all before it
    string trimed = llGetSubString(inputString, charStart+1, -1); //remove everything before the "◆"
    return trimed;
}

string GetPoseName (string inputString)
{
    integer charLine = llSubStringIndex(inputString,"|"); //find the | seperator character
    string lValue = llGetSubString (inputString, 0, charLine-1); // remove everything after the |
    return lValue;
}

string GetAnimName (string inputString)
{
    integer charLine = llSubStringIndex(inputString, "|"); // find the | seperator
    string lValue = llGetSubString(inputString, charLine+1, -1); //remove everythign before the |
    return lValue;
}

string GetSitterNumberFromMenuCardName(string menuCardName)
{
    list elements = llParseStringKeepNulls(menuCardName, "_", ""); //make a list seperated by underscores
    string sitterNumber = llList2String(elements, 2); //retrieve the sitter number from the list
    return sitterNumber;
}

string GetMenuNameFromMenuCardName(string menuCardName)
{
    list elements = llParseStringKeepNulls(menuCardName, "_", "");//make a list seperated by underscores
    string name = llList2String(elements, 3);//retrieve the name number from the list
    return name;
}

string GetButtonNameFromPmacLine(string inputString)
{
    integer barIndex = llSubStringIndex(inputString, "|");// find the | seperator
    string name = llGetSubString(inputString, 0, barIndex-1); //remove everything after the |
    return name;
}

SplitIntoSitters()
{   //splits the AVpos card down into individual sitters
    list tempSitterList;
    integer sitterCount = -1; //start at -1 so that we don't save contents before the first SITTER line
    integer lineNumber;
    integer notecardLines = osGetNumberOfNotecardLines("FixedRotations");
    for (lineNumber = 0; lineNumber < notecardLines; lineNumber++)
    {   //loop through ever line of the AVpos notecard
        string currentLine1 = osGetNotecardLine("FixedRotations", lineNumber);
        if (currentLine1 != "")
        {   //ignore blank lines
            string test = llGetSubString(currentLine1, 0, 3);
            string test2 = llGetSubString(currentLine1, 0, 0);
            if (test == "SITT")
            {   //do something for SITTER line found
                if (sitterCount > -1)
                {   //if we find a new SITTER line write the contents of the temp list to a notecard
                    WriteNotecard("Sitter" + (string)sitterCount, tempSitterList);               
                    tempSitterList = [];//clear the list ready to start again
                }
                sitterCount++;
            }
            else if (test == "MENU" || test == "POSE" || test == "SYNC" || test2 == "{")
            {   //only deal with the menus, poses, syncs and pos/rot lines
                tempSitterList += currentLine1; //add info to the new list
            }
                        
        }
    }
    //write a notecard containing all needed information for this sitter
    WriteNotecard("Sitter" + (string)sitterCount, tempSitterList);
}

list GetSitterSyncsAndMenus(string notecardName)
{   //loops through the named notecard looking for lines which start with SYNC, MENU or { (pos/rot lines)
    //adds them to the new list as they are found
    list sitterSyncsAndMenus;
    list poseNames;
    integer lineNumber;
    for (lineNumber = 0; lineNumber < osGetNumberOfNotecardLines(notecardName); lineNumber++)
    {   //loops through every line of the notecard
        string currentLine2 = osGetNotecardLine(notecardName, lineNumber);
        string testPose = llGetSubString(currentLine2, 0, 3);
        string testAnimData = llGetSubString(currentLine2, 0, 0);
        string testPoseName; 
        if (testPose == "SYNC")
        {   //for every SYNC line remove the word SYNC and the space, retrieve the pose name from the remainder
            //and add the pose name to the list of pose names
            string withoutTitle = llStringTrim(llGetSubString(currentLine2, 5, -1), STRING_TRIM); 
            sitterSyncsAndMenus += withoutTitle;
            testPoseName = GetPoseName(withoutTitle);
            poseNames += testPoseName;
        }
        else if (testPose == "MENU")
        {   //add ever Menu line to the list
            sitterSyncsAndMenus += currentLine2;
        }
        else if (testAnimData == "{")
        {   //come here for every pos/rot line, check the name and if it matches
            //add it to the list
            integer closeBraceIndex = llSubStringIndex(currentLine2, "}");
            string lineAnimName = llGetSubString(currentLine2, 1, closeBraceIndex-1);
            if(~llListFindList(poseNames, (list)lineAnimName))
            {   //if the name matches any of the ones added to the pose list earlier, add the line
                //to the main list. 
                sitterSyncsAndMenus += currentLine2;
            }
        }
    }
    return sitterSyncsAndMenus;
}

list GetSitterPOSEs(string notecardName)
{   //loop through the supplied notecard name saving just pose names and related pos/rot lines
    list sitterPoses;
    list poseNames;
    integer lineNumber;
    for (lineNumber = 0; lineNumber < osGetNumberOfNotecardLines(notecardName); lineNumber++)
    {   //loops through every line in the notecard
        string currentLine2 = osGetNotecardLine(notecardName, lineNumber);
        string testPose = llGetSubString(currentLine2, 0, 3);
        string testAnimData = llGetSubString(currentLine2, 0, 0);
        string testPoseName; 
        if (testPose == "POSE")
        {   //checks each pose line, retrieves the name then adds the name to the poses list
            string withoutTitle = llStringTrim(llGetSubString(currentLine2, 5, -1), STRING_TRIM); 
            sitterPoses += withoutTitle;
            testPoseName = GetPoseName(withoutTitle);
            poseNames += testPoseName;
        }
        else if (testAnimData == "{")
        {   //checks every pos/rot line, if the name matches one save earlier add it to the list
            integer closeBraceIndex = llSubStringIndex(currentLine2, "}");
            string lineAnimName = llGetSubString(currentLine2, 1, closeBraceIndex-1);
            if(~llListFindList(poseNames, (list)lineAnimName))
            {   //if the lines name matches one in the pose list add the whole line to the main list
                sitterPoses += currentLine2;
            }
        }
    }
    return sitterPoses;
}

FixAndCombineSinglePoses()
{   //makes new notecards with the sync and poses seperated 
    //along with their related pos/rot information. 
    SeperatePoseNamesAndData();
    CreateNewSyncSetFromPoses();
}

SeperatePoseNamesAndData()
{   //loops through every sitter card making new serpate cards for poses (not syncs) and their related pos/rot 
    list sitterNotecards = GetSpecificNotecardCards("Sitter");
    integer sitterCardIndex;
    for(sitterCardIndex = 0; sitterCardIndex < llGetListLength(sitterNotecards); sitterCardIndex++)
    {   //loops through every sitter notecard
        string cardName = llList2String(sitterNotecards, sitterCardIndex);
        list sitterPoses = GetSitterPOSEs(cardName);
        list sitterPosRotData;
        integer lineIndex;
        for (lineIndex = llGetListLength(sitterPoses)-1; lineIndex >=0; lineIndex--)
        {   //add all lines with braces to the sitte pos/rot list and remove from sitter poses list
            string currentLine3 = llList2String(sitterPoses, lineIndex);
            integer hasBraces = llSubStringIndex(currentLine3, "}");
            if (hasBraces > -1)
            {   //takes every pos/rot line and adds it to the pos/rot line list
                if (debug) llOwnerSay("Debug:BracesLine: " + currentLine3);
                sitterPosRotData += currentLine3;
                sitterPoses = llDeleteSubList(sitterPoses, lineIndex, lineIndex);
            }
        }
        //write out both cards, reversing the order of the pos/rot card so it matches the order of the menu card. 
        WriteNotecard("Poses " + cardName, sitterPoses);
        sitterPosRotData = ReverseListOrder(sitterPosRotData);
        WriteNotecard("DataPoses " + cardName, sitterPosRotData);
    }
}

GeneratePoseToSyncCards(list poseCards, list newSyncNames)
{   //loops through all pose cards line by line, looking for names with the same button names
    //assumes these are supposed to be paied up and makes new SYNC menus from them. 
    list newSyncPoses;
    list newSyncData;
    integer poseCardIndex;
    for (poseCardIndex = 0; poseCardIndex < llGetListLength(poseCards); poseCardIndex++)
    {   //loops through each card
        string cardName = "Poses Sitter" + (string)poseCardIndex;
        integer cardLength = osGetNumberOfNotecardLines(cardName);
        if(debug) llOwnerSay("Debug:ReadingCard: " + cardName);
        integer lineIndex;
        newSyncPoses = [];
        newSyncData = [];
        string menu = "MENU Social-A";
        newSyncPoses += menu;
        for (lineIndex = 0; lineIndex < cardLength; lineIndex++)
        {   //loops through each line in the given notecard
            string posesLine = osGetNotecardLine("Poses Sitter" + (string)poseCardIndex, lineIndex);
            string dataLine = osGetNotecardLine("DataPoses Sitter" + (string)poseCardIndex,lineIndex);
            string poseName = GetPoseName (posesLine);
            if (debug) llOwnerSay("Debug:CheckingPoseName: " + poseName);
            if (~llListFindList(newSyncNames, (list)poseName))
            {   //come here if the current pose name is found in the new sync names list
                if (debug) llOwnerSay("Debug:Found" + poseName);
                string newPoseLine = "SYNC " + posesLine;
                newSyncPoses += newPoseLine;
                newSyncData += dataLine;
            }
        }
        list combinedList = newSyncPoses + newSyncData;
        WriteNotecard("PoseToSyncSitter" + (string)poseCardIndex, combinedList);    
    }
}

CreateNewSyncSetFromPoses()
{   //loops though every pose card and attempts to find pairs which should be used together. 
    //then makes a list of real single only poses and pairs to treat as syncs, pmac singles
    //don't allow others to sit, so better to pair them up when possible. 
    list posesCards = GetSpecificNotecardCards("Poses Sitter");
    integer posesCardIndex;
    list poseNamesSitter0;
    list newSyncNames;
    list newSinglesNames;
    if (debug) DebugOwnerSayListContents("list of poses cards", posesCards);
    //loop through all cards checking for duplicate pose names, store them in newSyncNames
    for (posesCardIndex = 0; posesCardIndex < llGetListLength(posesCards); posesCardIndex++)
    {   //loops through each card, checking against sitter 0
        integer lineIndex;
        string notecardName = llList2String(posesCards, posesCardIndex);
        integer notecardLength = osGetNumberOfNotecardLines(notecardName);
        for (lineIndex = 0; lineIndex < notecardLength; lineIndex++)
        {
            string currnetLine = osGetNotecardLine(notecardName, lineIndex);
            string poseName = GetPoseName (currnetLine);
            if (posesCardIndex == 0)
            {
                poseNamesSitter0 += poseName;
            }
            else
            {
                if(~llListFindList(poseNamesSitter0, (list)poseName))
                { //come here if poseName is found in sitter0
                    if (!(~llListFindList(newSyncNames, (list)poseName)))
                    {   //come here only if the pose is not already in the new sync names
                        newSyncNames += poseName;
                    }
                }
                else
                {   //come here if the pose is not found in sitter 0
                    if (!(~llListFindList(newSinglesNames, (list)poseName)))
                    {   //come here only if the pose is not already in the new sync names
                        newSinglesNames += poseName;
                    }
                }
            }
        }
    }
    GenerateNewSinglesCard(newSyncNames);
    GeneratePoseToSyncCards(posesCards, newSyncNames);
    CombinePoseToSyncCardsWithSiterCards();
}

CombinePoseToSyncCardsWithSiterCards()
{   //takes the new sync cards (made from pair poses) and combines
    //these new menus with the original sitter cards ready for sync set processing
    list sitterCards = GetSpecificNotecardCards ("Sitter");
    integer sitterCardIndex;
    for (sitterCardIndex = 0; sitterCardIndex < llGetListLength(sitterCards); sitterCardIndex++)
    {
        list newSitterCard;
        string currentLine;
        string CardName = "Sitter" + (string)sitterCardIndex;
        newSitterCard += AllLinesWithOrWithoutBraces (CardName, FALSE);
        CardName = "PoseToSyncSitter" + (string)sitterCardIndex;
        newSitterCard += AllLinesWithOrWithoutBraces (CardName, FALSE);
        CardName = "Sitter" + (string)sitterCardIndex;
        newSitterCard += AllLinesWithOrWithoutBraces (CardName, TRUE);
        CardName = "Sitter" + (string)sitterCardIndex;
        newSitterCard += AllLinesWithOrWithoutBraces (CardName, TRUE);
        if (debug) DebugOwnerSayListContents("New Sitter " + (string)sitterCardIndex +  " card", newSitterCard);
        WriteNotecard("Sitter" + (string)sitterCardIndex, newSitterCard);
    }
}

list AllLinesWithOrWithoutBraces(string cardName, integer with)
{   //loops through the given notecard name, if the "with" integer is TRUE
    //adds all lines with braces to a list. If the "with" is FALSE all lines
    //without braces are added to the list. 
    list newList;
    integer CardLength = osGetNumberOfNotecardLines(cardName);
    integer lineNumber;
    //add lines without braces from the sitter card
    for (lineNumber = 0; lineNumber < CardLength; lineNumber++)
    {   //loops through the whole notecards
        string currentLine = osGetNotecardLine(cardName, lineNumber);
        integer hasBraces = llSubStringIndex(currentLine, "{");
        if(with)
        {   //we want all lines with braces
            if (hasBraces > -1) 
            {
                newList += currentLine;
            }
        }
        else
        {   //we want all lines without braces
            if (hasBraces == -1)
            {
                newList += currentLine;
            }
        }
    }
    return newList;
}

GenerateNewSinglesCard(list newSyncNames)
{   //loops through all poses in all the sitter cards, checks to see if they have matching
    //entries in the newSyncNames list, if they don't ass them to a list of real single 
    //poses and writes the note card when the list is complelete
    if (debug) llOwnerSay("Debug:GenerateNewSinglesCard: Entered");
    integer posesSitter0Line;
    list posesCards = GetSpecificNotecardCards("Poses Sitter");
    if (debug) DebugOwnerSayListContents("posesCards", posesCards);
    if (debug) DebugOwnerSayListContents("sync names list", newSyncNames);
    list newSinglePoses;
    list newSinglePosesData;
    integer posesCardIndex; 
    for (posesCardIndex = 0; posesCardIndex < llGetListLength(posesCards); posesCardIndex++)
    {   //loops through each poses card card
        integer lineIndex;
        string notecardName = llList2String(posesCards, posesCardIndex);
        if (debug) llOwnerSay("Debug:CheckingCard: " + notecardName);
        integer notecardLength = osGetNumberOfNotecardLines(notecardName);
        for (lineIndex = 0; lineIndex < notecardLength; lineIndex++)
        {   //loops through every line of the current poses card
            string currentLine4 = osGetNotecardLine(notecardName, lineIndex);
            string poseName = GetPoseName (currentLine4);
            if (debug) llOwnerSay("Debug: checking pose name: " + poseName);
            integer matchFound = FALSE;
            integer newSyncNamesIndex = 0;
            //now check this line against every line of new sync names
            while (!matchFound && newSyncNamesIndex < llGetListLength(newSyncNames))
            {   //loops through the sync poses checking for a match, keeps going until it finishes withou
                //a result or finds a match
                string newSyncNamesLine = llList2String(newSyncNames, newSyncNamesIndex);
                if(debug) llOwnerSay("Debug:Checking:" + currentLine4 + " against " + newSyncNamesLine);
                if (poseName == newSyncNamesLine)
                {   //come here if a a match has been found, stop the loop 
                    if(debug) llOwnerSay("Debug:MatchFound");
                    matchFound = TRUE;
                }
                newSyncNamesIndex++;
            }
            if (!matchFound)
            {   //loop though the sync cards has ended, no match found, add this item to the singles list
                //add the data from the same animations and button names to to another list. 
                if (debug) llOwnerSay("Debug: Not Found");
                string newSinglePosesLine = osGetNotecardLine("Poses Sitter" + (string)posesCardIndex, lineIndex);
                string newSinglePosesDataLine = osGetNotecardLine("DataPoses Sitter" + (string)posesCardIndex, lineIndex);
                newSinglePoses += newSinglePosesLine; 
                newSinglePosesData += newSinglePosesDataLine;
            } 
        }
    }
    if (debug)
    {
        DebugOwnerSayListContents("newSinglePoses", newSinglePoses);
        DebugOwnerSayListContents("newSinglePosesData", newSinglePosesData);
    }
    //now turn the two new lists above into a menu card for PMAC
    integer newSinglePosesIndex;
    list newSinglesMenu; //list to hold the new singles menu
    for (newSinglePosesIndex = 0; newSinglePosesIndex < llGetListLength(newSinglePoses); newSinglePosesIndex++)
    {   //loops through each of the new singles poses entries, makes the PMAC line and adds to the list ready for writing
        string lineFromPoses = llList2String(newSinglePoses, newSinglePosesIndex);
        string lineFromData = llList2String(newSinglePosesData, newSinglePosesIndex);
        if (debug) llOwnerSay("Debug:LineFromPoses: " + lineFromPoses);
        if (debug) llOwnerSay("Debug:LineFromPosesData: " + lineFromData);
        string buttonname = GetPoseName (lineFromPoses);
        if (debug) llOwnerSay("Debug:ButtonName: " + buttonname);
        string animName =  GetAnimName (lineFromPoses);
        string position = PosFromPositionsLine(lineFromData);
        string rot = RotFromPositionsLine (lineFromData); //this is already a rotation just reusing a method.
        string newEntry =  buttonname + "|NO COM|" + animName + "|" + position + "|" + rot;
        if(debug) llOwnerSay("Debug:AddedToSingleMenu: " + newEntry);
        newSinglesMenu += newEntry;
    }
    if (debug) DebugOwnerSayListContents("new singels menu", newSinglesMenu);
    //everything added, write the notecard. 
    WriteNotecard(".menu001A Singles", newSinglesMenu);
}

RemovePosesAndPoseDataFromSitters()
{
    //now the poses have bene converted to syncs or written to their own PMAC menu
    //remove them from the SITTER cards so they can be processed as just sync's
    list sitterCards = GetSpecificNotecardCards ("Sitter");
    integer sitterCardIndex;
    for (sitterCardIndex = 0; sitterCardIndex < llGetListLength(sitterCards); sitterCardIndex++)
    {   //loop through each sitter card, inside each one remove any pose related lines
        string cardName = llList2String(sitterCards, sitterCardIndex);
        list sitterWithNoPoses = GetSitterSyncsAndMenus(cardName);
        if (debug) DebugOwnerSayListContents("newSitter" + (string)sitterCardIndex, sitterWithNoPoses);
        WriteNotecard(cardName, sitterWithNoPoses);
    }
}

list SitterWithNoEmptyMenus (string cardName)
{   //loop through the card name provided, create a new list which contains
    //non of the menus which only make up a menu structure, keep the ones which
    //contain animation buttons. 
    list newList;
    integer lineIndex;
    integer cardLength = osGetNumberOfNotecardLines(cardName);
    for (lineIndex = 0; lineIndex < cardLength; lineIndex++)
    {   //loops through each line of the notecard
        string thisLine = osGetNotecardLine(cardName, lineIndex);
        string testMenu = llGetSubString(thisLine, 0, 3);
        string testBraces = llGetSubString(thisLine, 0, 0);
        string testPoseName; 
        if (testMenu == "MENU")
        {   //come here only if the line starts with MENU
            if (debug) llOwnerSay("Debug: Menu Line Found");
            string nextLine = osGetNotecardLine(cardName, lineIndex + 1);
            string nextLineMenuTest = llGetSubString(nextLine, 0, 3);
            if (nextLineMenuTest != "MENU")
            {   //if the next line is not also MENU add this line
                newList += thisLine;
            }
        }
        else if (testBraces = "{")
        {   //keep everything which is not a Menu line
            newList += thisLine;
        }
    }
    return newList;
}

RemoveEmptyMenusFromSitterCards()
{   //removes all the menu structure, preseving just the ones which directly deliver animation buttons
    list sitterCards = GetSpecificNotecardCards ("Sitter");
    integer sitterCardIndex;
    for (sitterCardIndex = 0; sitterCardIndex < llGetListLength(sitterCards); sitterCardIndex++)
    {
        string cardName = llList2String(sitterCards, sitterCardIndex);
        list SitterNoEmptyMenus = SitterWithNoEmptyMenus(cardName);
        if (debug) DebugOwnerSayListContents("newSitter" + (string)sitterCardIndex, SitterNoEmptyMenus);
        WriteNotecard(cardName, SitterNoEmptyMenus);
    }
}

RemoveTempCards()
{   //loops though the inventory removing any temp notecards created during the conversion
    list testStrings = ["DataPoses Sitter", "FixedRotations", "Poses Sitter", "PoseToSyncSitter", "Data_Sitter", "Menu_Sitter", "MenuData_Sitter", "Sitter"];
    list testResults;
    integer numOfNotecards = llGetInventoryNumber(INVENTORY_NOTECARD);
    integer notecardIndex;
    for (notecardIndex = numOfNotecards -1; notecardIndex >=0; notecardIndex--)
    {   //loops through the inventory
        string notecardName = llGetInventoryName(INVENTORY_NOTECARD, notecardIndex);
        integer testIndex;
        for (testIndex = 0; testIndex < llGetListLength(testStrings);testIndex++)
        {   //checks each name against the ones in the list to remove
            string testString = llList2String(testStrings,testIndex);
            string testResult = llGetSubString(notecardName, 0, llStringLength(testString)-1);
            if (testString == testResult)
            {   //when a match is found, remove it. 
                if (debug) llOwnerSay("Debug:RemoveTempCards:Removed: " + notecardName);
                llRemoveInventory(notecardName);
            }
        }
    }
}

list GetMenuLinePositions(string sitterCard)
{   //loops through the sitter card, making list of all line positions containing MENU lines
    integer sitterCardLength = osGetNumberOfNotecardLines(sitterCard);
    integer lineIndex;
    list menuLinePositions;
    integer dataStartLine;
    for(lineIndex = 0; lineIndex < sitterCardLength; lineIndex++)
    {   //loops through each line of the sittercard
        string currentLine = osGetNotecardLine(sitterCard, lineIndex);
        string menuTest = "MENU";
        string testResult = llGetSubString(currentLine, 0, llStringLength(menuTest)-1);
        if (menuTest == testResult)
        {   //add this line number to the list
            menuLinePositions += lineIndex;
        }
    }
    if (debug) llOwnerSay("Debug:GetMenuLinePositions:List: " + llList2CSV(menuLinePositions));
    return menuLinePositions;
}

GenerateMenuCardsForSyncs()
{   //goes through each sitter card making invidiual menu notecards for every sitter
    list sitterCards = GetSpecificNotecardCards ("Sitter");
    integer sitterCardIndex;
    for (sitterCardIndex = 0; sitterCardIndex < llGetListLength(sitterCards); sitterCardIndex++)
    {   //loops through each sitter card
        string sitterCardName = llList2String(sitterCards, sitterCardIndex);
        list menuLinePositions = GetMenuLinePositions(sitterCardName);
        list newMenuCardLines;
        integer menuIndex;
        
        for (menuIndex = 0; menuIndex < llGetListLength(menuLinePositions); menuIndex++)
        {   //loops through each menu entry for this sitter
            newMenuCardLines = []; 
            integer menuStartLine = llList2Integer(menuLinePositions, menuIndex) +1; //+1 avoids adding the actual menu line which is no longer required
            integer menuEndLine;
            if(menuIndex != llGetListLength(menuLinePositions)-1)
            {   //if its not the last entry, the end point is the start of the next menu
                menuEndLine = llList2Integer(menuLinePositions, menuIndex+1);
            }
            else
            {   //if this is the last menu, set the end to the end of the notecard
                menuEndLine = osGetNumberOfNotecardLines(sitterCardName)-1; //-1 to ensure we stop at the bottom of the card
            }
            integer menuLineIndex;
            for (menuLineIndex = menuStartLine; menuLineIndex < menuEndLine; menuLineIndex++)
            {   //add each line that forms part of this menu to the new menu card
                newMenuCardLines;
                string currentLine = osGetNotecardLine(sitterCardName, menuLineIndex);
                integer isData = llSubStringIndex(currentLine, "}");
                if (isData == -1)
                {
                    newMenuCardLines += currentLine;
                } 
            }
            string menuName = MenuNameFromMenuLine(osGetNotecardLine(sitterCardName,menuStartLine-1)) ; //-1 to get the actual menu line
            string newCardName = "Menu_Sitter_" + (string)sitterCardIndex + "_" + menuName;
            WriteNotecard(newCardName, newMenuCardLines);
        }
    }
}

string FindMatchingDataLine(string buttonName, string sitterNumber)
{   //loops through the Sitter card for the sitter number provided
    //looking for the button name provided inside the pos/rot lines
    //if one is found, return it
    string dataLine;
    string sitterCardName = "Sitter" + sitterNumber;
    integer cardLength = osGetNumberOfNotecardLines(sitterCardName);
    integer lineIndex = cardLength-1;
    integer matchFound = FALSE;
    while (!matchFound && lineIndex >= 0)
    {   //start from the bottom and loop until a match is found, positions are always at the bottom of the card
        string currentLine = osGetNotecardLine(sitterCardName, lineIndex);
        integer isPosRot = llSubStringIndex(currentLine, "}");
        if (isPosRot)
        {   //only look at pos/rot lines
            string lineName = NameFromPositionsLine(currentLine);
            if (lineName == buttonName)
            {   //if a match is found add it to the list
                dataLine = currentLine;
                matchFound = TRUE;
            }
        }
        lineIndex--;
    }
    return dataLine;
}

GenerateDataCardsForSyncs()
{   //loops through all the temp menu cards, for each one it loops through every 
    //line and then retrieves the matching pos/rot line in the appropriate sitter card 
    //using this to make a dedicated pos/rot DATA card for the menu being processed. 
    list menuCards = GetSpecificNotecardCards ("Menu_");
    integer menuCardIndex;
    list dataLines;
    for (menuCardIndex = 0; menuCardIndex < llGetListLength(menuCards); menuCardIndex++)
    {
        dataLines = []; //clear this to make a new one each time
        string cardName = llList2String(menuCards, menuCardIndex);
        string sitterNumber = GetSitterNumberFromMenuCardName(cardName);
        string menuName = GetMenuNameFromMenuCardName(cardName);
        integer cardLength = osGetNumberOfNotecardLines(cardName);
        integer cardLineIndex;
        for (cardLineIndex = 0; cardLineIndex < cardLength; cardLineIndex++)
        {   //loops through the current menu card line by line
            string cardLine = osGetNotecardLine(cardName, cardLineIndex);
            string buttonname = GetPoseName (cardLine);
            string dataLine = FindMatchingDataLine(buttonname, sitterNumber);
            dataLines += dataLine;
        }
        string newCardName = "Data_Sitter_" + sitterNumber + "_" + menuName ;
        WriteNotecard(newCardName, dataLines);
    }
}

list GetCombinedSitter0MenuData(string menuCardName, string dataCardName)
{   //takes the supplied names, retrieves the data from both and combines it line by line.
    //the returned list will make a MenuData temp notecard.
    list combinedMenuDataCard;
    integer menuCardLength = osGetNumberOfNotecardLines(menuCardName);
    integer dataCardLength = osGetNumberOfNotecardLines(dataCardName);
    integer menuCardLineIndex;
    integer dataCardLineIndex;
    for (menuCardLineIndex = 0; menuCardLineIndex < menuCardLength; menuCardLineIndex++)
    {   //loops through each line of the menu card
        string menuCardLine = osGetNotecardLine(menuCardName, menuCardLineIndex);
        string menuButtonName = GetPoseName (menuCardLine);
        string animName = GetAnimName (menuCardLine);
        integer dataSitter0CardIndex = 0;
        integer matchFound = FALSE;
        while (!matchFound && dataSitter0CardIndex < dataCardLength)
        {
            string dataCardLine = osGetNotecardLine(dataCardName, dataSitter0CardIndex);
            string dataButtonName = NameFromPositionsLine(dataCardLine);
            if (menuButtonName == dataButtonName)
            {
                matchFound = TRUE;
                string dataPos = PosFromPositionsLine(dataCardLine);
                string dataRot = RotFromPositionsLine (dataCardLine);
                string toAdd = menuButtonName + "|NO COM|" + animName + "|" + dataPos + "|" + dataRot;
                combinedMenuDataCard += toAdd;
            }
            dataSitter0CardIndex++;
        }
    }
    return combinedMenuDataCard;
}

CombineSitter0MenuAndDataCards()
{   //gets a list of all Menu cards and all Data cards then passes them in 
    //pairs to the combine method. 
    list menuSitter0Cards = GetSpecificNotecardCards ("Menu_Sitter_0");
    list dataDitter0Cards = GetSpecificNotecardCards ("Data_Sitter_0");
    integer menuSitter0CardIndex;
    for (menuSitter0CardIndex = 0; menuSitter0CardIndex < llGetListLength(menuSitter0Cards); menuSitter0CardIndex++)
    {
        string sitter0MenuCardName = llList2String(menuSitter0Cards, menuSitter0CardIndex);
        string sitter0DataCardName = llList2String(dataDitter0Cards, menuSitter0CardIndex);
        string menuName = GetMenuNameFromMenuCardName(sitter0MenuCardName);
        list combinedSitter0MenuData = GetCombinedSitter0MenuData(sitter0MenuCardName, sitter0DataCardName);
        WriteNotecard("MenuData_Sitter_0_" + menuName, combinedSitter0MenuData);
        if (debug) DebugOwnerSayListContents("sitter0MenuData_" + menuName, combinedSitter0MenuData);
    }
}

list GetRelatedMenuSitterCards(string menuName)
{   //finds all temp menu cards related to the supplied name and returns the list
    list menuSitterCards = GetSpecificNotecardCards ("Menu_Sitter");
    list relatedMenuCards;
    integer menuCardIndex;
    for (menuCardIndex = 0; menuCardIndex < llGetListLength(menuSitterCards); menuCardIndex++)
    {   //start loop at 0 incase there is only 1 entry, but ignore the first first loop as we do not want sitter 0
            string currentCardName = llList2String(menuSitterCards, menuCardIndex);
            string currentMenuName = GetMenuNameFromMenuCardName(currentCardName);
            string sitterNumber = GetSitterNumberFromMenuCardName(currentCardName);
            if (currentMenuName == menuName && sitterNumber != "0")
            {   //ignore sitter 0 since it is the one we are working from, don't duplicate it. 
                relatedMenuCards += currentCardName;
            }
    }
    return relatedMenuCards;
}

string GetAnimNameFromRelatedMenuCard(string relatedMenuCardName, string buttonName)
{   //All card entries can be out of order, so search through every line until a match is found and return the information. 
    string animName = "";
    integer cardLength = osGetNumberOfNotecardLines(relatedMenuCardName);
    integer cardIndex = 0;
    integer matchFound = FALSE;
    while (!matchFound && cardIndex < cardLength)
    {
        string cardLine = osGetNotecardLine(relatedMenuCardName, cardIndex);
        string poseName = GetPoseName (cardLine);
        if (poseName == buttonName)
        {
            animName = GetAnimName (cardLine);
            matchFound = TRUE;
        }
        cardIndex++;
    }
    return animName;
}

string GetPosRotFromRelatedDataCard(string relatedDataCardName, string buttonName)
{   //All card entries can be out of order, so search through every line until a match is found and return the information. 
    string posRotData = "";
    integer cardLength = osGetNumberOfNotecardLines(relatedDataCardName);
    integer cardIndex = 0;
    integer matchFound = FALSE;
    while (!matchFound && cardIndex < cardLength)
    {
        string cardLine = osGetNotecardLine(relatedDataCardName, cardIndex);
        string poseName = NameFromPositionsLine(cardLine);
        if (poseName == buttonName)
        {
            string pos = PosFromPositionsLine(cardLine);
            string rot = RotFromPositionsLine (cardLine);
            posRotData = pos + "|" + rot;
            matchFound = TRUE;
        }
        cardIndex++;
    }
    return posRotData;
}
 
CombineMenuDataCardWithRelatedCards(string menuDataCard, string menuName, list relatedMenuCards)
{   //take every line in the menuData card, find its corresponding line in each related card and combine the information. 
    //then add the combined line to a list, at the end return the list. 
    list pmcaMenuCard;
    integer cardLength = osGetNumberOfNotecardLines(menuDataCard);
    integer cardLineIndex;
    for (cardLineIndex = 0; cardLineIndex < cardLength; cardLineIndex++)
    {
        string currentLine = osGetNotecardLine(menuDataCard, cardLineIndex);
        string buttonName = GetButtonNameFromPmacLine(currentLine);
        integer relatedCardsIndex;
        string newLine = currentLine;
        for (relatedCardsIndex = 0; relatedCardsIndex < llGetListLength(relatedMenuCards); relatedCardsIndex++)
        {
            string relatedMenuCardName = llList2String(relatedMenuCards, relatedCardsIndex);
            string relatedCardSitter = GetSitterNumberFromMenuCardName(relatedMenuCardName);
            string relatedDataCardName = "Data_Sitter_" + relatedCardSitter + "_" + menuName;
            string animName = GetAnimNameFromRelatedMenuCard(relatedMenuCardName, buttonName);
            string posRot = GetPosRotFromRelatedDataCard(relatedDataCardName, buttonName);
            string extraToAdd = "|" + animName + "|" + posRot;
            newLine += extraToAdd;
        }
        pmcaMenuCard += newLine;
    }
    string pmacMenuCardName = ".menu" + "022A " + menuName;
    WriteNotecard(pmacMenuCardName, pmcaMenuCard);
}

CombineMenuAndDataCards()
{   //loop through each of the MenuData cards, find the related cards and pass them one by one to the 
    //combine card method.
    menuCardNumber = 2; 
    CombineSitter0MenuAndDataCards();
    list menuDataSitter0Cards = GetSpecificNotecardCards ("MenuData_Sitter_0");
    integer cardIndex;
    for (cardIndex = 0; cardIndex < llGetListLength(menuDataSitter0Cards); cardIndex++)
    {
        string currentCardName = llList2String(menuDataSitter0Cards, cardIndex);
        string menuName = GetMenuNameFromMenuCardName(currentCardName);
        list releatedMenuSitterCards = GetRelatedMenuSitterCards(menuName);
        if  (debug) llOwnerSay("Debug:CombineMenuAndDataCards:ProcessingMenu: " + menuName);
        if (debug) DebugOwnerSayListContents(menuName + " related cards: ", releatedMenuSitterCards);
        CombineMenuDataCardWithRelatedCards(currentCardName, menuName, releatedMenuSitterCards);
    }
}

default
{
    state_entry()
    {
        if (llGetInventoryType("AVpos") != INVENTORY_NOTECARD)
        {
            llOwnerSay("AVpos card not found, aborting");
        }
        else
        {
            llOwnerSay("Conversion Started");
            ConvertRotationsAndFixOffset();
            SplitIntoSitters();
            llOwnerSay("Sorting singles poses");
            FixAndCombineSinglePoses();
            RemovePosesAndPoseDataFromSitters();
            llOwnerSay("Preparing to convert SYNC's");
            RemoveEmptyMenusFromSitterCards();
            llOwnerSay("Creating Temp Menu cards");
            GenerateMenuCardsForSyncs();
            llOwnerSay("Creating Temp Position/Rotation cards");
            GenerateDataCardsForSyncs();
            llOwnerSay("Creating PMAC menu cards");
            CombineMenuAndDataCards();
            llOwnerSay("Clearing up temporary notecards");
            RemoveTempCards();
            llOwnerSay("Finished! You should find your new PMAC menu cards inside");
        }
        
    }
}
