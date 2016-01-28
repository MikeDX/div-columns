program columns;

global

// define our game struct
// this allows a columns game to be started anywhere on scren
// any any number of grids

struct gameinfo[3]

    struct grid[6]
         col[16];
         newmatch[16];
         matched[16];
         gmatched[16];
         rollmatch[16];
         struct data[14];
            jewelid;
            destroyed;
         end
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
    checkbest=0;
    ts;
    tc;
    gameover=0;

    matched=0;
    checkmatch=0;
    smash=0;
    newmatch=0;
    xpos;
    ypos;
    score;
    level;
    curr[3];
    next[3];
    play[3];
    nextx;
    jewels;
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



END


struct keys[3]
    left;
    right;
    down;
    swap;
    start;
    auto;
end=_left,_right,_down,_space,_1,_3,
    _a,_d,_s,_w,_2,_4,
    _left,_right,_down,_space,_1,_3;
// set attract mode

attract=1;
players=2;
timeout=0;

sounds[8];


begin

//set_fps(50,2);


// reset the timer
timer[0]=0;

set_mode(320240);


// load sounds

// 0 - smash
// 1 - game over noise (repeated)
// 2 - select
// 3 - drop
// 4 - level up?
// 5 - magic jewel?
// 6 - swap
// 7 - ????

for(x=0;x<8;x++)
    sounds[x]=load_wav("columns/fx"+itoa(x)+".wav",0);//(x==1));
end



load_fpg("columns/columns.FPG");

// colour bars
put_screen(0,209);


while(!key(_space) && timer[0]<500);
    frame;
end

clear_screen();
timer[0]=0;

// show the sega logo
graph=216;
x=160;
y=120;
size=200;

while(timer[0]<200)
//angle+=5000;
    frame;
end

// shrink to zero

while(size>0)
    size-=10;
    frame;
end
//roll();

// setup the "next" position for each game
// arcade
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



    //if(key(_space))
    //   attract=0;
    //end
    fadeonoff();

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

    fadeonoff();

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
y=10;
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


function fadeonoff()
begin
    fade_off();
    while(fading)
        frame;
    end

    fade_on();

end




process game(xpos,ypos,num)

// start game engine in a scroll region starting x,y
private
falls=0;
gaps=0;
gx=0;
gy=0;
speed=200;
myplayer;
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
    gameinfo[num].jewels=4;//;//6;//+rand(0,2);
    // set the game zpos ypos
    gameinfo[num].xpos=0;//xpos;
    gameinfo[num].ypos=0;//ypos;

    // setup a region for this grid (makes the sprite hiding easy)
    // xpos now only used to setup the scroll / region
    define_region(num+1,xpos,ypos,96,208);
    start_scroll(num+1,file,0,301,num+1,15);

    region=num+1;
    cnumber=2<<num;
    ctype=c_scroll;

    gameinfo[num].next[0]=0;
    gameinfo[num].next[1]=0;
    gameinfo[num].next[2]=0;

    // display the "next" jewels
    shownext(num);

    /// reset the grid to zero
    // and spawn jewels
    for(gx=0;gx<6;gx++)
        for(gy=15;gy>=0;gy--)
            gameinfo[num].grid[gx].col[gy]=0;
            jewel(gx,gy,num);
        end
    end


    loop

        while(!gameinfo[num].playing)

            flip++;
            flip=flip%32;
            if(flip<16)
                graph=0;
            else
                graph=401+(num%2);
            end

            if(key(keys[num].auto))
                gameinfo[num].autoplay=1;
                gameinfo[num].jewels=rand(5,6);

            end


            if(key(keys[num].start) || key(keys[num].swap) || gameinfo[num].autoplay==1)
                myplayer=player(num);
                gameinfo[num].playing=1;
            end
            frame;
            graph=0;
        end

        // mini loop until piece have been placed
        repeat
            frame;
        until(gameinfo[num].played==1);


        // once piece has been placed, check for "wins"
        // and check for drops

        repeat  // while wins

            // check for matches
            gameinfo[num].checkmatch=1;

            frame;

            if(gameinfo[num].matched>0)
                gameinfo[num].smash=28;
                repeat

                    frame;//(200);
                    if(gameinfo[num].smash==8)
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
            /*
            for(gx=0;gx<3;gx++)
                for(gy=0;gy<15;gy++)
                    gameinfo[num].grid[gx].matched[gy]=0;
                end
            end
            */

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

        until(gameinfo[num].matched==0);

        gameinfo[num].checkmatch=0;

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

       gameoversprite(num);

        for(gy=15;gy>=0;gy--)
            for(gx=0;gx<6;gx++)
                gameinfo[num].grid[gx].col[gy]=0;
            end
            sound(sounds[1],256,256);

            wipe(num,gy,speed);

            frame(speed);
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

        signal(myplayer, s_kill_tree);

        frame;

        gameinfo[num].playing=0;
        gameinfo[num].gameover=0;
           end

end


end

process gameoversprite(num)
begin

graph=410;

x=gameinfo[num].xpos+3*16;
y=gameinfo[num].ypos+8+16*20;
region=father.region;
cnumber=father.cnumber;
ctype=father.ctype;
gameinfo[num].autoplay=0;

while(y>92)
    y-=8;
    graph++;
    if(graph==414)
        graph=410;
    end
    frame;
end



while(gameinfo[num].gameover==1)

    graph++;
    if(graph==414)
        graph=410;
    end
    frame;

end

end


process wipe(num,y,speed)

begin

    for(x=0;x<6;x++)
        wipes(num,x,y,speed);
    end

end


process wipes(num,x,y,speed)
begin
    graph=60;
    region=num+1;
    cnumber=2<<num;
    ctype=c_scroll;
    x=gameinfo[num].xpos+8+x*16;
    y=gameinfo[num].ypos+8+(y-2)*16;
    while (graph<67);
        frame(speed);
    graph++;
end

end




function getnext(num)


begin

while(x<3)
    gameinfo[num].curr[x]=gameinfo[num].next[x];
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


struct matcharray[4]
    x;
    y;
END=-1,-1, 0,-1, 1,-1, -1,-1;


begin
graph=0;
region=num+1;
cnumber=2<<num;
ctype=c_scroll;

x=xpos*16+gameinfo[num].xpos+8;
y=ypos*16+gameinfo[num].ypos+8-32;

loop
// if smashed
//    flip++;

//    if(flip==10)
//        flip=0;
//    end

//pos=gameinfo[num];


if(gameinfo[num].smash>0 && gameinfo[num].grid[xpos].col[ypos]<0)
    gameinfo[num].grid[xpos].matched[ypos]=0;

    graph=1+10*(abs(gameinfo[num].grid[xpos].col[ypos])-1);
    gameinfo[num].grid[xpos].col[ypos]=0;

    while(gameinfo[num].smash>8)
        size=0;
        if(gameinfo[num].smash%4<2)
           size=100;
        end
        frame;
    end

    gameinfo[num].grid[xpos].col[ypos]=0;

    repeat
    //if(gameinfo[num].grid[xpos].col[ypos]<0)
        graph=67-gameinfo[num].smash;
   // end
        frame;
    until(gameinfo[num].smash==0);

    gameinfo[num].grid[xpos].matched[ypos]=0;

end
/*
    if(gameinfo[num].grid[xpos].newmatch[ypos]==1)
    //gameinfo[num].newmatch==1)
        //matched=0;

     //   if(jewelid>0)
            for(matchpos=0;matchpos<6;matchpos++)
                for(matchswap=0;matchswap<3;matchswap++)

                    // match out pseudo slot
                    jewelid=gameinfo[num].hints[matchswap].cols[matchpos].grid[xpos].col[ypos];
                    if(jewelid>0)

                    if(ypos>0)
                        if(gameinfo[num].hints[matchswap].cols[matchpos].grid[xpos].col[ypos-1]==jewelid &&
                           gameinfo[num].hints[matchswap].cols[matchpos].grid[xpos].col[ypos+1]==jewelid)

                           gameinfo[num].grid[xpos].matched[ypos]=jewelid;
                           gameinfo[num].grid[xpos].matched[ypos-1]=jewelid;
                           gameinfo[num].grid[xpos].matched[ypos+1]=jewelid;

                           gameinfo[num].hints[matchswap].cols[matchpos].score++;


                        end
                    end

                    if(xpos>0 && xpos<5 )
                        if(gameinfo[num].hints[matchswap].cols[matchpos].grid[xpos-1].col[ypos]==jewelid &&
                           gameinfo[num].hints[matchswap].cols[matchpos].grid[xpos+1].col[ypos]==jewelid)

                           gameinfo[num].grid[xpos].matched[ypos]=jewelid;
                           gameinfo[num].grid[xpos-1].matched[ypos]=jewelid;
                           gameinfo[num].grid[xpos+1].matched[ypos]=jewelid;
                            gameinfo[num].hints[matchswap].cols[matchpos].score++;

                        end

                        if(ypos>0)
                            if(gameinfo[num].hints[matchswap].cols[matchpos].grid[xpos-1].col[ypos-1]==jewelid &&
                               gameinfo[num].hints[matchswap].cols[matchpos].grid[xpos+1].col[ypos+1]==jewelid)

                               gameinfo[num].grid[xpos].matched[ypos]=jewelid;
                               gameinfo[num].grid[xpos-1].matched[ypos-1]=jewelid;
                               gameinfo[num].grid[xpos+1].matched[ypos+1]=jewelid;
                               gameinfo[num].hints[matchswap].cols[matchpos].score++;

                            end


                            if(gameinfo[num].hints[matchswap].cols[matchpos].grid[xpos-1].col[ypos+1]==jewelid &&
                               gameinfo[num].hints[matchswap].cols[matchpos].grid[xpos+1].col[ypos-1]==jewelid)

                               gameinfo[num].grid[xpos].matched[ypos]=jewelid;
                               gameinfo[num].grid[xpos-1].matched[ypos+1]=jewelid;
                               gameinfo[num].grid[xpos+1].matched[ypos-1]=jewelid;
                               gameinfo[num].hints[matchswap].cols[matchpos].score++;

                            end
                        end

                    end

                    end

        //    end
        end
*/
//    end
//    gameinfo[num].grid[xpos].newmatch[ypos]=0;
//    flip=0;

//end

//    jewelid =

//    end
    if(gameinfo[num].played==0 && gameinfo[num].grid[xpos].col[ypos]>0 && gameinfo[num].grid[xpos].matched[ypos]>0)
       // flip++;
       // flip=flip%10;
//       debug;

        if(timer[0]%20<10);
            graph=10;
        end
    end

    //else
    //    if(gameinfo[num].grid[xpos].matched[ypos]>0)
    //        graph=1+gameinfo[num].grid[xpos].matched[ypos]*10;
    //    end
    //end


//    if(gameinfo[num].grid[xpo].matched[ypos]==1)


//    else
//        graph=0;
//end

//end

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

loop
//    if(true) //gameinfo[num].played==1)
// check if jewel has changed
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
begin

x=gameinfo[num].nextx+8;
y=16+idx*16;

graph=0;

loop

    if(gameinfo[num].next[idx]!=jewelid)
        jewelid=gameinfo[num].next[idx];
        graph=1+(jewelid-1)*10;
    end

    frame;

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

colpos[6]; // to store our drop targets
begin

for(x=0;x<3;x++)
    piece[x]=gameinfo[num].play[x];
end

gameinfo[num].checkbest=1;
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
            for(y=0;y<15;y++)
                gameinfo[num].hints[graph].cols[col].grid[x].col[y]=
                gameinfo[num].grid[x].col[y];

               // if(col==5)
               //     gameinfo[num].grid[x].newmatch[y]=1;
               //     gameinfo[num].grid[x].matched[y]=0;
               // end

                if(gameinfo[num].grid[x].col[y]==0);
                    gameinfo[num].colpos[x]=y;
                end

            end
        end

        // copy piece to grid in position / swapped
        // rotate pieces (doesnt matter about the order, as long as they match
        // button presses.
        // we use 4 slots instead of 3 to use as a temp value.


                /*
        tp=piece[0];
        piece[0]=piece[2];
        piece[2]=piece[1];
        piece[1]=tp;
        */
        for(x=0;x<3;x++)
            //debug;
            if(colpos[col]-x>=0)
               // debug;
                gameinfo[num].hints[graph].cols[col].grid[col].col[gameinfo[num].colpos[col]-x]=piece[2-x];
            end
        end

                // set score for this grid
        first=0;
        repeat

        oldscore=gameinfo[num].hints[matchswap].cols[matchpos].score;

        for(xpos=0;xpos<6;xpos++)
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

                            gameinfo[num].grid[xpos].gmatched[ypos]=jewelid;
                            gameinfo[num].grid[xpos].gmatched[ypos-1]=jewelid;
                            gameinfo[num].grid[xpos].gmatched[ypos+1]=jewelid;

                            gameinfo[num].hints[matchswap].cols[matchpos].score++;


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

                            gameinfo[num].grid[xpos].gmatched[ypos]=jewelid;
                            gameinfo[num].grid[xpos-1].gmatched[ypos]=jewelid;
                            gameinfo[num].grid[xpos+1].gmatched[ypos]=jewelid;


                            gameinfo[num].hints[matchswap].cols[matchpos].score++;

                        end

                        if(ypos>0)
                            if(gameinfo[num].hints[matchswap].cols[matchpos].grid[xpos-1].col[ypos-1]==jewelid &&
                               gameinfo[num].hints[matchswap].cols[matchpos].grid[xpos+1].col[ypos+1]==jewelid)

                                if(first==0)
                                    gameinfo[num].grid[xpos].matched[ypos]=jewelid;
                                    gameinfo[num].grid[xpos-1].matched[ypos-1]=jewelid;
                                    gameinfo[num].grid[xpos+1].matched[ypos+1]=jewelid;
                                end

                                gameinfo[num].grid[xpos].gmatched[ypos]=jewelid;
                                gameinfo[num].grid[xpos-1].gmatched[ypos-1]=jewelid;
                                gameinfo[num].grid[xpos+1].gmatched[ypos+1]=jewelid;


                                gameinfo[num].hints[matchswap].cols[matchpos].score++;

                            end


                            if(gameinfo[num].hints[matchswap].cols[matchpos].grid[xpos-1].col[ypos+1]==jewelid &&
                               gameinfo[num].hints[matchswap].cols[matchpos].grid[xpos+1].col[ypos-1]==jewelid)

                                if(first==0)
                                    gameinfo[num].grid[xpos].matched[ypos]=jewelid;
                                    gameinfo[num].grid[xpos-1].matched[ypos+1]=jewelid;
                                    gameinfo[num].grid[xpos+1].matched[ypos-1]=jewelid;
                                end

                                gameinfo[num].grid[xpos].gmatched[ypos]=jewelid;
                                gameinfo[num].grid[xpos-1].gmatched[ypos+1]=jewelid;
                                gameinfo[num].grid[xpos+1].gmatched[ypos-1]=jewelid;

                               gameinfo[num].hints[matchswap].cols[matchpos].score++;

                            end
                        end

                    end

                end
            end
        end
        first++;

        newscore=gameinfo[num].hints[matchswap].cols[matchpos].score-oldscore;
        // check for drops
        if(newscore>0)
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

      //  graph=0;

      //  frame;
        until (newscore==0)

        // swap the piece for the next move
        tp=piece[2];
        piece[2]=piece[1];
        piece[1]=piece[0];
        piece[0]=tp;

    end
    //x=160;
    //y=110;

//graph=1+col*10;
//frame;

end
//frame;
//debug;

gameinfo[num].newmatch=1;

end

process bestmove(num)

private

bests;
bestc;
score;
best;
bestpos;

begin

//write_int(0,120*num,0,0,&gameinfo[num].ts);
//write_int(0,120*num,16,0,&gameinfo[num].tc);
//write_int(0,120*num,32,0,&best);

loop

if(gameinfo[num].checkbest==1)
    //debug;
    frame(500);

    bests=0;
    bestc=0;
    best=0;
    gameinfo[num].auto=0;

    for(x=0;x<3;x++)
        for(y=0;y<6;y++)
            score=gameinfo[num].hints[x].cols[y].score;

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
            if(gameinfo[num].colpos[x]>bestpos)
                bestpos=gameinfo[num].colpos[x];
                bestc=x;//gameinfo[num].colpos[x];
            end
        end


    end

    gameinfo[num].checkbest=0;
    gameinfo[num].ts=bests;
    gameinfo[num].tc=bestc;
    gameinfo[num].auto=1;


    gameinfo[num].checkbest=0;

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

//write_int(0,num*160,0,0,&x);
//write_int(0,num*160,16,0,&ypos);
loop

    while(gameinfo[num].gameover==1)
        frame;
    end
    // populate the "next" grid
    for(tp=0;tp<3;tp++)
        gameinfo[num].play[tp]=gameinfo[num].next[tp];
    end
//    gameinfo[num].roll=0;
    donenext=0;
    setupmatch(num);
    cpos=0;
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
ypos=0;

// player box outline
graph=300;
y=-48;
x=40;//gameinfo[num].xpos+8+16*xpos;

// reset the gameinfo to say the piece is "in play"
gameinfo[num].played=0;
bestmove(num);

// main loop, repeated until gameover
repeat

    // auto play
    if(gameinfo[num].autoplay==1)

        gameinfo[num].autoswap=0;
        gameinfo[num].autoleft=0;
        gameinfo[num].autoright=0;
        gameinfo[num].autodown=0;

        if(gameinfo[num].auto==1)
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

    if(scan_code == keys[num].swap || gameinfo[num].autoswap==1)
        sound(sounds[6],256,256);
        cpos++;
        if(cpos==3)
            cpos=0;
        end
        tp=gameinfo[num].play[2];
        gameinfo[num].play[2]=gameinfo[num].play[1];
        gameinfo[num].play[1]=gameinfo[num].play[0];
        gameinfo[num].play[0]=tp;
        if(donenext==0)
            for(tp=0;tp<3;tp++)
                gameinfo[num].next[tp]=gameinfo[num].play[tp];
            end
        end
    end



    if(gameinfo[num].autoleft==1 || (scan_code == keys[num].left && xpos>0))
        if(gameinfo[num].grid[xpos-1].col[ypos]==0 &&
         gameinfo[num].grid[xpos-1].col[ypos-1*(ypos>0)]==0)
            x-=16;
            xpos--;
        end

    end



    if(gameinfo[num].autoright==1 || (scan_code == keys[num].right && xpos<5))
        if(gameinfo[num].grid[xpos+1].col[ypos]==0 &&
          gameinfo[num].grid[xpos+1].col[ypos-1*(ypos>0)]==0)
            x+=16;
            xpos++;
        end
    end

    if(key(keys[num].down) || timer[1]>dropnext || gameinfo[num].autodown==1)
        dropnext=timer[1]+dropinter;

        // check if block below is free
        d=1-d;
        y+=8;
        if(y==32 && donenext==0)
            getnext(num);
            donenext=1;
        end

        if(d==0)
            ypos++;
        end

        if(d==1)
        if(ypos==15 || gameinfo[num].grid[xpos].col[ypos]!=0)
            y=y-8;
            xpos=(x-8-(gameinfo[num].xpos))/16;
            //ypos=(y-(y%16))/16+2;
            ypos--;
            // populate play grid
            if(ypos>1)
                gameinfo[num].grid[xpos].col[ypos]=gameinfo[num].play[2];
                if(ypos>=1)
                    gameinfo[num].grid[xpos].col[ypos-1]=gameinfo[num].play[1];
                    if(ypos>=2)
                        gameinfo[num].grid[xpos].col[ypos-2]=gameinfo[num].play[0];
                    end
                end
            else
                gameinfo[num].gameover=1;
            end
            sound(sounds[3],256,256);

            if(donenext==0)
                getnext(num);
            end

            gameinfo[num].played=1;
        end

        end
    end

    frame;

until (gameinfo[num].played==1);

    gameinfo[num].autoswap=0;
    gameinfo[num].autoleft=0;
    gameinfo[num].autoright=0;
    gameinfo[num].autodown=0;

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
