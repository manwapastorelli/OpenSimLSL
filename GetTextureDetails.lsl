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
