/*
Drop this script into any object (you will need to own it unless you have edit rights on the person who does). Then click the textre you want intofmation about. It will read out the details in local chat. You will need to stand within 20m of the item at the time. It is set to normal chat instead of owner so people working collaboratively can see it together. 
*/

string ReturnTextureDetails(integer link, integer face)
{
    list linkParamList = llGetLinkPrimitiveParams(link,[PRIM_NAME, PRIM_DESC, PRIM_TEXTURE, face, PRIM_NORMAL, face, PRIM_SPECULAR, face, PRIM_COLOR, face, PRIM_GLOW, face]);
    string primName = llList2String(linkParamList,0);
    string primDesc = llList2String(linkParamList,1);
    string primDiffuse;
    if (primName == "BtnEyes0") primDiffuse = "52cc6bb6-2ee5-e632-d3ad-50197b1dcb8a"; //IMG_USE_BAKED_EYES
    else if (primName == "BtnHead0") primDiffuse = "5a9f4a74-30f2-821c-b88d-70499d3e7183"; //IMG_USE_BAKED_HEAD
    else if (primName == "BtnUpper0") primDiffuse = "ae2de45c-d252-50b8-5c6e-19f39ce79317"; //IMG_USE_BAKED_UPPER
    else if (primName == "BtnLower0") primDiffuse = "24daea5f-0539-cfcf-047f-fbc40b2786ba"; //IMG_USE_BAKED_LOWER
    else primDiffuse = llList2String(linkParamList,2);
    string primNormal = llList2String(linkParamList, 6);
    string primSpecular = llList2String(linkParamList, 10);
    string primSpecColor = llList2String(linkParamList, 14);
    string primSpecGloss = llList2String(linkParamList, 15);
    string primSpecEnvir = llList2String(linkParamList, 16);
    string primColor = llList2String(linkParamList, 17);
    string primGlow = llList2String(linkParamList, 18);
    string textreDetails =  primDiffuse + "," + 
                            primNormal + "," + 
                            primSpecular + "," +
                            primSpecColor + "," +
                            primSpecGloss + "," +
                            primSpecEnvir + "," + 
                            primColor + "," +
                            primGlow;
    return textreDetails;
}

default
{
    touch_start(integer dont_care)
    {
        integer linkNo = llDetectedLinkNumber(0);
        integer touchedFace = llDetectedTouchFace(0);
        string detailsString = ReturnTextureDetails(linkNo, touchedFace);
        list textureDetails = llCSV2List(detailsString);
        llSay(0, "Diffuse UUID: " + llList2String(textureDetails,0));
        llSay(0, "Normal UUID: " + llList2String(textureDetails,1));
        llSay(0, "Specular UUID: " + llList2String(textureDetails,2));
        llSay(0, "Colour: " + llList2String(textureDetails,3));
        llSay(0, "Gloss: " + llList2String(textureDetails,4));
        llSay(0, "Enviroment: " + llList2String(textureDetails,5));
        llSay(0, "Specular Colour: " + llList2String(textureDetails,6));
        llSay(0, "Glow: " + llList2String(textureDetails,7));
    }
}
