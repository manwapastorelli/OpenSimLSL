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

integer CheckIsInteger (string inputString)
{   //checks to see if a string can be parsed into an integer and returns true or false
    integer isInt;
    integer length;
    length = llStringLength(inputString);
    string firstChar = llGetSubString(inputString, 0, 0);
    while (length > 1 && firstChar == "0" )
    {   //ignore any 0's at the start of the string but not if its the only character
        inputString = llGetSubString(inputString, 1, -1); //get everything after the frist 0
        firstChar = llGetSubString(inputString, 0, 0); //set the new first character again
        length = llStringLength(inputString);//get the string length again
    }//close while string has more than 1 char
    integer chkInt = (integer)inputString; //type cast to integer
    string chkStr = (string)chkInt; // type cast back to string
    if (inputString == "") isInt = FALSE; //set false if string is blank
    else if (chkStr == inputString) isInt = TRUE; //if strings match set true
    else isInt = FALSE; //if they dont match set false
    return isInt; //return bool
}//close check is int

default
{
    state_entry()
    {
        string userInputString = "12345"; //sample input from a user
        integer isInteger = CheckIsInteger(userInputString); //calling the checking method
        integer userInputInteger; // defines the new rotation for this example
        if (isInteger) 
        {   //if the method returned TRUE come here
            userInputInteger = (integer)userInputString; //typecast the string to a rotation
        }//close if user input was a rotation
        else 
        {
            //send error to user and get them to try again . 
        }
    }
}