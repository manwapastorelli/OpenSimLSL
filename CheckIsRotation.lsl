/*
BSD 3-Clause License
Copyright (c) 2019, Sara Payne (Manwa Pastorelli in virtual worlds)
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
Check If A User Input is a Rotation
===================================
Any time you need to take user input it is paramount you check they have actually put something sensible. 
All user input in Opensim comes in the form of a string, either from a notecard, listening to chat or a text box. 
This fuction takes that user input and validates it as being valid to type cast (convert) to a rotation. (quaternions not Euler).

Caveat - Only works in base 10 (decimal);
*/

integer CheckIsFloat (string inputString)
{   //checks to see if the provided string can be type cast (converted) into a float
    list allowedChars = ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "."]; //no other characters allowed in a decimal float other than "-" which is dealt with another way
    integer charOk = TRUE;
    if (llGetSubString (inputString, 0, 0) == "-") 
    {   //if this is a negative number thats ok, but we don't need it for the check, remove it. 
        inputString = llGetSubString(inputString, 1, -1); //removes the - from the start
    }//close if number is negative
    integer decimalIndex = llSubStringIndex(inputString, "."); //get the index of the decimal if one exists
    if (decimalIndex != -1)
    {   //only come here if the number has a decimal in it
        string afterFirstDecimal = llGetSubString (inputString, decimalIndex+1, -1);
        if (llSubStringIndex(afterFirstDecimal, ".") !=-1)  
        {   //come here if there is more than one . in the string... aka not a valid decimal
            charOk = FALSE; //set return value to false
        }//close if there is more than one "." 
    }//close if the string has a "."
    integer charIndex = 0;
    while (charOk && charIndex < llStringLength(inputString))
    {   //loops through the characters in the string, checking each one is part of the allowed characters
        //if any of them don't match charOK is set to false. 
        string charToCheck = llGetSubString(inputString, charIndex, charIndex); //sets the current character to check
        if(!(~llListFindList(allowedChars, (list)charToCheck))) //checks selected character against the allowed characters
        {   //come here if the character is not in the allowed characters list. 
            charOk = FALSE; //set result to FALSE
        }//close if character is not in the allowed list
        ++charIndex; //increase the character count   
    }//close while loop
    return charOk; // return TRUE/FALSE
}//close CheckIsFloat

integer CheckIsRotation (string inputString)
{   //checks to see if a string provided can be cast to a rotation, returning TRUE if it can and FALSE if it can't.
    //This function works with a CheckIsFloat method availible seperately
    integer isRot;
    string startProcess = llStringTrim ((inputString), STRING_TRIM); //remove any white space from either side of the string
    integer stringLength = llStringLength(startProcess); //find the number of characters in the string
    integer openBraceIndex = llSubStringIndex(startProcess, "<");//find the index number of the <
    integer closeBraceIndex = llSubStringIndex(startProcess, ">");//find the index number of the >
    if (openBraceIndex == 0 && closeBraceIndex == stringLength-1 )
    {   //only come here if the first character is < and the last character is >
        integer startIndex = openBraceIndex +1; //character after the <
        integer endIndex = closeBraceIndex -1; //character before the >
        startProcess = llGetSubString(startProcess, startIndex, endIndex); //removes the "<>" from the startProcess string
        list stringParts = llCSV2List(startProcess); //converts the remaining numbers which are CSV into list elements
        string strX =  llStringTrim( (llList2String(stringParts,0)), STRING_TRIM); //defines a string for X and removes any white space
        string strY =  llStringTrim( (llList2String(stringParts,1)), STRING_TRIM); //defines a string for y and removes any white space
        string strZ =  llStringTrim( (llList2String(stringParts,2)), STRING_TRIM); //defines a string for z and removes any white space
        string strS =  llStringTrim( (llList2String(stringParts,3)), STRING_TRIM); //defines a string for s and removes any white space
        integer strXIsFloat =  CheckIsFloat(strX); //returns a true or false, if its true this value is a float. 
        integer strYIsFloat =  CheckIsFloat(strY); //returns a true or false, if its true this value is a float.
        integer strZIsFloat =  CheckIsFloat(strZ); //returns a true or false, if its true this value is a float.
        integer strSIsFloat =  CheckIsFloat(strS); //returns a true or false, if its true this value is a float.
        if (strXIsFloat && strYIsFloat && strZIsFloat && strSIsFloat) isRot  = TRUE; //if all values are floats then this can be type cast into a rotation, return true
        else isRot  = FALSE; //not all values inside the <> are floats, so this can not be type cast to a rotation, set false
    }//close if containing characters are <>
    else isRot = FALSE; //first and last characters did not match rotation formatting, so it can't be a valid rotation, set to false
    return isRot; //returns true/false
}

default
{
    state_entry()
    {
        string userInputString = "<1,1,1,1>"; //sample input from a user
        integer isRotation = CheckIsRotation(userInputString); //calling the checking method
        rotation userInputRotation; // defines the new rotation for this example
        if (isRotation) 
        {   //if the method returned TRUE come here
            userInputRotation = (rotation)userInputString; //typecast the string to a rotation
        }//close if user input was a rotation
        else 
        {
            //send error to user and get them to try again . 
        }
    }
}