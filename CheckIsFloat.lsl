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
Check If A User Input is a Float
================================
Any time you need to take user input it is paramount you check they have actually put something sensible. 
All user input in Opensim comes in the form of a string, either from a notecard, listening to chat or a text box. 
This fuction takes that user input and validates it as being valid to type cast (convert) to a float (decimal number).

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

default
{
    state_entry()
    {
        string userInputString = "123.567"; //sample input from a user
        integer isFloat = CheckIsFloat(userInputString); //calling the checking method
        float userInputFloat; // defines the new rotation for this example
        if (isFloat) 
        {   //if the method returned TRUE come here
            userInputFloat = (float)userInputString; //typecast the string to a rotation
        }//close if user input was a rotation
        else 
        {
            //send error to user and get them to try again . 
        }
    }
}