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
integer menuChannel;
integer menuChannelListen;
 
CheckDate()
{   //checks to see if the day, month or year has changed form the last check, calling appropirate methods if it has
    list dateComponents = llParseString2List(llGetDate(), ["-"], []);
    integer year  = llList2Integer(dateComponents, 0);
    integer month = llList2Integer(dateComponents, 1);
    integer day   = llList2Integer(dateComponents, 2);
    if (year != lastYear)
    {   //change of year has occured, so it must also be a new day and a new month. Do them all in order
        ProcessNewDay(day);
        ProcessNewMonth(month, year);
        ProcessNewYear(year);
    }
    else if (month =! lastMonth)
    {   //a change of month has occured, so it must also be a new day, process both doing the daily update first
        ProcessNewDay(day);
        ProcessNewMonth(month, year);
    }
    else if (day != lastDay)
    {   //a change of day has occured, process a new day
        ProcessNewDay(day);
    }
}//close check the date

ProcessNewDay(integer day)
{   //makes yesterdays visitors note card then resets the lists for today
    GenerateNewNoteCard("DayOfMonth", lastDay);
    lastDay = day; //make last day equal today ready for tomorrow
    todaysVisitors =  []; //clear todays visitors list. 
    todaysVisitorsUUIDs = []; //clear the list of visitors uuid's
}//close process new day

ProcessNewMonth(integer month, integer year)
{
    PopulateDaysAndMonthsNoteardLists();//clear lists and generate new ones to work from
    ProcessLastPeriodVisitors("DayOfTheMonth");
    GenerateNewNoteCard("MonthOfYear", lastMonth);
    lastMonth = month; //make last month this month ready for next month
    lastPeriodsVisitors = []; //clear to keep memory down while not processing
    totalVisitorsCalculation = 0; //reset total visitors calc to 0 ready for next time
    daysOfMonthNotecards = []; //clear list to keep memory use down
    if (year == lastYear) monthsOfYearNotecards = [];//change of year has not occured so this is not needed, clear to keep memory use down
}//close process new month

ProcessNewYear(integer year)
{
    ProcessLastPeriodVisitors("Year");
    GenerateNewNoteCard("MonthOfYear", lastYear);
    lastYear = year;
    lastPeriodsVisitors = []; //clear to keep memory down while not processing
    totalVisitorsCalculation = 0; //reset total visitors calc to 0 ready for next time
    monthsOfYearNotecards = [];//change of year has not occured so this is not needed, clear to keep memory use down
}

ProcessLastPeriodVisitors(string type)
{
    list notecardsToProcess;
    if (type == "MonthOfYear")
    {
        notecardsToProcess = monthsOfYearNotecards;
        monthsOfYearNotecards = [];//clear to keep memory down
    }
    else if (type == "DayOfMonth")
    {
        notecardsToProcess = daysOfMonthNotecards;
        daysOfMonthNotecards = []; //clear to keep memory use down
    }
    list lastPeriodsVisitors = []; //ensure the list is clear at the start
    integer listLength = llGetListLength(notecardsToProcess);
    integer listIndex;
    for (listIndex = listLength-1; listIndex >= 0; listIndex--)
    {
        string notecardName = llList2String(notecardsToProcess, listIndex);
        totalVisitorsCalculation = 0;
        ProcessVisitorsNotecard(notecardName); //adds contentents to the period list and total visitors figures preventing duplicates in the list
        llRemoveInventory(notecardName);
    }
}

GenerateNewNoteCard(string notecardType, integer DayOrMonthOrYear)
{   //saves yesterdays vistors, clears the lists and sets last day to todays day 
    string visitors ;
    if (notecardType == "DayOfMonth" ) 
    {
        lastPeriodsVisitors = todaysVisitors;
        todaysVisitors = [];//clear todays visitors now to keep memory use down
        visitors = (string)llGetListLength(todaysVisitors);
    }
    else visitors = (string)llGetListLength(lastPeriodsVisitors);
    string totalVisitorsLine = "**Total Visitors = " + visitors; //sets the line to add to the visitors list
    lastPeriodsVisitors += totalVisitorsLine; //adds the line above to the list
    string tail; 
    if (DayOrMonthOrYear < 10) tail = "0" + (string)lastDay; //keep the tail to always be 2 characters 
    else tail = (string)DayOrMonthOrYear; //set the tail string based on the day of the month yesterday
    string noteCardName = notecardType + "-" + tail;
    osMakeNotecard(noteCardName, lastPeriodsVisitors); //save the notecard
}//close process new day

ProcessVisitorsNotecard(string notecardName)
{   //loops through the named notecard, adding the total visitors together and adding new uninque visitors to a period list
    string currentLine;
    integer notecardLength = osGetNumberOfNotecardLines(notecardName);
    integer lineIndex;
    for (lineIndex = 0; lineIndex < notecardLength; lineIndex++)
    {   //loops through the selected notecard
        currentLine = osGetNotecardLine(notecardName, lineIndex);
        string firstChar = llGetSubString(currentLine, 0, 0);
        if (firstChar == "*") //process this line as a total for notecard
        {   //do this the long way, assume people are idiots and manually change an auto generated notecard. 
            integer equalsIndex = llSubStringIndex (currentLine, "="); //get the position of the equals sign
            string strVisitors = llGetSubString(currentLine, equalsIndex+1, -1); //everything after the equals sign
            strVisitors = llStringTrim(strVisitors, STRING_TRIM); //remove any white space
            integer visitors = (integer) strVisitors; //convert to an integer
            totalVisitorsCalculation += visitors; //add value to total visitors calc figure
        }//close if first char is an *
        else if (firstChar != "")
        {   //auto generated notecards always add a blank line, ensure we don't process this
            if (!(~llListFindList(lastPeriodsVisitors, (list)currentLine)))
            {   //if this visitor is not the last periods list add them
                currentLine = osGetNotecardLine(notecardName, lineIndex);
                lastPeriodsVisitors += currentLine;
            }//close if not on list
        }//close if line is not blank    
    }//close loop through notecard
}//close process visitors notecard

PopulateDaysAndMonthsNoteardLists()
{   //goes through the inventory making lists of the notecard names for days of the month and months of the year
    list daysOfMonthNotecards = []; //ensure the list starts empty
    list monthsOfYearNotecards = []; //ensure the list starts empty
    integer totalNotecards = llGetInventoryNumber(INVENTORY_NOTECARD);
    integer notecardIndex;
    for (notecardIndex = 0; notecardIndex < totalNotecards; notecardIndex++)
    {   //loops through all notecards and makes a list of the day of the month notecards
        string notecardName = llGetInventoryName(INVENTORY_NOTECARD, notecardIndex);
        integer hyphenIndex = llSubStringIndex(notecardName, "-");
        if (hyphenIndex != -1)
        {   //only come here if the name contains a hypen, otherwise ignore as its not part of the system
            string notecardType = llGetSubString(notecardName, 0, hyphenIndex-1); //everything before the hypen
            if (notecardType == "DayOfMonth") daysOfMonthNotecards += notecardName; //add this card to the days of the month list
            else if (notecardType == "MonthOfYear") monthsOfYearNotecards += notecardName; //add this card to the months of the year list
            //no else as its not part of the system so gets ignored
        }//close if its a notecard belonging to the ones we need to processs
    }//close loop through all notecards
}//populate days and months lists. 

ProcessDetectedAvatars()
{   //processes avatars detected by either the region list or collission event. 
    list avatarsInRegion = llGetAgentList(AGENT_LIST_REGION, []); //generates a list of all avatar uuids in the region
    integer avatarIndex;
    for (avatarIndex = 0; avatarIndex < llGetListLength(avatarsInRegion); avatarIndex++)
    {   //loop through all detected avis
        key uuidToCheck = llList2Key(avatarsInRegion, avatarIndex); //avi we are currently dealing with
        string aviName = ParseName (llKey2Name(uuidToCheck)); //get avi name without hg stuff if present
        if (!(~llListFindList(todaysVisitorsUUIDs, (list)uuidToCheck)))
        {   //if avi has not already visited today add them to both daily visitors and UUID lists
            todaysVisitorsUUIDs += uuidToCheck; //add this uuid to the list of visitors today, has to be uuid as names could match with hg visitors
            string homeUri = osGetAvatarHomeURI(uuidToCheck);//get the avatars home grid
            string newVisitor = aviName + "," + homeUri; //this is the line we add to the visitors list
            todaysVisitors += newVisitor;//add the line abive to todays visitors list. 
        }//close if not on the list already
    }//close loop through detected list
}//close process avatars in region

string ParseName(string detectedName)
{ // parse name so both local and hg visitors are displayed nicely
//hypergrid name example firstName.LastName@SomeGrid.com:8002
string firstName;
string lastName;
string cleanName;
integer atIndex = llSubStringIndex(detectedName, "@"); //get the index position of the "@" symbol if present
integer periodIndex = llSubStringIndex(detectedName, ".");//get the index position of the "." if present
list nameSegments;
if ((periodIndex != -1) && (atIndex =! -1))
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
{
    list buttons = ["Visitors", "Done"];
    string message = "Will deliver a folder with the visitors details in it.";
    llDialog(aviUUID, message, buttons, menuChannel); 
}

ShowVisitors (key aviUUID)
{   //adds an extra card to show todays visitors then delivers a folder of all visitor details. 
    list notecardToMake = todaysVisitors;
    integer numberOfVisitorsToday = llGetListLength(todaysVisitors);
    string notecardName = "Todays-Visitors";
    string totalVisitorsLine = "**Total Visitors = " + (string)numberOfVisitorsToday; //sets the line to add to the visitors list
    notecardToMake += totalVisitorsLine; //adds the line above to the list
    osMakeNotecard(notecardName, notecardToMake); //save the notecard
    list itemsToDeliver = [];
    integer notecardIndex;
    for (notecardIndex = 0; notecardIndex < llGetInventoryNumber(INVENTORY_NOTECARD); notecardIndex++)
    {
        string notecardToProcess = llGetInventoryName(INVENTORY_NOTECARD, notecardIndex);
        integer hyphenIndex = llSubStringIndex(notecardName, "-");
        if (hyphenIndex != -1)
        {   //ignore all notecards which do not have a hyphen in them
            string notecardType  = llGetSubString(notecardToProcess, 0, hyphenIndex-1);
            if (notecardType == "DayOfMonth" || notecardType == "MonthOfYear" || notecardType == "Year")
            {   //only process notecards starting with "DayOfMonth, MonthOfYear or Year
                itemsToDeliver += notecardToProcess;
            }//close if name matechs our criteria
        }//close if there is a hypen
    }//close loop through all notecards in the inventory. 
    llGiveInventoryList(aviUUID, llGetObjectName(), itemsToDeliver);
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
                    llOwnerSay("Line number: " + (string)index + " is malformed. It is not blank, and does not begin with a #, yet it contains no equals sign.");
                }//close line is invalid
            }//close invalid line
        }
    }//close if the notecard exists
    else 
    {   //the named notecard does not exist, send an error to the user. 
        llOwnerSay ("The notecard called " + notecardName + " is missing, please address this");
    }//close error the notecard does not exist
}//close read config card. 

 

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
        admins = [];
        ReadConfigCards("admin");
        llSetTimerEvent(1800); //every 30 mins
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
    {
         key toucher = llDetectedKey(0);
         if (~llListFindList(admins, (list)toucher))
         {
             llListenControl (menuChannelListen, FALSE); //turns on listeners for main menu channel
             DialogAdminMenu(toucher);
         }
    }

    listen( integer channel, string name, key id, string message )
    {
        if (channel == menuChannel)
        {
            if (~llListFindList(admins, (list)id))
            {
                if (message == "Visitors") ShowVisitors (id);
            }
        }
    }

    timer()
    {   //come here based on the timer event time 
        ProcessDetectedAvatars();
        CheckDate();
    }//close timer
}//close state default