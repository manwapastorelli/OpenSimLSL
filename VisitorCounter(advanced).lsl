list todaysVisitors; //list contains names and grid uri as CSV (uniquire visits in the day)
list todaysVisitorsUUIDs;//list contains all unique UUIDS detected today. 
key lastCollider;//uuid of the last avi to collide with this object
integer lastDay; //day of the month at the last point we checked
integer lastMonth; //month at the year at the last point we checked
integer lastYear; //year at the last point we checked
list daysOfMonthNotecards;//used while processing change of month
list monthsOfYearNotecards; //used while processing change of year
integer totalVisitorsCalculation; //used while processing change of month
list lastPeriodsVisitors; //used while processing change of month 
list admins;//list of people allowed to access the counters menu
integer menuChannel; //channel the menu listens on
integer menuChannelListen; //handle to turn the listener on and off
key lastAdmin; //uuid of the last admin to use the menu, used to send time out warning
integer timeInterval = 30; //how frequently the sim is checked for visitors
integer menuListen; //used to aid in tracking the listener...shouldn't be needed working aorund OS bugs
list notecardsToProcess; //used when processing a new month or year, temp storage of notecard names
 
integer GetDate (string dayMonthYear) 
{   //fetches the date, and breaks it down into component parts returning the requested prt
    list dateComponents = llParseString2List(llGetDate(), ["-"], []);
    integer toReturn;
    if (dayMonthYear == "Day") toReturn = llList2Integer(dateComponents, 2);//day of month
    else if (dayMonthYear == "Month") toReturn =  llList2Integer(dateComponents, 1); //month of year
    else if (dayMonthYear == "Year") toReturn =  llList2Integer(dateComponents, 0); //year
    return toReturn; 
} //close GetDate
  
CheckDate()
{   //checks to see if the day, month or year has changed form the last check, calling appropirate methods if it has
    integer year = GetDate("Year");
    integer month = GetDate("Month");
    integer day = GetDate("Day");
    if (day != lastDay) ProcessNewDay(day, month, year);
}//close check the date 

ProcessNewDay(integer day, integer month, integer year)
{   //makes yesterdays visitors note card then resets the lists for today
    totalVisitorsCalculation = 0; //reset total visitors calc to 0 ready for next time
    ProcessLastPeriodVisitors("DayOfMonth");
    GenerateNewNoteCard("DayOfMonth");
    lastDay = day; //make last day equal today ready for tomorrow
    todaysVisitors =  []; //clear todays visitors list. 
    todaysVisitorsUUIDs = []; //clear the list of visitors uuid's
    if (lastMonth != month) ProcessNewMonth(month, year);
}//close process new day
 
ProcessNewMonth(integer month, integer year)
{
    totalVisitorsCalculation = 0; //reset total visitors calc to 0 ready for next time
    PopulateDaysAndMonthsNoteardLists("ProcessNewMonth");//clear lists and generate new ones to work from
    ProcessLastPeriodVisitors("MonthOfYear");
    GenerateNewNoteCard("MonthOfYear");
    lastMonth = month; //make last month this month ready for next month
    lastPeriodsVisitors = []; //clear to keep memory down while not processing
    totalVisitorsCalculation = 0; //reset total visitors calc to 0 ready for next time
    daysOfMonthNotecards = []; //clear list to keep memory use down
    if (year != lastYear) ProcessNewYear(year);
    else monthsOfYearNotecards = [];//change of year has not occured so this is not needed, clear to keep memory use down
}//close process new month

ProcessNewYear(integer year)
{
    totalVisitorsCalculation = 0; //reset total visitors calc to 0 ready for next time
    PopulateDaysAndMonthsNoteardLists("ProcessNewYear");//clear lists and generate new ones to work from
    ProcessLastPeriodVisitors("Year");
    GenerateNewNoteCard("Year");
    lastYear = year;
    lastPeriodsVisitors = []; //clear to keep memory down while not processing
    totalVisitorsCalculation = 0; //reset total visitors calc to 0 ready for next time
    monthsOfYearNotecards = [];//change of year has not occured so this is not needed, clear to keep memory use down
}//close process new year

ProcessLastPeriodVisitors(string type)
{
    notecardsToProcess = [];
    if (type == "DayOfMonth")
    { 
        list yesterdaysVisitors = todaysVisitors;
        string visitorsUnique = "*Unique Visitors = " + (string)llGetListLength(yesterdaysVisitors);
        string visitorsAll = "*All Visitors = " + (string)llGetListLength(yesterdaysVisitors);
        yesterdaysVisitors += visitorsUnique; //adds the line above to the list
        yesterdaysVisitors += visitorsAll; //adds the line above to the list
        if (llGetInventoryType("Yesterday") == INVENTORY_NOTECARD) llRemoveInventory("Yesterday");
        osMakeNotecard("Yesterday", yesterdaysVisitors); //save the notecard
        EnsureNotecardWritten("Yesterday"); 
        notecardsToProcess += "Yesterday";
    }
    else if (type == "MonthOfYear")
    {
        notecardsToProcess = daysOfMonthNotecards;
        daysOfMonthNotecards = []; //clear to keep memory use down
    }
    else if (type == "Year")
    {
        notecardsToProcess = monthsOfYearNotecards;
        monthsOfYearNotecards = [];//clear to keep memory down
    }
    lastPeriodsVisitors = []; //ensure the list is clear at the start 
    integer numberOfNotecardsToProcess = llGetListLength(notecardsToProcess);
    integer noteCardIndex;
    totalVisitorsCalculation = 0;
    for (noteCardIndex = numberOfNotecardsToProcess-1; noteCardIndex >= 0; noteCardIndex--)
    {
        string notecardName = llList2String(notecardsToProcess, noteCardIndex);
        ProcessVisitorsNotecard(notecardName); //adds contentents to the period list and total visitors figures preventing duplicates in the list
        llRemoveInventory(notecardName);
    } 
} 
 
ProcessVisitorsNotecard(string notecardName)
{   //loops through the named notecard, adding the total visitors together and adding new uninque visitors to a period list
    string currentLine;
    integer notecardLength = osGetNumberOfNotecardLines(notecardName);
    integer lineIndex;
    for (lineIndex = 0; lineIndex < notecardLength; lineIndex++)
    {   //loops through the selected notecard
        currentLine = osGetNotecardLine(notecardName, lineIndex);
        string firstTwoChars = llGetSubString(currentLine, 0, 1);
        if (currentLine != "")
        {
            if (firstTwoChars == "*A" || firstTwoChars == "*U") //process this line as a total for notecard
            {   //do this the long way, assume people are idiots and manually change an auto generated notecard. 
                if (firstTwoChars == "*A")
                {   //only process the all figures when adding together. 
                    integer equalsIndex = llSubStringIndex (currentLine, "="); //get the position of the equals sign
                    string strVisitors = llGetSubString(currentLine, equalsIndex+1, -1); //everything after the equals sign
                    strVisitors = llStringTrim(strVisitors, STRING_TRIM); //remove any white space
                    integer visitors = (integer) strVisitors; //convert to an integer
                    totalVisitorsCalculation += visitors; //add value to total visitors calc figure      
                }   //close if first two charas are *A
            }//close if first char is an *
            else 
            { 
                if (!(~llListFindList(lastPeriodsVisitors, (list)currentLine)))
                {   //if this visitor is not the last periods list add them
                    currentLine = osGetNotecardLine(notecardName, lineIndex);
                    lastPeriodsVisitors += currentLine;
                }//close if not on list
            }//close if line does not start with an asterix
        }//close if line is not blank
    }//close loop through notecard
}//close process visitors notecard

GenerateNewNoteCard(string notecardType)
{   //saves yesterdays vistors, clears the lists and sets last day to todays day ;
    integer lastTimePeriod; 
    if (notecardType == "DayOfMonth") lastTimePeriod = lastDay;
    else if (notecardType == "MonthOfYear") lastTimePeriod = lastMonth;
    else if (notecardType == "Year") lastTimePeriod = lastYear;
    string visitorsUnique = "*Unique Visitors = " + (string)llGetListLength(lastPeriodsVisitors);
    string visitorsAll = "*All Visitors = " + (string)totalVisitorsCalculation;
    lastPeriodsVisitors += visitorsUnique; //adds the line above to the list
    lastPeriodsVisitors += visitorsAll; //adds the line above to the list
    string tail; 
    if (lastTimePeriod < 10) tail = "0" + (string)lastTimePeriod; //keep the tail to always be 2 characters 
    else tail = (string)lastTimePeriod; //set the tail string based on the day of the month yesterday
    string notecardName = notecardType + "-" + tail;
    if (llGetInventoryType(notecardName) == INVENTORY_NOTECARD) llRemoveInventory(notecardName);
    osMakeNotecard(notecardName, lastPeriodsVisitors); //save the notecard
    EnsureNotecardWritten(notecardName);
    lastPeriodsVisitors = [];
}//close process new day 

PopulateDaysAndMonthsNoteardLists(string callingMethod)
{   //goes through the inventory making lists of the notecard names for days of the month and months of the year
    daysOfMonthNotecards = []; //ensure the list starts empty
    monthsOfYearNotecards = []; //ensure the list starts empty
    integer totalNotecards = llGetInventoryNumber(INVENTORY_NOTECARD);
    integer notecardIndex;
    for (notecardIndex = 0; notecardIndex < totalNotecards; notecardIndex++)
    {   //loops through all notecards and makes a list of the day of the month notecards
        string notecardName = llGetInventoryName(INVENTORY_NOTECARD, notecardIndex);
        integer hyphenIndex = llSubStringIndex(notecardName, "-");
        if (hyphenIndex >= 0)
        {   //only come here if the name contains a hypen, otherwise ignore as its not part of the system
            string notecardType = llGetSubString(notecardName, 0, hyphenIndex-1); //everything before the hypen
            if (notecardType == "DayOfMonth") 
            {
                daysOfMonthNotecards += notecardName; //add this card to the days of the month list
            }
            else if (notecardType == "MonthOfYear") 
            {
                monthsOfYearNotecards += notecardName; //add this card to the months of the year list
            }
            //no else as its not part of the system so gets ignored
        }//close if its a notecard belonging to the ones we need to processs
    }//close loop through all notecards
}//populate days and months lists.  

string ParseName(string detectedName)
{ // parse name so both local and hg visitors are displayed nicely
//hypergrid name example firstName.LastName@SomeGrid.com:8002
string firstName;
string lastName;
string cleanName;
integer atIndex = llSubStringIndex(detectedName, "@"); //get the index position of the "@" symbol if present
integer periodIndex = llSubStringIndex(detectedName, ".");//get the index position of the "." if present
list nameSegments;
if ((periodIndex >= 0) && (atIndex >= 0))
    {   //the detected name contains both an "@"" and "." so this avi is a hypergrid visitor
        nameSegments = llParseString2List(detectedName,[" "],["@"]);//split the dected name into two list elements
        string hGGridName = llList2String(nameSegments,0); //everything before the @ 
        nameSegments = llParseStringKeepNulls(hGGridName, [" "], ["."]); //split the hg name into two list elements
        firstName = llList2String(nameSegments,0); //retrieve the first name from the 1st index in the list
        lastName = llList2String(nameSegments,2); //retrieve  the last name form the 2nd index in the list
        cleanName = firstName + " " + lastName; //combines the names to look like a local visitors name
    }//close if hg visitor
else
    {   //this is a local visitor the name is already clean
        cleanName = detectedName;
    }//close if local visitor
return cleanName; //returns the cleaned name to the calling method
}//close parse name

SetUpListeners()
{//sets the coms channel and the random menu channel then turns the listeners on.
    menuChannel = (integer)(llFrand(-1000000000.0) - 1000000000.0); //generates random main menu channel
    menuChannelListen = llListen(menuChannel, "", NULL_KEY, "");//sets up main menu listen integer
    llListenControl (menuChannelListen, FALSE); //turns off listeners for main menu channel
}//close set up listeners

DialogAdminMenu(key aviUUID)
{   //deliver the menu to the admin provided
    list buttons = ["Visitors", "Done"]; //list of buttons on the menu
    string message = "Will deliver a folder with the visitors details in it."; //message on the menu
    llDialog(aviUUID, message, buttons, menuChannel); //delivers the actual menu
}//close deliver dialog menu

ShowVisitors (key aviUUID)
{   //adds an extra card to show todays visitors then delivers a folder of all visitor details. 
    list notecardToMake = todaysVisitors;
    integer numberOfVisitorsToday = llGetListLength(notecardToMake);
    string notecardName = "Todays-Visitors";
    string visitorsUnique = "*Unique Visitors = " + (string)numberOfVisitorsToday;
    string visitorsAll = "*All Visitors = " + (string)numberOfVisitorsToday;
    notecardToMake += visitorsUnique; //adds the line above to the list
    notecardToMake += visitorsAll; //adds the line above to the list
    if (llGetInventoryType(notecardName) != -1)
    {   //if this notecard already exists delete it
        llRemoveInventory(notecardName);
    }//close if notecard already exists
    osMakeNotecard(notecardName, notecardToMake); //save the notecard
    list itemsToDeliver = [];
    integer notecardIndex;
    for (notecardIndex = 0; notecardIndex < llGetInventoryNumber(INVENTORY_NOTECARD); notecardIndex++)
    {   //loops through all notecards in the inventory. 
        string notecardToProcess = llGetInventoryName(INVENTORY_NOTECARD, notecardIndex);
        integer hyphenIndex = llSubStringIndex(notecardToProcess, "-");
        if (hyphenIndex != -1)
        {   //ignore all notecards which do not have a hyphen in them
            string notecardType  = llGetSubString(notecardToProcess, 0, hyphenIndex-1);
            if (notecardType == "DayOfMonth" || notecardType == "MonthOfYear" || notecardType == "Year" || "Todays")
            {   //only process notecards starting with "DayOfMonth, MonthOfYear or Year
                itemsToDeliver += notecardToProcess;
            }//close if name matechs our criteria
        }//close if there is a hypen
    }//close loop through all notecards in the inventory. 
    llGiveInventoryList(aviUUID, llGetObjectName(), itemsToDeliver);
    llListenControl (menuChannelListen, FALSE); //turns off listeners for main menu channel
    menuListen = FALSE;
}//close show visitors.

ProcessInstructionLine(string instruction, string data)
{   //we only need the data, add it to the admins list
    admins += data; 
}//close process instruction line

string CleanUpString(string inputString)
{   //takes in the string provided by the sending method, removes white space and converts it to lower case then returns the string to the sending method 
    string cleanString = llStringTrim( llToLower(inputString), STRING_TRIM ); //does the clean up
    return cleanString; //returns the string to the sending method now its cleaned up  
}//close clean up string. 

ReadConfigCards(string notecardName)
{   //Reads the named config card if it exists
    if (llGetInventoryType(notecardName) == INVENTORY_NOTECARD)
    {   //only come here if the name notecard actually exists, otherwise give the user an error
        integer notecardLength = osGetNumberOfNotecardLines(notecardName); //gets the length of the notecard
        integer index; //defines the index for the next line
        for (index = 0; index < notecardLength; ++index)
        {    //loops through the notecard line by line  
            string currentLine = osGetNotecardLine(notecardName,index); //contents of the current line exactly as it is in the notecard
            string firstChar = llGetSubString(currentLine, 0,0); //gets the first character of this line
            integer equalsIndex = llSubStringIndex(currentLine, "="); //gets the position of hte equals sign on this line if it exists
            if (currentLine != "" && firstChar != "#" && equalsIndex != -1 )
            {   //only come here if the line has content, it does not start with # and it contains an equal sign
                string instruction = llGetSubString (currentLine, 0, equalsIndex-1); //everything before the equals sign
                string data = llGetSubString(currentLine, equalsIndex+1, -1); //everything after the equals sign    
                instruction = CleanUpString (instruction); //sends the instruvtion to the cleanup method to remove white space and turn to lower case
                data = CleanUpString (data); //sends the data to the cleanup method to remove white space and turn to lower case
                ProcessInstructionLine(instruction, data); //sends the instruction and the data to the Process instruction method
            }//close if the line is valid
            else
            {   //come here if the above condition is not met
                if ( (currentLine != "") && (firstChar != "#") && (equalsIndex == -1))
                {   // if the line is not blank and it does not begin with a #, and there is no = sign send an error telling the user which line is invalid. 
                    //llOwnerSay("Line number: " + (string)index + " is malformed. It is not blank, and does not begin with a #, yet it contains no equals sign.");
                }//close line is invalid
            }//close invalid line
        }
    }//close if the notecard exists
    else 
    {   //the named notecard does not exist, send an error to the user. 
        //llOwnerSay ("The notecard called " + notecardName + " is missing, auto generating one with just the owner added");
        list newNotecardContents = ["# Allowed Admins", llGetOwner()];
        osMakeNotecard(notecardName, newNotecardContents); //save the notecard
    }//close error the notecard does not exist
}//close read config card. 

ProcessDetectedAvatars()
{   //processes avatars detected by either the region list or collission event. 
    list avatarsInRegion = llGetAgentList(AGENT_LIST_REGION, []); //generates a list of all avatar uuids in the region
    integer avatarIndex;
    for (avatarIndex = 0; avatarIndex < llGetListLength(avatarsInRegion); avatarIndex++)
    {   //loop through all detected avis
        key uuidToCheck = llList2Key(avatarsInRegion, avatarIndex); //avi we are currently dealing with
        string aviName = llKey2Name(uuidToCheck);
        string cleanName = ParseName (aviName); //get avi name without hg stuff if present
        if (!(~llListFindList(todaysVisitorsUUIDs, (list)uuidToCheck)))
        {   //if avi has not already visited today add them to both daily visitors and UUID lists
            todaysVisitorsUUIDs += uuidToCheck; //add this uuid to the list of visitors today, has to be uuid as names could match with hg visitors
            string homeUri = osGetAvatarHomeURI(uuidToCheck);//get the avatars home grid
            string newVisitor = cleanName + "," + homeUri; //this is the line we add to the visitors list
            todaysVisitors += newVisitor;//add the line abive to todays visitors list. 
        }//close if not on the list already
    }//close loop through detected list
}//close process avatars in region 

EnsureNotecardWritten(string notecardName)
{   //holds the scrit in a loop untill the card is written
    integer notecardWritten = FALSE;
    while (!notecardWritten)
    {   //if the status is not written come here
        if (llGetInventoryType(notecardName) == INVENTORY_NOTECARD) notecardWritten = TRUE; //change to true if its written
    }  //close while not written 
}//close ensure notecard is written. 

default
{
    changed( integer change )
    {   //if we have been moved to a new region or changed owne reset the script
        if (change & (CHANGED_OWNER | CHANGED_REGION)) llResetScript();
    }//close changed

    state_entry()
    {
        osVolumeDetect(TRUE); //makes item volumetric
        SetUpListeners();
        //start fake test data
        //==========================
        //lastYear = 2018;
        //lastMonth = 09;
        //lastDay = 23;
        //==========================
        //end fake test data
        lastYear = GetDate("Year");
        lastMonth = GetDate("Month");
        lastDay = GetDate("Day");
        llSetTimerEvent(timeInterval); //every 30 mins
    }//close state entry

    collision_start(integer total_number)
    {
        integer detectedType = llDetectedType(0);
        if (detectedType == 1 || detectedType == 3 || detectedType == 5)
        {   //only process avatars, no bots or physical objects
            key detectedUUID = llDetectedKey(0);
            if (detectedUUID != lastCollider)
            {   //if this is the same avi just standing on the dector don't process them
                lastCollider = detectedUUID;
                ProcessDetectedAvatars();
            }//close if not last collider
        }//close if detected type is an avatar
    }//close collision event

    touch_start(integer num_detected)
    {   //come here any time the object is clicked
         admins = [];
         ReadConfigCards("Admin");
         key toucher = llDetectedKey(0);
         if (~llListFindList(admins, (list)toucher))
         {  //if the toucher is on the admin list deliver the menu
             lastAdmin = toucher; //store the last admin toucher incase of a time out. 
             llListenControl (menuChannelListen, TRUE); //turns on listeners for main menu channel
             menuListen = TRUE;
             DialogAdminMenu(toucher);
         }//close if toucher is on list
         else llRegionSayTo(toucher, PUBLIC_CHANNEL, "Sorry you are not on the admin list and can not use this item.");
    }//close touch start event 

    listen( integer channel, string name, key id, string message )
    {
        if (channel == menuChannel)
        {   //come here if the channel is the menu channel
            if (~llListFindList(admins, (list)id))
            {   //if avi sending the message is on the admins list send them the menu
                if (message == "Visitors") ShowVisitors(id);
            }//close if found on admins list
        }//close channel is the menu channel
    }//close listen
 
    timer()
    {   //come here based on the timer event time 
        if (menuListen)
        {   //come here if the menu listener is on
            menuListen = FALSE;//set listener tracker to false
            llRegionSayTo(lastAdmin, PUBLIC_CHANNEL, "Menu timed out, please click again"); //warn the last user
            llListenControl (menuChannelListen, FALSE); //turns on listeners for main menu channel
        }//close if menu listener is on
        ProcessDetectedAvatars(); //scan the sim and process all found avis
        CheckDate(); //check the date to see if its a new day, if it is process the changes (includes month/year if they also changed)
    }//close timer
}//close state default 