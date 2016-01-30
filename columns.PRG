program columns;

const

maxgames=4;


global

// define our game struct
// this allows a columns game to be started anywhere on scren
// any any number of grids

struct gameinfo[maxgames]

    // main grid info
    struct grid[6]
         col[16];
         newmatch[16];
         matched[16];
         gmatched[16];
    end

    struct gridcache[6]
        col[16];
    end

    // struct that stores the grid used for the hints
    // and for the cpu player

    struct hints[3]   // each "swap" variant
        struct cols[6] // each possible position
            struct grid[6]  // regular grid copy
                col[16];
            end
            score;
        end
    end

    // player data

    score=0;
    level=0;
    jewelcount=0;

    chain=0;

    // general game data

    // next / in play jewels
    next[3];
    play[3];

    jewels; // random jewels (4 - 6 usually)

    gameover=0;

    // AI data
    ts; // starget swap
    tc; // target column


    matched=0;
    checkmatch=0;
    smash=0;
    newmatch=0;
    xpos;
    ypos;

    incscore=0;
    newscore=0;

    nextx;
    played=1;
    playing=0;
    colpos[6];

    // auto play data

    autoswap=0;
    autoright=0;
    autoleft=0;
    autodown=0;
    autoplay=0;
    auto=0;

    updateboards=0;
    speed=0;
    playerid=0;

    region;
    ctype;
    cnumber;

END

levels[20]=35,70,105,140,150,180,210,240,270,300,330,360,390,420,450,480,510,100000000;


struct keys[maxgames]
    left;
    right;
    up;
    down;
    swap;
    start;
    auto;
end=_left,_right,_up,_down,_space,_1,_3,
    _a,_d,_w,_s,_w,_2,_4,
    _left,_right,_up,_down,_space,_1,_3,
                                    ;
// set attract mode

attract=1;
players=2;
timeout=0;

sounds[8];

numbersfpg=0;

begin

    // setup our video mode
    set_mode(320240);
    set_fps(30,2);
    //force_pal("PAL/visibone.PAL");

    // load our graphics
    load_fpg("columns/columns.FPG");
    numbersfpg=load_fpg("columns/numbers.fpg");

    load_fnt("columns/columns.fnt");
    // load sounds
    load_sounds();

    // show boot screen
    boot();

    for(x=0;x<20;x++)
        levels[x]=(x+1)*35;
    end
    levels[19]=max_int;


    // next piece position for dual screen
    gameinfo[0].nextx=120;
    gameinfo[1].nextx=184;

    // single player
    gameinfo[2].nextx=88;

//main operating loop
loop
    size=100;

    timer[0]=0;
    // columns title
    graph=206;
    x=160;
    y=50;

    // men intro with bag

    put_screen(0,205-(players==1));

    // bag of gems process
    if(players==2)
        titlegems();
    end
    // show this screen for 10 seconds
    press_start();

    while(!key(_space)  && timer[0]<1000)
        frame;
    end
    if(key(_space))
        sound(sounds[2],256,256);
    end

    signal(type press_start, s_kill);


    // reset timer
    timer[0]=0;

    // kill the gems spawning from the bag
    signal(type titlegems, s_kill_tree);

    frame;

    // hide "columns" title
    graph=0;

    fadeoffon();

    // show the arcade (two player) games grid
    switch(players)
        case 1:
            // show the single player grid
            put_screen(0,217);
            // spawn the single player process
            game(112,8,2);
            joystick(2);
        end

        case 2:
            put_screen(0,203);
            gameinfo[0].gameover=0;
            gameinfo[1].gameover=0;
            game(16,8,0);
            game(208,8,1);

            /*
            gameinfo[3].nextx=326;
            game(336,8,3);

            for(x=4;x<9;x++)
                gameinfo[x].nextx=(x-4)*127;
                game(16+((x-4)*127),248,x);
            end
            */

        end

    end

    frame;
    timeout=timer[0]+1000;
    // show this grid for 10 seconds, or until escape press
    // or continuously if not in attract mode
    repeat
    // only check every second
        frame(2400);

        if(gameinfo[0].playing==1||
           gameinfo[1].playing==1||
           gameinfo[2].playing==1)

            timeout=timer[0]+1000;
        end
            until (timer[0]>timeout);
    stop_scroll(1);
    stop_scroll(2);
    stop_scroll(3);

    fadeoffon();

    // reset time
    timer[0]=0;

    //kill the game(s) and all subprocesses
    signal(type game, s_kill_tree);
    signal(type joystick, s_kill_tree);

    delete_text(all_text);

    frame;

    players=1-players+2;


end  // end main loop

end



process press_start()

private flip=0;

begin
graph=414;

x=160;
y=180;
loop

    flip++;
    flip=flip%10;

    if(flip<5)
        graph=0;
    else
        graph=414;
    end

    frame(300);

end

end

process demo(num)

private flip=0;

begin
graph=415;

ctype=c_scroll;
region=num+1;
cnumber=father.cnumber;
x=48;
y=180;
loop

    flip++;
    flip=flip%10;

    if(flip<5)
        graph=0;
    else
        graph=415;
    end

    frame(300);

end


end



process game(xpos,ypos,num)

// start game engine in a scroll region starting x,y
private
falls=0;
gaps=0;
gx=0;
gy=0;
//myplayer;
flip=0;
s=0;

begin
    //write_int(0,num*160,32,0,&cnumber);

    // background grid
    //graph=301;
    gameinfo[num].gameover=0;
    x=3*16+1;//xpos+3*16+1;
    y=7*16+8;
    //flip=num*16;
    // set number of random jewels in this game
    gameinfo[num].jewels=6;//4;//;//6;//+rand(0,2);
    // set the game zpos ypos
    gameinfo[num].xpos=0;//xpos;
    gameinfo[num].ypos=0;//ypos;

    // setup a region for this grid (makes the sprite hiding easy)
    // xpos now only used to setup the scroll / region
    define_region(num+1,xpos,ypos,96,208);
    start_scroll(num+1,file,0,301,num+1,15);

    // put the folowing in an array!

    if(num==0)
        write_int(1,120,114,3,&gameinfo[num].score);
        write_int(1,120,154,3,&gameinfo[num].level);
        write_int(1,120,186,3,&gameinfo[num].jewelcount);
        define_region(num+1+maxgames,110,64,60,46);  // score region
    end

    if(num==1)
        write_int(1,198,138,5,&gameinfo[num].score);
        write_int(1,198,178,5,&gameinfo[num].level);
        write_int(1,198,210,5,&gameinfo[num].jewelcount);
        define_region(num+1+maxgames,160,88,60,46);  // score region

    end

    //jewelcount);
    //write_int(1,xpos,ypos+16,3,&gameinfo[num].score);
    //write_int(1,xpos,ypos+32,3,&gameinfo[num].level);
    //end

    region=num+1;
    cnumber=2<<num;
    ctype=c_scroll;

    gameinfo[num].region=region;
    gameinfo[num].cnumber=cnumber;
    gameinfo[num].ctype=ctype;
    gameinfo[num].speed=200;

    gameinfo[num].next[0]=0;
    gameinfo[num].next[1]=0;
    gameinfo[num].next[2]=0;

    // reset the grid to zero
    // and spawn jewels
    for(gx=0;gx<6;gx++)
        for(gy=15;gy>=0;gy--)
            gameinfo[num].grid[gx].col[gy]=0;
            //if(gy>10)
            //    gameinfo[num].grid[gx].col[gy]=1;
            //else
            jewel(gx,gy,num);
            //end

        end
    end


    loop
       // gameinfo[num].autoplay=1;
      //  gameinfo[num].jewels=6;//rand(5,6);
      //  myplayer=player(num);
        //gameinfo[num].playing=0;
     //   frame;

        while(gameinfo[num].playing==0)

            flip++;
            flip=flip%32;
            if(flip<16)
                graph=0;
            else
                graph=401+(num%2);
            end

            if(key(keys[num].auto) || gameinfo[num].autoplay==1)
                gameinfo[num].autoplay=1;
                //gameinfo[num].jewels=6;//rand(5,6);

            end


            if(key(keys[num].start) || key(keys[num].swap) || key(keys[num].up) || key(keys[num].auto))
                gameinfo[num].autoplay=0;
                gameinfo[num].score=0;
                gameinfo[num].level=0;
                gameinfo[num].jewelcount=0;
                gameinfo[num].jewels=4;
                gameinfo[num].played=0;

                signal(gameinfo[num].playerid,s_kill_tree);
                //frame;
                gameinfo[num].playerid=player(num);
                gameinfo[num].playing=1;
            end

            if(key(keys[num].auto) || gameinfo[num].autoplay==1)
                gameinfo[num].autoplay=1;
                gameinfo[num].jewels=6;//4;//6;//rand(5,6);

            end
            frame;
            graph=0;

        end

        // game started
        gameinfo[num].gameover=0;

        // mini loop until piece have been placed
        repeat
            frame;
        until(gameinfo[num].played==1);


        // once piece has been placed, check for "wins"
        // and check for drops
        gameinfo[num].chain=1;
        repeat  // while wins

            // check for matches
            gameinfo[num].checkmatch=1;

            frame;

            if(gameinfo[num].matched>0)
                gameinfo[num].smash=28;
                frame;

                gameinfo[num].newscore=gameinfo[num].incscore;
                gameinfo[num].incscore=0;
                newpoints(num);
                frame;

                repeat

                    frame;//(200);
                    if(gameinfo[num].smash==8)
                    // && gameinfo[num].autoplay==0);
                        sound(sounds[0],512,256);

                    end

                    if(gameinfo[num].smash<7)
                        frame;
                    end

                    gameinfo[num].smash--;
                until(gameinfo[num].smash==0);
                frame;
            end

            gameinfo[num].checkmatch=0;


            repeat  // while falls
                falls=0;
                gaps=0;
                for(gy=14;gy>=0;gy--)

                    for(gx=0;gx<6;gx++)
                        gameinfo[num].grid[gx].matched[gy]=0;

                        if(gameinfo[num].grid[gx].col[gy]==0)
                            gaps=1;

                            if(gy>0)
                                if(gameinfo[num].grid[gx].col[gy-1]>0)
                                    gameinfo[num].grid[gx].col[gy]=gameinfo[num].grid[gx].col[gy-1];
                                    gameinfo[num].grid[gx].col[gy-1]=0;
                                    falls=1;
                                end
                            end
                        end
                    end
                end
                frame;
            until (falls==0)

            gameinfo[num].checkmatch=1;
            gameinfo[num].matched=0;
            frame;

            gameinfo[num].chain++;

        until(gameinfo[num].matched==0);

        gameinfo[num].checkmatch=0;

        if(gameinfo[num].jewelcount>levels[gameinfo[num].level] && gameinfo[num].level<20)
            gameinfo[num].level++;
            if(gameinfo[num].level<3)
                gameinfo[num].jewels=gameinfo[num].level+4;
            end
            sound(sounds[4],256,256);
        end

        if(attract==1)
            if(gaps==0)
                for(gy=12;gy>=0;gy--)
                    for(gx=0;gx<6;gx++)
                        gameinfo[num].grid[gx].col[gy]=0;
                    end
                end
            end
        end

        frame;
        gameinfo[num].played=0;

    if(gameinfo[num].gameover==1)
        gameoveranim(num);
    end

    end

end

function gameoveranim(num)

private
gy=0;
gx=0;


begin

        gameoversprite(num);

        for(gy=15;gy>=0;gy--)
            for(gx=0;gx<6;gx++)
                gameinfo[num].grid[gx].col[gy]=0;
            end

            //if(gameinfo[num].autoplay==0);
                sound(sounds[1],256,256);
            //end

            wipe(num,gy);

            frame(gameinfo[num].speed);
        end

        gy=0;
        while(gy<3)
            gameinfo[num].next[gy]=0;
            gy++;
        end

        //stop_sound(s);

        gy=100;

        while(gy>0)
            gy--;
            frame;
        end

        signal(gameinfo[num].playerid, s_kill_tree);

        frame;

        gameinfo[num].playing=0;
        //gameinfo[num].gameover=0;


end



process gameoversprite(num)

begin

graph=410;

x=gameinfo[num].xpos+3*16;
y=gameinfo[num].ypos+8+16*20;

region=gameinfo[num].region;
cnumber=gameinfo[num].cnumber;
ctype=gameinfo[num].ctype;
gameinfo[num].autoplay=0;

while(gameinfo[num].gameover==1)
    if(y>92)
        y-=8;
    end
    graph=rand(410,413);
    frame;

end



end


process wipe(num,y)

begin

    for(x=0;x<6;x++)
        wipes(num,x,y);
    end

end


process wipes(num,x,y)
begin
    graph=60;
    region=gameinfo[num].region;
    cnumber=gameinfo[num].cnumber;
    ctype=gameinfo[num].ctype;

    x=gameinfo[num].xpos+8+x*16;
    y=gameinfo[num].ypos+8+(y-2)*16;

    while (graph<67);
        frame(gameinfo[num].speed);
        graph++;
    end

end




function getnext(num)


begin

while(x<3)
    gameinfo[num].next[x]=rand(1,gameinfo[num].jewels);
    x++;
end

return;

end


process smash(xpos,ypos,num)

private
pos=0;
flip=0;
jewelid;
jewelm;
xg=0;
xc=0;
yc=0;
xcc=0;
ycc=0;
//matched=0;
maidx;

matchpos;
matchswap;



begin
graph=0;
region=num+1;
cnumber=2<<num;
ctype=c_scroll;

x=xpos*16+gameinfo[num].xpos+8;
y=ypos*16+gameinfo[num].ypos+8-32;

loop

if(gameinfo[num].autoplay==1)
    //flags=4;
end

if(gameinfo[num].smash>0 && gameinfo[num].grid[xpos].col[ypos]<0)
    gameinfo[num].grid[xpos].matched[ypos]=0;

    graph=1+10*(abs(gameinfo[num].grid[xpos].col[ypos])-1);
    gameinfo[num].grid[xpos].col[ypos]=0;

    gameinfo[num].incscore+=(10*(gameinfo[num].level+1))*gameinfo[num].chain;
    frame;

    while(gameinfo[num].smash>8)
        size=0;
        if(gameinfo[num].smash%4<2)
           size=100;
        end
        frame;
    end

    gameinfo[num].grid[xpos].col[ypos]=0;

    repeat

        graph=67-gameinfo[num].smash;
        frame;

    until(gameinfo[num].smash==0);

    gameinfo[num].grid[xpos].matched[ypos]=0;

    gameinfo[num].jewelcount++;




end

    if(gameinfo[num].level<2 && gameinfo[num].played==0 && gameinfo[num].grid[xpos].col[ypos]>0 &&
        gameinfo[num].grid[xpos].matched[ypos]>0)

        if(timer[0]%20<10);
            graph=10;   // highlight box round gem
        end
    end


frame;

graph=0;

end

end



process jewel(xpos,ypos,num)

private

jewelid=0;
px=0;
py=0;

shimmer=0;
above=0;
//smashing=0;
counter=0;

begin

region = num+1;
ctype=c_scroll;
cnumber=2<<num;

x=xpos*16+gameinfo[num].xpos+8;
y=ypos*16+gameinfo[num].ypos+8-32;

//if(num==0)
//write_int(0,x,y,4,&gameinfo[num].grid[xpos].col[ypos]);
//write_int(0,x+16+num*120,y,4,&gameinfo[num].hints[0].cols[0].grid[xpos].col[ypos]);
//end
//write_int(0,x+16+num*128,y,4,&gameinfo[num].grid[xpos].matched[ypos]);
smash(xpos,ypos,num);

//loop
//frame;
//end


//if(xpos==0)
//write_int(0,x+num*120,y,4,&ypos);
//end
//debug;


loop
//    if(true) //gameinfo[num].played==1)
// check if jewel has changed
    if(gameinfo[num].autoplay==1)
  //  debug;
        //flags=4;
    end

    if(abs(gameinfo[num].grid[xpos].col[ypos])!=jewelid)
        counter=5;
        jewelid = abs(gameinfo[num].grid[xpos].col[ypos]);
        graph=0;
        if(jewelid>0)
            graph = 1+(jewelid-1)*10;
        end

    end
    if(counter>0)
        counter--;
    end

    if(jewelid>0 && counter==0)
        if(shimmer==0)
            if(above==0)
                if(ypos>0)
                    if(gameinfo[num].grid[xpos].col[ypos-1]!=0)
                    //if(rand(0,1000)>990)
                        shimmer=7;
                    end
                end
            end
        end

        if(shimmer>0)
            graph=1+(jewelid-1)*10+(9-shimmer);
            shimmer--;
            if(shimmer==0)
                graph=1+(jewelid-1)*10;
            end

        end

    end

    if(ypos>0)
        above=abs(gameinfo[num].grid[xpos].col[ypos-1]);
    end


    if(gameinfo[num].checkmatch==1 && jewelid>0)

        if(ypos>0)
            if(abs(gameinfo[num].grid[xpos].col[ypos-1])==jewelid &&
               abs(gameinfo[num].grid[xpos].col[ypos+1])==jewelid)

                gameinfo[num].grid[xpos].col[ypos-1]=-jewelid;
                gameinfo[num].grid[xpos].col[ypos]=-jewelid;
                gameinfo[num].grid[xpos].col[ypos+1]=-jewelid;
                gameinfo[num].matched=1;
            end
        end

        if(xpos>0 && xpos<5 )
            if(abs(gameinfo[num].grid[xpos-1].col[ypos])==jewelid &&
               abs(gameinfo[num].grid[xpos+1].col[ypos])==jewelid)

                gameinfo[num].grid[xpos-1].col[ypos]=-jewelid;
                gameinfo[num].grid[xpos+1].col[ypos]=-jewelid;
                gameinfo[num].grid[xpos].col[ypos]=-jewelid;

                gameinfo[num].matched=1;
            end

            if(ypos>0)
                if(abs(gameinfo[num].grid[xpos-1].col[ypos-1])==jewelid &&
                   abs(gameinfo[num].grid[xpos+1].col[ypos+1])==jewelid)

                    gameinfo[num].grid[xpos-1].col[ypos-1]=-jewelid;
                    gameinfo[num].grid[xpos+1].col[ypos+1]=-jewelid;
                    gameinfo[num].grid[xpos].col[ypos]=-jewelid;

                    gameinfo[num].matched=1;
                end


                if(abs(gameinfo[num].grid[xpos-1].col[ypos+1])==jewelid &&
                   abs(gameinfo[num].grid[xpos+1].col[ypos-1])==jewelid)

                    gameinfo[num].grid[xpos-1].col[ypos+1]=-jewelid;
                    gameinfo[num].grid[xpos+1].col[ypos-1]=-jewelid;
                    gameinfo[num].grid[xpos].col[ypos]=-jewelid;
                    gameinfo[num].matched=1;

                end
            end

       end

    end
    frame;

end

end




process shownext(num)

begin

for(x=0;x<3;x++)
next(num,x);
end
    loop
        frame;
    end

end

process next(num,idx)

private

jewelid=-1;
target=0;

begin

x=gameinfo[num].nextx+8;
y=16+idx*16+240*(num>3);

graph=0;

loop
    if(father.father.y<24 && gameinfo[num].played==0 && gameinfo[num].play[idx]>0)
        target=gameinfo[num].play[idx];
    else
        target=gameinfo[num].next[idx];
    end

    if(target!=jewelid)
        jewelid=target;
        //gameinfo[num].next[idx];
        graph=1+(target-1)*10;
        //jewelid-1)*10;
    end

    frame;

end


end




process player(num)

private
dropinter=100;
dropnext=0;
xpos=2;
ypos=1;
d=0;
gameover=0;
tp=0;
donenext=0;
cpos=0;
repeatdelay=5;
repeatcount=0;
oldkey=0;


begin

gameinfo[0].played=0;
region=num+1;
cnumber=2<<num;
ctype=c_scroll;
//show player jewels
x=-100;
pjewel(num,0);
pjewel(num,1);
pjewel(num,2);

getnext(num);

if(gameinfo[num].autoplay==1)
    demo(num);
    if(num!=2)
//        joystick(num);
    end

end

// display the "next" jewels
shownext(num);

//newpoints(num);


//write_int(0,num*160,0,0,&x);
//write_int(0,num*160,16,0,&ypos);
loop
    if(gameinfo[num].autoplay==1)
        //flags=4;
    end

    while(gameinfo[num].gameover==1)
        frame;
    end
    // populate the "next" grid
    for(tp=0;tp<3;tp++)
        gameinfo[num].play[tp]=gameinfo[num].next[tp];
    end
    //    gameinfo[num].roll=0;
    donenext=0;
    getnext(num);
    setupmatch(num);
    gameinfo[num].updateboards=1;
    bestmove(num);
    cpos=0;
    frame;
// copy the next into the current
// we need 3 copies.
// current
// next
// in play
//
// since the next changes as the current comes into view

// out half/tile position
d=1;
// exact grid positions
xpos=2;
ypos=1;

// player box outline
graph=300;
y=-32;
x=40;//gameinfo[num].xpos+8+16*xpos;

// reset the gameinfo to say the piece is "in play"
gameinfo[num].played=0;


frame;


// main loop, repeated until gameover
repeat

    if(oldkey!=0)
        if(!key(oldkey))
            oldkey=0;
        end

        if(repeatcount<repeatdelay+1)
            repeatcount++;
        end

    end

    // auto play
    if(gameinfo[num].autoplay==1)
        //if(key(keys[num].start || key(keys[num].swap)))
        //    gameinfo[num].gameover=1;
        //    break;
       // end

        gameinfo[num].autoswap=0;
        gameinfo[num].autoleft=0;
        gameinfo[num].autoright=0;
        gameinfo[num].autodown=0;
        //frame;

        if(gameinfo[num].auto==1 && gameinfo[num].played==0)
            if(gameinfo[num].ts!=cpos)
                gameinfo[num].autoswap=1;
            end

            if(gameinfo[num].tc>xpos)
                gameinfo[num].autoright=1;
            end

            if(gameinfo[num].tc<xpos)
                gameinfo[num].autoleft=1;
            end

            if(gameinfo[num].played==0 && gameinfo[num].autoswap==0  && gameinfo[num].autoleft==0 && gameinfo[num].autoright==0)

                gameinfo[num].autodown=1;
            end
        end

    end

    if(key(keys[num].swap) || key(keys[num].up) || gameinfo[num].autoswap==1)

        if((oldkey!=keys[num].swap && oldkey!=keys[num].up) || repeatcount>repeatdelay)

        if(key(keys[num].swap))
            if(oldkey!=keys[num].swap)
                repeatcount=0;
                oldkey=keys[num].swap;
            end
        end

        if(key(keys[num].up))
            if(oldkey!=keys[num].up)
                repeatcount=0;
                oldkey=keys[num].up;
            end
        end


        sound(sounds[6],256,256);

        cpos++;
        if(cpos==3)
            cpos=0;
        end
        tp=gameinfo[num].play[2];
        gameinfo[num].play[2]=gameinfo[num].play[1];
        gameinfo[num].play[1]=gameinfo[num].play[0];
        gameinfo[num].play[0]=tp;

    end

    end



    if(gameinfo[num].autoleft==1 || (key(keys[num].left) && xpos>0))
    if(oldkey!=keys[num].left || repeatcount>repeatdelay)

        if(oldkey!=keys[num].left)
            repeatcount=0;
            oldkey=keys[num].left;
        end

        if(gameinfo[num].grid[xpos-1].col[ypos]==0 &&
         gameinfo[num].grid[xpos-1].col[ypos-1*(ypos>0)]==0)
            x-=16;
            xpos--;
        end
    end

    end



    if(gameinfo[num].autoright==1 || (key(keys[num].right) && xpos<5) )
    if(oldkey!=keys[num].right || repeatcount>repeatdelay)

        if(oldkey!=keys[num].right)
            repeatcount=0;
            oldkey=keys[num].right;
        end

        if(gameinfo[num].grid[xpos+1].col[ypos]==0 &&
          gameinfo[num].grid[xpos+1].col[ypos-1*(ypos>0)]==0)
            x+=16;
            xpos++;
        end
    end
    end

    if(key(keys[num].down) || timer[1]>dropnext || gameinfo[num].autodown==1)
        dropnext=timer[1]+dropinter-(gameinfo[num].level*9);

        if(key(keys[num].down) || gameinfo[num].autodown==1)
            gameinfo[num].score++;
        end

        // check if block below is free
        d=1-d;
        y+=8;
        //if(y==32 && donenext==0)
        //    getnext(num);
        //    donenext=1;
       // end

        if(d==0)
            ypos++;
        end

        if(d==1)
        if(ypos==15 || gameinfo[num].grid[xpos].col[ypos]!=0)
            y=y-8;
            //xpos=(x-8-(gameinfo[num].xpos))/16;
            //ypos=(y-(y%16))/16+2;
            ypos--;
            //if(x>0)
            // populate play grid
                if(ypos>1 && xpos>=0)
                    if(ypos>2)
                        gameinfo[num].grid[xpos].col[ypos-2]=gameinfo[num].play[0];
                    end

                    if(ypos>1)
                        gameinfo[num].grid[xpos].col[ypos-1]=gameinfo[num].play[1];
                    end

                    if(ypos>0)
                        gameinfo[num].grid[xpos].col[ypos]=gameinfo[num].play[2];
                    end
                //end
                else
                    gameinfo[num].gameover=1;
                end

            //if(gameinfo[num].autoplay==0);
                sound(sounds[3],256,256);
           // end

            gameinfo[num].played=1;
            frame;
            x=-100;
            y=-100;
            //frame(200);
        end

        end
    end

    //if(gameinfo[num].autoplay==1)
    //    frame(5);
    //else
       frame;
    //end

    //if(!gameinfo[num].autodown && !gameinfo[num].auto)
    //    frame;
    //end


until (gameinfo[num].played==1);

    gameinfo[num].autoswap=0;
    gameinfo[num].autoleft=0;
    gameinfo[num].autoright=0;
    gameinfo[num].autodown=0;

    for(tp=0;tp<3;tp++)
        gameinfo[num].play[tp]=0;
    end

    // hide the player jewels and wait until main loop
    // has done its checks to resume play
    x=-100;
    repeat
        frame;
    until (gameinfo[num].played==0)


end

// never reached?
debug;

end


process pjewel(num,idx)

private
idy;

// show the jewels the player has
begin
    x=-100;
    priority=father.priority-1;

    region=num+1;
    cnumber=2<<num;
    ctype=c_scroll;
    idy=idx*16;

    // repeat whilst not gameover
    loop
        if(gameinfo[num].autoplay==1)
            //flags=4;
        end

        if(gameinfo[num].gameover==0)
            graph=(gameinfo[num].play[idx]-1)*10+1;

            // get coords from player
            x=father.x;
            y=father.y-16+idy;

        else
            graph=0;
        end

        frame;

    end

end





// gems out of the bag on title

process titlegems()

begin

//graph=219;
    for(y=-1;y<2;y++)
        gem1(219,-2,y);
        gem1(220,-1,y);
        gem1(221,0,y);
        gem1(220,1,y);
        gem1(219,2,y);
    end

    loop
        frame;
    end

end


process gem1(graph,xdir,yoff)

private
ydir;
count;
begin

// repeat forever
loop
    count=0;

    x=160;
    y=116;

    if(abs(xdir)==1);
        y+=2;
    end

    if(abs(xdir)==2);
        y+=7;
    end

    ydir=-6;
    size=100;

    while(count<40)//y<200+6*(abs(xdir)))//!out_region(id,0));
        graph++;
        if(graph==222)
            graph=219;
        end

        count++;

        if(ydir<0)
            x=x+xdir;
        end

        y+=ydir;

        if(ydir<5)
            ydir++;
        end

        if(y>120 && size>0)
            size-=8;
        end

        if(count==15)
            y+=4*(abs(yoff));
            x+=4*(yoff);
        end

        frame;

    end

end


end





// on screen joystick and buttons

process joystick(num)

begin

if(num==2)
    x=240;
    y=200;
else
    ctype=c_scroll;
    cnumber=father.cnumber;
    region=father.region;
    x=32;
    y=200;
end
button(num);

loop
    graph=210;
    if(key(keys[0].left) || gameinfo[num].autoleft==1)
        graph=211;
    end

    if(key(keys[num].right) || gameinfo[num].autoright==1)
        graph=212;
    end

    if(key(keys[num].down) || gameinfo[num].autodown==1)
        graph=213;
    end

  /*
    if(gameinfo[num].autoplay==1)
        graph+=100;
    end
  */


    frame;
end

end

process button(num)

begin

if(num==2)
    x=300;
    y=190;
else
    ctype=c_scroll;
    cnumber=father.cnumber;
    region=father.region;
    x=72;
    y=180;
end

loop

    graph=214;

    if(key(keys[num].swap) || gameinfo[num].autoswap==1)

        graph=215;

    end
  /*
    if(gameinfo[num].autoplay==1)
        graph+=100;
    end
    */
    frame;

end

end

process roll()

begin

    loop
        roll_palette(0,255,1);
    frame;

end

end

process newpoints(num)

private
xoff;
yoff;

sy=0;
score=0;
mscore=0;
scg=0;
pos=0;
d=0;
snum;
slen;

chain=0;

begin

region=num+1+maxgames;

if(num==0)
    xoff=116;
    yoff=64;
end

if(num==1)
//160,88
    xoff=172;
    yoff=88;
end
//yoff+=8;

x=16+xoff;
y=yoff-16;
sy=y;

graph=10;
file=numbersfpg;

//ctype=c_scroll;
cnumber=gameinfo[num].cnumber;

//write_int(1,x,y+20,4,&chain);

//loop
    y=sy;
    x=16+xoff+16;

    while(gameinfo[num].newscore==0)
        frame;
    end
    chain=gameinfo[num].chain;
    score = gameinfo[num].newscore;
    mscore=score;
    gameinfo[num].newscore=0;
    //frame;
    snum = itoa(score);

    slen = strlen(snum);

//    debug;

    while(mscore>0)
        scg=mscore%10;
        mscore-=scg;
        mscore/=10;

        if(scg==0)
            scg=10;
        end


        x-=8;
        pos++;

        scorenum(region,num,x,y,scg,pos,sy,chain,slen);

      //  debug;
    end
    frame(3500);

    gameinfo[num].score+=score;
    score=0;

//end


end

process scorenum(region,num,x,y,scg,pos,sy,chain,slen)
private
d=0;

begin
    if(num==0)
        x+=(slen-3)*8;
    end

    file=numbersfpg;

        graph=scg;

        if(scg==0)
            graph=10;
        end

        graph+=10*(chain-1);

        frame(pos*200);

        repeat

            y+=4;

            if(y-sy==24)
                d=0;
                repeat
                    frame;
                    d++;
                until (d==21);
            end
            //graph=scg;
            flags=0;

            if(y-sy>32)
                y+=4;
                flags=4;
            end

            frame;

        until(y-sy>64)
    end


// END OF GAME PROCESES

/////////////////////
/////////////////////

// Helper Functions

function load_sounds()
// load sounds

// 0 - smash
// 1 - game over noise (repeated)
// 2 - select
// 3 - drop
// 4 - level up?
// 5 - magic jewel?
// 6 - swap
// 7 - ????

begin

    for(x=0;x<8;x++)
        sounds[x]=load_wav("columns/fx"+itoa(x)+".wav",0);//(x==1));
    end

end

function boot()

begin

    timer[0]=0;

    // colour bars
    put_screen(0,209);

    while(!key(_space) && timer[0]<500);
        frame;
    end

    clear_screen();

    // show the sega logo
    set_fps(60,2);
    fill3();
    set_fps(30,2);

    graph=216;
    x=161;
    y=121;
    size=100;

    timer[0]=0;

    while(timer[0]<200)
        frame;
    end

// shrink logo to zero
    while(size>0)
        size-=10;
        frame;
    end

end





// Fades the screen off, then on

function fadeoffon()

begin
    fade_off();

    while(fading)
        frame;
    end

    fade_on();

end


// select the best move to use
// for the cpu player


function bestmove(num)

private

bests=0;
bestc=0;
score;
best=0;
bestpos;
possible[6];
begin

    // prevent game moving until we have got a move
    gameinfo[num].auto=0;

    for(x=0;x<3;x++)
        for(y=0;y<6;y++)
            score=gameinfo[num].hints[x].cols[y].score;//+gameinfo[num].colpos[y];
            possible[y]=0;
            if(score>best)
                bests=x;
                bestc=y;
                best=score;
            end

        end
    end

    if(best==0)

        bests=rand(0,2);
        bestc=rand(0,5);
        bestpos=0;

        for(x=0;x<6;x++)
            if(gameinfo[num].colpos[x]>=bestpos)
                bestpos=gameinfo[num].colpos[x];
                bestc=x;//gameinfo[num].colpos[x];
            end
        end


    end


    // store best move data for cpu to target

    gameinfo[num].ts=bests;
    gameinfo[num].tc=bestc;
    gameinfo[num].auto=1;

end



function nextscore(num,swap,pos)

private

struct testgrid[6]
    cols[16];
    matched[16];
end

xpos=0;
ypos=0;

spos=0;
cpos=0;

colpos[6];
piece[3];
tp=0;
oldscore;
newscore;
jewelid;
drops=0;
multi=0;

begin

    for(x=0;x<3;x++)
        piece[x]=gameinfo[num].next[x];
    end


    // get drop position for each piece
    for(x=0;x<6;x++)
        //gameinfo[num].colpos[x]=0;
        colpos[x]=0;
        for(y=14;y>0;y--)

            if(gameinfo[num].gridcache[x].col[y]==0);
                colpos[x]=y;
          //      gameinfo[num].colpos[x]=y;
                break;
            end
        end
    end

    //debug;


    for(spos=0;spos<3;spos++)
        for(cpos=0;cpos<6;cpos++)

            // copy grid
            for(xpos=0;xpos<6;xpos++)
                for(ypos=0;ypos<15;ypos++)
                    testgrid[xpos].cols[ypos]=gameinfo[num].gridcache[xpos].col[ypos];
                end
            end

            // place our piece
            for(x=0;x<3;x++)

                if(colpos[cpos]-x>=0)
                    testgrid[cpos].cols[colpos[cpos]-x]=piece[2-x];
                end
            end

            //debug;

            multi=1;
            repeat

                oldscore=gameinfo[num].hints[swap].cols[pos].score;

                // check matches
                for(xpos=0;xpos<6;xpos++)
                    for(ypos=0;ypos<15;ypos++)

                        // reset match this board
                        testgrid[xpos].matched[ypos]=0;

                        jewelid=testgrid[xpos].cols[ypos];

                if(jewelid>0)

                    if(ypos>0)
                        if(testgrid[xpos].cols[ypos-1]==jewelid &&
                           testgrid[xpos].cols[ypos+1]==jewelid)

                            testgrid[xpos].matched[ypos-1]=jewelid;
                            testgrid[xpos].matched[ypos+1]=jewelid;
                            testgrid[xpos].matched[ypos]=jewelid;

                            //debug;
                            gameinfo[num].hints[swap].cols[pos].score+=multi;
                        end

                    end

                    if(xpos>0 && xpos<5 )

                        if( testgrid[xpos-1].cols[ypos]==jewelid &&
                           testgrid[xpos+1].cols[ypos]==jewelid )

                             testgrid[xpos-1].matched[ypos]=jewelid;
                             testgrid[xpos+1].matched[ypos]=jewelid;
                             testgrid[xpos].matched[ypos]=jewelid;

                             //debug;
                             gameinfo[num].hints[swap].cols[pos].score+=multi;

                        end

                        if(ypos>0)
                            if(
                            testgrid[xpos-1].cols[ypos-1]==jewelid &&
                            testgrid[xpos+1].cols[ypos+1]==jewelid )

                                testgrid[xpos-1].matched[ypos-1]=jewelid;
                                testgrid[xpos+1].matched[ypos+1]=jewelid;
                                testgrid[xpos].matched[ypos]=jewelid;

                                //debug;
                                gameinfo[num].hints[swap].cols[pos].score+=multi;

                            end


                            if( testgrid[xpos-1].cols[ypos+1]==jewelid &&
                                testgrid[xpos+1].cols[ypos-1]==jewelid )

                                testgrid[xpos-1].matched[ypos+1]=jewelid;
                                testgrid[xpos+1].matched[ypos-1]=jewelid;
                                testgrid[xpos].matched[ypos]=jewelid;

                                //debug;
                                gameinfo[num].hints[swap].cols[pos].score+=multi;

                            end
                        end

                    end

                end

                    end
                end

                // make gaps
                for(xpos=0;xpos<6;xpos++)
                        for(ypos=0;ypos<15;ypos++)
                            if(testgrid[xpos].matched[ypos]>0)
                                testgrid[xpos].cols[ypos]=0;
                                testgrid[xpos].matched[ypos]=0;
                            end
                        end
                    end

                // drops
                repeat

                    drops=0;
                    for(xpos=0;xpos<6;xpos++)
                        for(ypos=1;ypos<15;ypos++)
                            if(testgrid[xpos].cols[ypos]==0)
                                if(testgrid[xpos].cols[ypos-1]>0)
                                    testgrid[xpos].cols[ypos]=testgrid[xpos].cols[ypos-1];
                                    testgrid[xpos].cols[ypos-1]=0;
                                    drops=1;
                                end
                            end
                        end
                    end
                    multi++;
                until(drops==0);


                newscore=gameinfo[num].hints[swap].cols[pos].score-oldscore;

            until(newscore==0)

        end

        // rotate pieces for next loop
        tp=piece[2];
        piece[2]=piece[1];
        piece[1]=piece[0];
        piece[0]=tp;

    end


end



function setupmatch(num)

private
col;
tp=0;
xpos=0;
ypos=0;
jewelid=0;
matchpos=0;
matchswap=0;
newscore=0;
oldscore=0;
piece[4];
drops=0;
first=0;
multi=0;

colpos[6]; // to store our drop targets
begin

for(x=0;x<6;x++)
    for(y=0;y<15;y++)
        gameinfo[num].grid[x].matched[y]=0;
    end
end


for(col=0;col<6;col++)   // each possible position
    for(x=0;x<3;x++)
        piece[x]=gameinfo[num].play[x];
    end

    for(graph=0;graph<3;graph++) // each swap
        gameinfo[num].hints[graph].cols[col].score=0;

        matchswap=graph;
        matchpos=col;


        for(x=0;x<6;x++) // copy main grid
            gameinfo[num].colpos[x]=0;

            for(y=0;y<15;y++)
                gameinfo[num].hints[graph].cols[col].grid[x].col[y]=
                gameinfo[num].grid[x].col[y];

                if(gameinfo[num].grid[x].col[y]==0);
                    gameinfo[num].colpos[x]=y;
                    colpos[x]=y;
                end

            end
        end

        // copy piece to grid in position / swapped
        // rotate pieces (doesnt matter about the order, as long as they match
        // button presses.
        // we use 4 slots instead of 3 to use as a temp value.

        for(x=0;x<3;x++)

            if(colpos[col]-x>=0)

                gameinfo[num].hints[graph].cols[col].grid[col].col[colpos[col]-x]=piece[2-x];
            end
        end

        // set score for this grid
        first=0;
        multi=10;
        repeat

        oldscore=gameinfo[num].hints[matchswap].cols[matchpos].score;

        for(xpos=0;xpos<6;xpos++)
            if(colpos[x]>1)
            for(ypos=0;ypos<15;ypos++)

                // reset match this board
                gameinfo[num].grid[xpos].gmatched[ypos]=0;

                jewelid=gameinfo[num].hints[matchswap].cols[matchpos].grid[xpos].col[ypos];

                if(jewelid>0)

                    if(ypos>0)
                        if(gameinfo[num].hints[matchswap].cols[matchpos].grid[xpos].col[ypos-1]==jewelid &&
                           gameinfo[num].hints[matchswap].cols[matchpos].grid[xpos].col[ypos+1]==jewelid)

                            if(first==0)
                                gameinfo[num].grid[xpos].matched[ypos]=jewelid;
                                gameinfo[num].grid[xpos].matched[ypos-1]=jewelid;
                                gameinfo[num].grid[xpos].matched[ypos+1]=jewelid;
                            end

                            if(gameinfo[num].autoplay==1)
                                gameinfo[num].grid[xpos].gmatched[ypos]=jewelid;
                                gameinfo[num].grid[xpos].gmatched[ypos-1]=jewelid;
                                gameinfo[num].grid[xpos].gmatched[ypos+1]=jewelid;

                                gameinfo[num].hints[matchswap].cols[matchpos].score+=multi;
                            end

                        end
                    end

                    if(xpos>0 && xpos<5 )
                        if(gameinfo[num].hints[matchswap].cols[matchpos].grid[xpos-1].col[ypos]==jewelid &&
                           gameinfo[num].hints[matchswap].cols[matchpos].grid[xpos+1].col[ypos]==jewelid)

                            if(first==0)
                                gameinfo[num].grid[xpos].matched[ypos]=jewelid;
                                gameinfo[num].grid[xpos-1].matched[ypos]=jewelid;
                                gameinfo[num].grid[xpos+1].matched[ypos]=jewelid;
                            end

                            if(gameinfo[num].autoplay==1)
                                gameinfo[num].grid[xpos].gmatched[ypos]=jewelid;
                                gameinfo[num].grid[xpos-1].gmatched[ypos]=jewelid;
                                gameinfo[num].grid[xpos+1].gmatched[ypos]=jewelid;

                                gameinfo[num].hints[matchswap].cols[matchpos].score+=multi;
                            end

                        end

                        if(ypos>0)
                            if(gameinfo[num].hints[matchswap].cols[matchpos].grid[xpos-1].col[ypos-1]==jewelid &&
                               gameinfo[num].hints[matchswap].cols[matchpos].grid[xpos+1].col[ypos+1]==jewelid)

                                if(first==0)
                                    gameinfo[num].grid[xpos].matched[ypos]=jewelid;
                                    gameinfo[num].grid[xpos-1].matched[ypos-1]=jewelid;
                                    gameinfo[num].grid[xpos+1].matched[ypos+1]=jewelid;
                                end

                                if(gameinfo[num].autoplay==1)
                                    gameinfo[num].grid[xpos].gmatched[ypos]=jewelid;
                                    gameinfo[num].grid[xpos-1].gmatched[ypos-1]=jewelid;
                                    gameinfo[num].grid[xpos+1].gmatched[ypos+1]=jewelid;

                                    gameinfo[num].hints[matchswap].cols[matchpos].score+=multi;
                                end
                            end


                            if(gameinfo[num].hints[matchswap].cols[matchpos].grid[xpos-1].col[ypos+1]==jewelid &&
                               gameinfo[num].hints[matchswap].cols[matchpos].grid[xpos+1].col[ypos-1]==jewelid)

                                if(first==0)
                                    gameinfo[num].grid[xpos].matched[ypos]=jewelid;
                                    gameinfo[num].grid[xpos-1].matched[ypos+1]=jewelid;
                                    gameinfo[num].grid[xpos+1].matched[ypos-1]=jewelid;
                                end

                                if(gameinfo[num].autoplay==1)
                                    gameinfo[num].grid[xpos].gmatched[ypos]=jewelid;
                                    gameinfo[num].grid[xpos-1].gmatched[ypos+1]=jewelid;
                                    gameinfo[num].grid[xpos+1].gmatched[ypos-1]=jewelid;

                                    gameinfo[num].hints[matchswap].cols[matchpos].score+=multi;
                                end

                            end
                        end

                    end

                end
            end
            end
        end
        first++;
        multi++;

        newscore=gameinfo[num].hints[matchswap].cols[matchpos].score-oldscore;
        // check for drops
        if(newscore>0 && gameinfo[num].autoplay==1 )
        //gameinfo[num].hints[matchswap].cols[matchpos].score>0)
            drops=0;
            //debug;
            // make holes in the board
            for(xpos=0;xpos<6;xpos++)
                for(ypos=14;ypos>0;ypos--)
                    if(gameinfo[num].grid[xpos].gmatched[ypos]>0)
                        gameinfo[num].hints[matchswap].cols[matchpos].grid[xpos].col[ypos]=0;
                        gameinfo[num].grid[xpos].gmatched[ypos]=0;

                    end
                end
            end

            repeat

            drops=0;


            for(xpos=0;xpos<6;xpos++)
                for(ypos=1;ypos<15;ypos++)

                    if(gameinfo[num].hints[matchswap].cols[matchpos].grid[xpos].col[ypos]==0 &&
                       gameinfo[num].hints[matchswap].cols[matchpos].grid[xpos].col[ypos-1]>0)

                        gameinfo[num].hints[matchswap].cols[matchpos].grid[xpos].col[ypos]=
                          gameinfo[num].hints[matchswap].cols[matchpos].grid[xpos].col[ypos-1];

                        gameinfo[num].hints[matchswap].cols[matchpos].grid[xpos].col[ypos-1]=0;

                        drops=1;
                    end
                end
            end

            until (drops==0);


        //    debug;
        end

        until (newscore==0)

        // all drops done

        // run each variant of next, in each position and get some more score for this grid


        for(xpos=0;xpos<6;xpos++);
            for(ypos=0;ypos<15;ypos++)
                gameinfo[num].gridcache[xpos].col[ypos] = gameinfo[num].hints[matchswap].cols[matchpos].grid[xpos].col[ypos];
            end
        end

        //gameinfo[num].hints[matchswap].cols[matchpos].score+=

        nextscore(num,matchswap,matchpos);

        // swap the piece for the next move
        tp=piece[2];
        piece[2]=piece[1];
        piece[1]=piece[0];
        piece[0]=tp;

    end

end

end



function fill3()

private

map;


begin
while(key(_space))
frame;
end

//set_fps(50,0);

//set_mode(320240);
//load_fpg("sega.FPG");
map = 223;
//load_map("segabw.pcx");

graph=map;
//size=300;

x=160;
y=120;

fill2(map,2,2,1,120);

repeat
frame;
until (!get_id(type fill) || key(_space));
signal(type fill, s_kill);

end


process fill2(map,x,y,source,target)
begin

fill(map,x,y,source,target);

end


process fill(map,x,y,source,target)

private
pixel;
xpos;
ypos;
begin
//write_int(0,x*8,y*8,4,&pixel);

pixel=map_get_pixel(file,map,x,y);
if(pixel!=target)
//source)
//debug;
map_put_pixel(file,map,x,y,target);
frame;
//end

FROM xpos=-1 TO 1;
//;xpos<2;xpos++)

    FROM ypos=-1 to 1;
    //for(ypos=-1;ypos<2;ypos++)
        if(!(x+xpos==father.x && y+ypos==father.y) && x+xpos>=0 && y+ypos>=0 && !(xpos==0 && ypos==0))
            pixel=map_get_pixel(file,map,x+xpos,y+ypos);
            if(pixel==source)
            //target)
            //=source)
            //    debug;
                fill(map,x+xpos,y+ypos,source,target);
                //frame(50);
                //xpos=1;
                //ypos=1;
                //break;

            end
        end
       // frame;

    end
    //frame;

end

//frame(50);

end

end







