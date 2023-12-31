#define CLIENT_ONLY

#include "OggPlayer.as";

Random rnd(32141234);
 
const string stereo = "StereoPlayer.png";
 
const f32 HUD_X = getScreenWidth()/2;
const f32 HUD_Y = getScreenHeight();

Vec2f buttonframesize = Vec2f(16,16);
Vec2f longbuttonframesize = Vec2f(32,16);
 
//Vec2f letterpos; 
const SColor litcolor(255, 0, 255, 255);
const SColor halflitcolor(255, 130, 255, 130);

string song_name = "";

class StereoButton
{
    Vec2f Offset;
    Vec2f Size;
    bool toggled;

    StereoButton(Vec2f _posoff, Vec2f _size)
    {
        Offset = _posoff;
        Size = _size;
        toggled = false;
    }

    bool MouseOverMe(Vec2f menuPos, Vec2f mousePos)
    {
        if (mousePos.x > (menuPos.x+Offset.x+Size.x) || mousePos.y < (menuPos.y+Offset.y) || mousePos.y > (menuPos.y+Offset.y+Size.y) || mousePos.x < (menuPos.x+Offset.x) )
        {
            return false;
        }
        return true;
    }
}

class StereoPlayer
{
    Vec2f Position;
    Vec2f Size;
    int ChannelSelected;
    bool isShowing;

    string trackName;
    uint trackNum;

    uint baseTrackCount;
    uint modTrackCount;
    uint userTrackCount;

    f32 timer;
    u8 substr_letters;
    f32 offset;

    StereoButton@ OpenButton;
    StereoButton@ BackButton;
    StereoButton@ StopButton;
    StereoButton@ NextButton;
    StereoButton@ VolUButton;
    StereoButton@ VolDButton;
    StereoButton@ ShufButton;
    StereoButton@ Cha1Button;
    StereoButton@ Cha2Button;
    StereoButton@ Cha3Button;

    bool mouse_over_menu;
    bool cameraLocked;
    int buttonHoverNum;

    StereoPlayer()
    {
        Position = Vec2f(1, HUD_Y-128);
        Size = Vec2f(183,150);

        timer = 0;
        substr_letters = 0;
        offset = 0;

        isShowing = true;
        mouse_over_menu = false;
        buttonHoverNum = 0;
        //cameraLocked = false;

        @OpenButton = StereoButton(Vec2f(157, 7), Vec2f(24, 24));
        @BackButton = StereoButton(Vec2f( 10, 100), Vec2f(50, 28));
        @StopButton = StereoButton(Vec2f( 54, 100), Vec2f(50, 28));
        @NextButton = StereoButton(Vec2f(98, 100), Vec2f(50, 28));
        @VolUButton = StereoButton(Vec2f(158,40), Vec2f(24, 24));
        @VolDButton = StereoButton(Vec2f(158,64), Vec2f(24, 24));
        @ShufButton = StereoButton(Vec2f(158,98), Vec2f(24, 24));
        @Cha1Button = StereoButton(Vec2f( 10, 72), Vec2f(50, 28));
        @Cha2Button = StereoButton(Vec2f( 54, 72), Vec2f(50, 28));
        @Cha3Button = StereoButton(Vec2f( 98, 72), Vec2f(50, 28));

        setupTracks();
    }

    void setupTracks()
    {
        CMixer@ mixer = getMixer();
        if (mixer is null)
            return;

        mixer.ResetMixer();
        rnd.Reset(Time());

        uint i = 0;
        //base tracks
        {
            const string based = "Sounds/Music/.ogg";
            CFileMatcher@ files = CFileMatcher(based);
            while (files.iterating())
            {
                const string filename = files.getCurrent();                  
                string[]@  filepath = filename.split("/");
                if (filepath[0] == "Sounds" && filepath[1] == "Music")
                {   
                    mixer.AddTrack(filepath[2], i);
                    string[]@  shortname = filepath[2].split(".");
                    TrackNames.push_back(shortname[0]);
                    i++;
                }
            }
            baseTrackCount = i;
        }

        //mod tracks
        {
            mixer.AddTrack("../Mods/OggPlayer/Music/Thousand Foot Krutch ~ Phenomenon.ogg", i);
            TrackNames.push_back("Thousand Foot Krutch ~ Phenomenon");
            i++;
            modTrackCount = i-baseTrackCount;
        }

        //user tracks
        {
            CFileMatcher@ files = CFileMatcher("Maps/Music/.ogg");
            //files.printMatches();
            while (files.iterating())
            {
                const string filename = files.getCurrent();  
                string[]@  filepath = filename.split("/");
                if (filepath.size() == 3 && filepath[0] == "Maps" && filepath[1] == "Music")
                {   
                    mixer.AddTrack(filepath[2], i);
                    string[]@  shortname = filepath[2].split(".");
                    TrackNames.push_back(shortname[0]);
                    i++;
                }
            }
            userTrackCount = i-modTrackCount-baseTrackCount ;
        }

        if (TrackNames.size() > baseTrackCount+modTrackCount)
        {
            trackNum = baseTrackCount+modTrackCount;
            trackName = TrackNames[trackNum];
            mixer.StopAll();
            mixer.FadeInRandom(trackNum , 5.0f); 

            Cha3Button.toggled = true;
        }
        else if (TrackNames.size() > baseTrackCount)
        {
            trackNum = baseTrackCount;
            trackName = TrackNames[trackNum];
            mixer.StopAll();
            mixer.FadeInRandom(trackNum , 5.0f); 

            Cha2Button.toggled = true;
        }
        else if (TrackNames.size() > 0)
        {
            trackNum = 0;
            trackName = TrackNames[trackNum];
            mixer.StopAll();
            mixer.FadeInRandom(trackNum , 5.0f); 

            Cha1Button.toggled = true;
        }
    }

    bool MouseOverMe(Vec2f mousePos)
    {
        if (mousePos.x > (Position.x+Size.x) || mousePos.y < Position.y)
        {
            return false;
        }
        return true;
    }

    void Tick()
    { 
        CRules@ rules = getRules();
        CPlayer@ player = getLocalPlayer(); if (player is null) return;
        CMixer@ mixer = getMixer(); if (mixer is null) return;
        CControls@ controls = player.getControls(); if (controls is null) return;  
        CCamera@ cam = getCamera(); if (cam is null) return;
        //if (!s_gamemusic || s_musicvolume == 0.0f) {if (isShowing) isShowing = false; return;}

        if (!StopButton.toggled && mixer.getPlayingCount() == 0 && s_musicvolume > 0.1f)
        {
            if (Cha3Button.toggled && userTrackCount > 1)
            {
                if (ShufButton.toggled)
                {
                    trackNum = baseTrackCount+modTrackCount+rnd.NextRanged(userTrackCount);
                }
                else if (trackNum == baseTrackCount+modTrackCount+userTrackCount-1)
                trackNum = baseTrackCount+modTrackCount;
                else
                trackNum++;
            }
            else if (Cha2Button.toggled && modTrackCount > 1)
            {
                if (ShufButton.toggled)
                {
                    trackNum = baseTrackCount+rnd.NextRanged(modTrackCount);
                }
                else if (trackNum == baseTrackCount+modTrackCount-1)
                trackNum = baseTrackCount;
                else
                trackNum++;
            } 
            else if (Cha1Button.toggled && baseTrackCount > 1)
            {
                if (ShufButton.toggled)
                {
                    trackNum = rnd.NextRanged(baseTrackCount);
                }
                else if (trackNum == baseTrackCount-1)
                trackNum = 0;
                else
                trackNum++;
            }  

            trackName = TrackNames[trackNum];
            mixer.StopAll();
            mixer.FadeInRandom(trackNum , 0.5f);
     
            offset = 0;
            substr_letters = 0;
            timer = 50;
        }

        Vec2f mousePos = controls.getMouseScreenPos();
        mouse_over_menu = MouseOverMe(mousePos);

        if (!mouse_over_menu)
        { 
            buttonHoverNum = 0; 
            //if (cameraLocked ) 
            //{                
            //    cam.setLocked(false);
            //    cameraLocked = false;
            //}
            return;
        }       

        Vec2f mouseWorldPos = controls.getMouseWorldPos(); 

        //if (!cameraLocked)
        //{
        //    cam.setLocked(true); //locks controls/keypress :C
        //    cameraLocked = true;
        //}

        const bool keyAction1 = (controls.isKeyJustReleased(controls.getActionKeyKey(AK_ACTION1))); 

        if (OpenButton.MouseOverMe(Position, mousePos)) 
        { 
            buttonHoverNum = 1; 
            if (keyAction1)
            {
                Sound::Play("select.ogg", mouseWorldPos, 0.6f, 0.6f);
                isShowing = !isShowing;
                Position.y = isShowing ? (HUD_Y-128) : (HUD_Y-24);
            }
        }
        else if (NextButton.MouseOverMe(Position, mousePos)) 
        { 
            buttonHoverNum = 2;

            if (keyAction1 && !StopButton.toggled)
            {
                Sound::Play("select.ogg", mouseWorldPos, 0.6f, 0.6f);
                bool action = false;

                if (Cha3Button.toggled && userTrackCount > 1)
                {
                    if (ShufButton.toggled)
                    {
                        trackNum = baseTrackCount+modTrackCount+rnd.NextRanged(userTrackCount);
                        trackName = TrackNames[trackNum];
                    }
                    else if (trackNum == baseTrackCount+modTrackCount+userTrackCount-1)
                    trackNum = baseTrackCount+modTrackCount;
                    else
                    trackNum++;
                    action = true;
                }
                else if (Cha2Button.toggled && modTrackCount > 1)
                {
                    if (ShufButton.toggled)
                    {
                        trackNum = baseTrackCount+rnd.NextRanged(modTrackCount);
                        trackName = TrackNames[trackNum];
                    }
                    else if (trackNum == baseTrackCount+modTrackCount-1)
                    trackNum = baseTrackCount;
                    else
                    trackNum++;

                    action = true;
                } 
                else if (Cha1Button.toggled && baseTrackCount > 1)
                {
                    if (ShufButton.toggled)
                    {
                        trackNum = rnd.NextRanged(baseTrackCount);
                        trackName = TrackNames[trackNum];
                    }
                    else if (trackNum == baseTrackCount-1)
                    trackNum = 0;
                    else
                    trackNum++;
                    action = true;
                }  

                if (action)
                {
                    trackName = TrackNames[trackNum];
                    mixer.StopAll();
                    mixer.FadeInRandom(trackNum , 0.5f);
             
                    offset = 0;
                    substr_letters = 0;
                    timer = 50;
                }
            }
         }
        else if (StopButton.MouseOverMe(Position, mousePos)) 
        { 
            buttonHoverNum = 3; 
            if (keyAction1)
            {   
                Sound::Play("select.ogg", mouseWorldPos, 0.6f, 0.6f);
                
                if (StopButton.toggled)
                {
                    mixer.FadeInRandom(trackNum , 0.5f);
                    StopButton.toggled = false;
                }
                else
                {
                    //mixer.FadeOutAll(0.0f, 1.0f);
                    mixer.StopAll();
                    StopButton.toggled = true;
                }
            }
        }
        else if (BackButton.MouseOverMe(Position, mousePos))
        { 
            buttonHoverNum = 4; 
            if (keyAction1 && !StopButton.toggled)
            {
                Sound::Play("select.ogg", mouseWorldPos, 0.6f, 0.6f);
                bool action = false;

                if (Cha3Button.toggled && userTrackCount > 1)
                {
                    if (ShufButton.toggled)
                    {
                        trackNum = baseTrackCount+modTrackCount+rnd.NextRanged(userTrackCount);
                        trackName = TrackNames[trackNum];
                    }
                    else if (trackNum == baseTrackCount+modTrackCount)
                    trackNum = baseTrackCount+modTrackCount+userTrackCount-1;
                    else
                    trackNum--;
                    action = true;
                }
                else if (Cha2Button.toggled && modTrackCount > 1)
                {
                    if (ShufButton.toggled)
                    {
                        trackNum = baseTrackCount+rnd.NextRanged(modTrackCount);
                        trackName = TrackNames[trackNum];
                    }
                    else if (trackNum == baseTrackCount)
                    trackNum = baseTrackCount+modTrackCount-1;
                    else
                    trackNum--;
                    action = true;
                }
                else if (Cha1Button.toggled && baseTrackCount > 1)
                {
                    if (ShufButton.toggled)
                    {
                        trackNum = rnd.NextRanged(baseTrackCount);
                        trackName = TrackNames[trackNum];
                    }
                    else if (trackNum == 0)
                    trackNum = baseTrackCount-1;
                    else
                    trackNum--;

                    action = true;
                }

                if (action)
                {
                    trackName = TrackNames[trackNum];
                    mixer.StopAll();
                    mixer.FadeInRandom(trackNum , 0.5f);
             
                    offset = 0;
                    substr_letters = 0;
                    timer = 50;
                }
            }
        }
        else if (VolUButton.MouseOverMe(Position, mousePos)) 
        { 
            buttonHoverNum = 5; 
            if (keyAction1 && !StopButton.toggled)
            {   
                Sound::Play("select.ogg", mouseWorldPos, 0.6f, 0.6f);
                if (!s_gamemusic)
                {                    
                    s_gamemusic = true;
                }
                else if (s_musicvolume < 1.0f)
                {                    
                    s_musicvolume += 0.05f;
                }
            }
        }
        else if (VolDButton.MouseOverMe(Position, mousePos)) 
        { 
            buttonHoverNum = 6; 
            if (keyAction1 && !StopButton.toggled)
            { 
                Sound::Play("select.ogg", mouseWorldPos, 0.6f, 0.6f);                
                
                if (s_musicvolume > 0.1f)
                {
                    s_musicvolume -= 0.05f;
                }
            }
        }
        else if (ShufButton.MouseOverMe(Position, mousePos)) 
        { 
            buttonHoverNum = 7; 
            if (keyAction1)
            {   
                Sound::Play("select.ogg", mouseWorldPos, 0.6f, 0.6f);
                ShufButton.toggled = !ShufButton.toggled;
            }
        }
        else if (Cha1Button.MouseOverMe(Position, mousePos)) 
        { 
            buttonHoverNum = 8; 
            if (keyAction1)
            {   
                Sound::Play("select.ogg", mouseWorldPos, 0.6f, 0.6f);
                Cha1Button.toggled = true; 
                Cha2Button.toggled = false;
                Cha3Button.toggled = false;

                if (baseTrackCount == 0)
                {
                    trackNum = 0;
                    trackName = "No Tracks Found";
                    mixer.StopAll();
                }
                else if (ShufButton.toggled)
                {
                    trackNum = rnd.NextRanged(baseTrackCount);
                    trackName = TrackNames[trackNum];
                    mixer.StopAll();
                    if (!StopButton.toggled)
                    mixer.FadeInRandom(trackNum, 0.5f);
                }
                else
                {
                    trackNum = 0;
                    trackName = TrackNames[trackNum];
                    mixer.StopAll();
                    if (!StopButton.toggled)
                    mixer.FadeInRandom(trackNum, 0.5f);
                }
            }
        }
        else if (Cha2Button.MouseOverMe(Position, mousePos)) 
        { 
            buttonHoverNum = 9; 
            if (keyAction1)
            {   
                Sound::Play("select.ogg", mouseWorldPos, 0.6f, 0.6f);
                Cha1Button.toggled = false;
                Cha2Button.toggled = true;
                Cha3Button.toggled = false;            

                if (modTrackCount == 0)
                {
                    trackNum = baseTrackCount;
                    trackName = "No Tracks Found";
                    mixer.StopAll();
                }
                else if (ShufButton.toggled)
                {
                    trackNum = baseTrackCount+rnd.NextRanged(modTrackCount);
                    trackName = TrackNames[trackNum];
                    mixer.StopAll();
                    if (!StopButton.toggled)
                    mixer.FadeInRandom(trackNum, 0.5f);
                }
                else
                {
                    trackNum = baseTrackCount;
                    trackName = TrackNames[trackNum];
                    mixer.StopAll();
                    if (!StopButton.toggled)
                    mixer.FadeInRandom(trackNum, 0.5f);
                }
            }
        }
        else if (Cha3Button.MouseOverMe(Position, mousePos)) 
        { 
            buttonHoverNum = 10;
            if (keyAction1)
            {   
                Sound::Play("select.ogg", mouseWorldPos, 0.6f, 0.6f);
                Cha1Button.toggled = false;
                Cha2Button.toggled = false;
                Cha3Button.toggled = true;
                

                if (userTrackCount == 0)
                {
                    trackNum = 0;
                    trackName = "No Tracks Found";
                    mixer.StopAll();
                }
                else if (ShufButton.toggled)
                {
                    trackNum = baseTrackCount+modTrackCount+rnd.NextRanged(userTrackCount);
                    trackName = TrackNames[trackNum];
                    mixer.StopAll();

                    if (!StopButton.toggled)
                    mixer.FadeInRandom(trackNum, 0.5f);
                }
                else
                {
                    trackNum = baseTrackCount+modTrackCount;
                    trackName = TrackNames[trackNum];
                    mixer.StopAll();

                    if (!StopButton.toggled)
                    mixer.FadeInRandom(trackNum, 0.5f);
                }
            }
        }
        else { buttonHoverNum = 0; }    
              
    }

    void Render()
    {
        CPlayer@ player = getLocalPlayer();
        if (player is null) return;
     
        GUI::DrawIcon(stereo, 0,  Vec2f(96, 64), Position, 1.0f); // background  
        RenderTrackName();
        
        if (Cha3Button.toggled)
        {
            GUI::DrawIcon(stereo, 12, longbuttonframesize, Position+Cha3Button.Offset, 1.0f, halflitcolor);
        }
        else if (Cha2Button.toggled)
        {
            GUI::DrawIcon(stereo, 12, longbuttonframesize, Position+Cha2Button.Offset, 1.0f, halflitcolor);
        }
        else if (Cha1Button.toggled)
        {
            GUI::DrawIcon(stereo, 12, longbuttonframesize, Position+Cha1Button.Offset, 1.0f, halflitcolor);
        }

        if (StopButton.toggled)
        {
            GUI::DrawIcon(stereo, 12, longbuttonframesize, Position+StopButton.Offset, 1.0f, halflitcolor);
        }

        if (ShufButton.toggled)
        {
            GUI::DrawIcon(stereo, 26, buttonframesize, Position+ShufButton.Offset, 1.0f, halflitcolor);
        }
        
        if ( mouse_over_menu && isShowing)
        {
            switch (buttonHoverNum)
            {
                case 1: {GUI::DrawIcon(stereo, 27, buttonframesize,     Position+OpenButton.Offset, 1.0f, litcolor); break;}
                case 2: {GUI::DrawIcon(stereo, 12, longbuttonframesize, Position+NextButton.Offset, 1.0f, litcolor); break;}
                case 3: {GUI::DrawIcon(stereo, 12, longbuttonframesize, Position+StopButton.Offset, 1.0f, litcolor); break;}
                case 4: {GUI::DrawIcon(stereo, 12, longbuttonframesize, Position+BackButton.Offset, 1.0f, litcolor); break;}

                case 5: {GUI::DrawIcon(stereo, 26, buttonframesize, Position+VolUButton.Offset, 1.0f, litcolor); break;}
                case 6: {GUI::DrawIcon(stereo, 26, buttonframesize, Position+VolDButton.Offset, 1.0f, litcolor); break;}
                case 7: {GUI::DrawIcon(stereo, 26, buttonframesize, Position+ShufButton.Offset, 1.0f, litcolor); break;}

                case 8: {GUI::DrawIcon(stereo, 12, longbuttonframesize, Position+Cha1Button.Offset, 1.0f, litcolor); break;}
                case 9: {GUI::DrawIcon(stereo, 12, longbuttonframesize, Position+Cha2Button.Offset, 1.0f, litcolor); break;}
                case 10: {GUI::DrawIcon(stereo, 12, longbuttonframesize, Position+Cha3Button.Offset, 1.0f, litcolor); break;}
            }            

        }
        else if (buttonHoverNum == 1)
        GUI::DrawIcon(stereo, 27, buttonframesize, Position+OpenButton.Offset, 1.0f, 1.0f, litcolor); // up down button
    }

    void RenderTrackName()
    {
        GUI::SetFont("hud");
     
        float time = (getGameTime()*2.0f);
        string track = trackName;
 
        //GUI::DrawText(track, Position+Vec2f(25, 18)*2, color_white);
        //GUI::DrawText(track, Position+Vec2f(25, 18)*2, Position+Vec2f(103, 27)*2, color_white, false, false);
 
        Vec2f dim;
        GUI::GetTextDimensions(track, dim);
        if(dim.x > 150)
        {
            string final_string = track.substr(substr_letters, track.size()-substr_letters);
            GUI::GetTextDimensions(final_string, dim);
            if(dim.x + offset > 128 && timer == 0)
            {
                offset -= getRenderApproximateCorrectionFactor()/3.0f;
                while(dim.x + offset > 128)
                {
                    final_string = final_string.substr(0, final_string.size()-1);
                    GUI::GetTextDimensions(final_string, dim);
                }
                song_name = final_string;
            }
            else
            {
                timer += getRenderApproximateCorrectionFactor()/3.0f;
                if(timer < 35)
                {
                    song_name = final_string;
                }
                else if (timer < 70)
                {
                    final_string = track;
                    GUI::GetTextDimensions(final_string, dim);
                    while(dim.x > 128)
                    {
                        final_string = final_string.substr(0, final_string.size()-1);
                        GUI::GetTextDimensions(final_string, dim);
                    }
                    song_name = final_string;
                }
                else
                {
                    substr_letters = 0;
                    timer = 0;
                }
            }
        }
        else
        {
            offset = 0;
            substr_letters = 0;
            song_name = track;
        }
 
        GUI::DrawText(song_name, Position+Vec2f(6+offset, 20)*2, color_white);
 
        if(offset < 0)
        {
            string char_to_remove = song_name.substr(0, 1);
            Vec2f dim2;
            GUI::GetTextDimensions(char_to_remove, dim2);
            offset += dim2.x/2.0f;
            substr_letters++;
        }
    } 
}
