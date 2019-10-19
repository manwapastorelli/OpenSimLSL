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

list sze;
list local_pos;
vector Size;
vector local_Position;
integer i;
integer j;
integer linkNo;
list local_rot;
rotation local_rotation;
integer TouchedFace;
vector TouchedUVPos;
 
default
{
    touch_start(integer total_number)
    {   
        linkNo = llDetectedLinkNumber(0);
        TouchedFace = llDetectedTouchFace(0);
        TouchedUVPos = llDetectedTouchUV(0);
        local_pos = llGetLinkPrimitiveParams(linkNo, [ PRIM_POS_LOCAL ]);
        local_rot = llGetLinkPrimitiveParams(linkNo, [ PRIM_ROT_LOCAL ]);
        local_Position =(llList2Vector(local_pos,i));
        local_rotation =(llList2Rot(local_rot,j)) ;
        sze = llGetLinkPrimitiveParams(linkNo, [ PRIM_SIZE ]);
        Size =(llList2Vector (sze,i));
        local_Position = llList2Vector(local_pos,i);
        llSay(0, " Link No: " +(string)linkNo + 
                 "\n Face No: " + (string)TouchedFace + 
                 "\n UV Pos: " + (string)TouchedUVPos +  
                 "\n local pos " + (string)local_Position +     
                 "\n local rotatoin " + (string)local_rotation  + 
                 "\n Size " + (string)Size);
    }
} 