#include "StereoPlayer.as"

void onInit(CRules@ this)
{  
    StereoPlayer stereo;
    this.set("StereoPlayer", @stereo);
    //onRestart(this);   

    this.set_bool("initialized game", true);
}
 
//void onRestart( CRules@ this )
//{
//    CPlayer@ player = getLocalPlayer();
//    if (player is null) return;
//    CMixer@ mixer = getMixer();
//    if (mixer is null) return;
//
//    if (mixer.getPlayingCount() == 0)
//    {
//        rnd.Reset(player.getNetworkID()+getGameTime());
//        s8 num = rnd.NextRanged(7);
//        this.set_s8("track", num);
//        this.SyncToPlayer("track", player);
//        this.set_string("musictrack" ,UserTrackNames[num]);
//        this.set_u16("tracktimer", getGameTime());
//        mixer.StopAll();
//        mixer.FadeInRandom(num , 25.0f);
//    }
//}

void onTick(CRules@ this)
{  
    StereoPlayer@ stereo;
    if (!this.get("StereoPlayer", @stereo)) { return; }
    stereo.Tick();    
}

void onRender(CRules@ this)
{
    StereoPlayer@ stereo;
    if (!this.get("StereoPlayer", @stereo)) { return; }
    stereo.Render();  
}