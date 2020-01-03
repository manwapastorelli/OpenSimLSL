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

//Touch anywhere on an object to get details about where you touched, ie link number, face number, uv position etc

default
{
    touch_start(integer total_number)
    {   
        integer linkNo = llDetectedLinkNumber(0);
        integer touchedFace = llDetectedTouchFace(0);
        vector touchedUVPos = llDetectedTouchUV(0);
        list primInfo = llGetLinkPrimitiveParams(linkNo,    
            [  
                PRIM_POS_LOCAL, 
                PRIM_ROT_LOCAL, 
                PRIM_SIZE, 
                PRIM_TEXTURE, touchedFace 
            ]);
        vector localPosition = llList2Vector(primInfo,0);
        rotation localRotation = llList2Rot(primInfo,1) ;
        vector primSize = llList2Vector(primInfo,2);
        string faceTexture = llList2String(primInfo, 3);
        llSay(0, " Link No: " +(string)linkNo + 
                 "\n Face No: " + (string)touchedFace +
                 "\n Texture: " + faceTexture +  
                 "\n UV Pos: " + (string)touchedUVPos +  
                 "\n local pos " + (string)localPosition +     
                 "\n local rotatoin " + (string)localRotation  + 
                 "\n Size " + (string)primSize);
    }
}