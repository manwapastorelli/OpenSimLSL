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
Covey Dynamic Dialog Menu System
=================================
Display a menu of any number of buttons dynamically across multiple pages

The system assumes you have two lists of buttons. Some fixed which must be in every page of your menu and the dynamic buttons. 

The reserved buttons must include next and back

The main call point for the menu is in the touch_start event
*/

//Menu Lists, Dynamic Buttons, Reserved Buttons and a temp list used to display the menu
list menuButtons = ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "10", "11", "12", "13", "14", "15", "16", "17", "18", "19", "20", "21", "22", "23", "24"]; //menu buttons list
list reservedButtons = ["Next", "Back"]; // permanant buttons on the menu
list tempMenuButtons; //used to store temp menu entries.This is the list which gets displayed in the dialog statement.
//variables used in creating the dynaic menus
integer numOfPages; //used to store the total number of pages in this menu
integer dynamicButtonsPerPage; //the number of spaces left after the reserved buttons
integer reservedButtonsPerPage; //number of reserved buttoons per page
integer currentPageNumber; //used to store the current page number
integer menuLength; //used to store the length of the menu being worked on
//Listeners used for hearing menu button entries
integer mainMenuChannel; //global integer for menu channel
integer mainMenuChannelListen;//clobal control integer for turning menu listen on and off
//Other Variables
key user; //uuid of who ever is using the menu
string menuMessage = "You are viewing page "; //message to display in the dialog menu


SetUpListeners()
{//sets the coms channel and the random menu channel then turns the listeners on.
mainMenuChannel = (integer)(llFrand(-1000000000.0) - 1000000000.0); //generates random main menu channel
mainMenuChannelListen = llListen(mainMenuChannel, "", NULL_KEY, "");//sets up main menu listen integer
llListenControl (mainMenuChannelListen, TRUE); //turns on listeners for main menu channel
}//close set up listeners

integer CalcPagesInMenu(list inputList)
{ // works out the total number of pages needed allowing two buttons for forwards and backwards
    reservedButtonsPerPage = llGetListLength(reservedButtons); // how many button spaces per page we need to reserve
    dynamicButtonsPerPage = 12-reservedButtonsPerPage;  //subtract the reserve from the total availible of 12
    numOfPages = (integer)(menuLength /dynamicButtonsPerPage); // 2 buttons for next and back with 1p per page and an extra page for any remainders
    if (menuLength%dynamicButtonsPerPage > 0) ++numOfPages; //if there is any remainder after dividing the number of buttons by 10 addd on another page
    return numOfPages; //returns the number of pages
}//close calculate pages in menu

GenTempMenuList(list inputList)
{ // generates the temp menu buttons (the ones for the current page)
    tempMenuButtons = []; //makes sure the list is blank before we start
    integer firstIndex = currentPageNumber*dynamicButtonsPerPage; //uses the page number to work out the start index in the menu buttons list
    integer lastIndex = firstIndex + dynamicButtonsPerPage-1; // calculates the last index in the menu buttons list
    if (lastIndex >= llGetListLength(inputList)) lastIndex = llGetListLength(inputList) -1; //don't add extra blank buttons for no good reason
    integer i; 
    for ( i = firstIndex; i <= lastIndex; ++ i)
    {   // adds each of the index is the range calculated to the temp buttons list
        tempMenuButtons += llList2String(inputList,i); 
    }
    AddReservedButtonsToTempMenu(); //adds the reserved buttons to the temp buttons list
} //close generate temp menu list

AddReservedButtonsToTempMenu()
{ // loops through the reserved buttons and adds them to the temp list
    integer i;
    for (i = 0; i < llGetListLength(reservedButtons); ++i)
    {
        tempMenuButtons += llList2String (reservedButtons, i);
    }
}//close add reserved buttons to temp list

DialogueMenu(list inputList)
{ //displays a big list of buttons dynamially over many pages 
menuLength = llGetListLength (inputList);
if  (menuLength <= 12 - llGetListLength(reservedButtons)) 
    { // come here if the dynamic buttons and reserved buttons fit on one page
        tempMenuButtons = inputList; // make the temp list the same as the main list
        AddReservedButtonsToTempMenu(); //add the reserved buttons
    } // close if everything fits on one page
else
    {   //work out the menu structure and display the requested page number
        numOfPages = CalcPagesInMenu(inputList); 
        if ( currentPageNumber >= numOfPages) currentPageNumber = 0; // these two lines make sure the page number never goes out of range;
        else if (currentPageNumber < 0) currentPageNumber = numOfPages-1; //counting starts from 0 so the last page is 1 less than the total number of pages 
        GenTempMenuList(inputList); //gen list and pass the menu to process from   
    }
string pageMessage = menuMessage + " " + (string)(currentPageNumber+1) + " of " + numOfPages;
llDialog(user, pageMessage, tempMenuButtons, mainMenuChannel); //display the current page in the dialog
//llOwnerSay("Debug: Current Page Buttons: \n" + llList2CSV(tempMenuButtons));
}// close display dialogue menu

ProcessMenuResponse(string message)
{ // processes responses to the listen event
    if (message == llList2String(reservedButtons, 0) )
    {
        ++ currentPageNumber; //button in this example is Next to add 1 to the page number and call the menu again
        DialogueMenu(menuButtons); //call the menu again
    }
    else if (message == llList2String(reservedButtons, 1))
    {
        -- currentPageNumber; // button in this example is back so subtract 1 from the page number 
        DialogueMenu(menuButtons); //call the menu again
    }
    else 
        {   // come here if pressed button is not in the reserved list
            if(~llListFindList(menuButtons, (list)message))
            {   //come her if the button pressed is in the dynamic buttons list
                llRegionSayTo(user, PUBLIC_CHANNEL, "A dynamic button was pressed");
            }
            else llOwnerSay ("Debug: Unknown button pressed");
        }
}// close process messages from the listen event

default
{
    state_entry()
    {   //come here once when the scrip first runs
        SetUpListeners(); // sets up the listeners
        currentPageNumber = 0; //sets the page number to 0 when the script is frist run
    } // close state entry
    
    touch_start(integer count)
    { //someones touched the prim
        user = llDetectedKey(0); //stores the uuid of the person who touched me
        DialogueMenu(menuButtons); // to use a different list just change menu buttons to what ever list you wish to use for your menu
    }// close touch start
    
    listen (integer channel, string name, key id, string message)
    { // listens for inputs from the dialog menu
        if (llGetOwnerKey(id) == llGetOwner() && channel == mainMenuChannel); 
        {  //if the message heard is on the correct channel and the objects owner is the same as this objects owner process the message
            ProcessMenuResponse(message); //sends the heard message to the process method
        }// close if owner and channel number match
    }//close listen
}// close state default
 
