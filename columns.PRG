program columns;

global

// define our game struct
// this allows a columns game to be started anywhere on scren
// any any number of grids

struct gameinfo[3]

    struct grid[6]
         col[14];

         struct data[14];
            jewelid;
            destroyed;
         end
    end

    gameover=0;

    matched=0;
    checkmatch=0;
    smash=0;

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

END

// set attract mode

attract=1;


begin

// reset the timer
timer[0]=0;

set_mode(320240);

load_fpg("columns/columns.FPG");

// colour bars
put_screen(0,209);

while(timer[0]<200);
frame;
end

// setup the "next" position for each game
// arcade
gameinfo[0].nextx=120;
gameinfo[1].nextx=184;

// single player
gameinfo[2].nextx=88;


//main operating loop
loop


    // columns title
    graph=206;
    x=160;
    y=50;

    // men intro with bag
    put_screen(0,205);

    // bag of gems process
    titlegems();


    // show this screen for 10 seconds
    while(!key(_space))// && timer[0]<1000)
        frame;
    end


    // reset timer
    timer[0]=0;

    // kill the gems spawning from the bag
    signal(type titlegems, s_kill_tree);

    frame;

    // hide "columns" title
    graph=0;



    if(key(_space))
       attract=0;
    end

    // show the arcade (two player) games grid
    put_screen(0,203);
    game(16,8,0);
    game(208,8,1);

    frame;

    // show this grid for 10 seconds, or until escape press
    // or continuously if not in attract mode
    while(attract==0 || (!key(_esc) && timer[0]<1000))
        frame;
    end

    // reset time
    timer[0]=0;

    //kill the game(s) and all subprocesses
    signal(type game, s_kill_tree);
    delete_text(all_text);
    frame;

    // show the female title

    put_screen(0,204);

    // show the coluns logo
    graph=206;

    frame;

    // show this tite for 10 seconds or until space pressed
    while(!key(_space))// && timer[0]<1000)
        frame;
    end


    // reset time
    timer[0]=0;

    // hide logo
    graph=0;

    // show the single player grid
    put_screen(0,217);
    // spawn the single player process
    game(112,8,2);
    frame;

    // loop whilst game playing, or for 10 seconds, or
    // until escape is pressed
    while(attract==0 || (!key(_esc) && timer[0]<1000));
        frame;
    end

    // reset time
    timer[0]=0;

    // kill the game
    signal(type game, s_kill_tree);
    // delete any texts on screen
    delete_text(all_text);


end  // end main loop



end




process game(xpos,ypos,num)

// start game engine in a scroll region starting x,y
private
falls=0;
gaps=0;
gx=0;
gy=0;

begin
    // background grid
    //graph=301;
    x=xpos+3*16;
    y=7*16;

    // set number of random jewels in this game
    gameinfo[num].jewels=3+rand(0,3);
    // set the game zpos ypos
    gameinfo[num].xpos=xpos;
    gameinfo[num].ypos=ypos;

    // setup a region for this grid (makes the sprite hiding easy)
    define_region(num+1,xpos,ypos,96,208);

    // display the "next" jewels
    shownext(num);

    // populate the "next" grid
    getnext(num);
    //frame;

    region=num+1;

    /// reset the grid to zero
    // and spawn jewels
    for(gx=0;gx<6;gx++)
        for(gy=12;gy>=0;gy--)
            gameinfo[num].grid[gx].col[gy]=0;
            jewel(gx,gy,num);
        end
    end


    loop

        if(!gameinfo[num].playing)
            player(num);
            gameinfo[num].playing=1;
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
                gameinfo[num].smash=7;
                repeat

                    frame(300);
                    gameinfo[num].smash--;
                until(gameinfo[num].smash==0);
                frame;
            end


            repeat  // while falls
                falls=0;
                gaps=0;
                for(gy=12;gy>=0;gy--)

                    for(gx=0;gx<6;gx++)

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

            until (falls==0)

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

begin
graph=0;
region=num+1;
x=xpos*16+gameinfo[num].xpos+8;
y=ypos*16+gameinfo[num].ypos+8;

loop
// if smashed
if(gameinfo[num].smash>0 && gameinfo[num].grid[xpos].col[ypos]<0)

    gameinfo[num].grid[xpos].col[ypos]=0;

    repeat
    //if(gameinfo[num].grid[xpos].col[ypos]<0)
        graph=66-gameinfo[num].smash;
   // end
        frame;
    until(gameinfo[num].smash==0);


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
//smashing=0;

begin

region = num+1;
x=xpos*16+gameinfo[num].xpos+8;
y=ypos*16+gameinfo[num].ypos+8;

//write_int(0,x,y,4,&gameinfo[num].grid[xpos].col[ypos]);
smash(xpos,ypos,num);
loop
//    if(true) //gameinfo[num].played==1)
// check if jewel has changed
    if(abs(gameinfo[num].grid[xpos].col[ypos])!=jewelid)
        jewelid = abs(gameinfo[num].grid[xpos].col[ypos]);
        graph=0;
        if(jewelid>0)
            graph = 1+(jewelid-1)*10;
        //    frame;//(50);
//            frame;//(200);//(50);
        end
        //frame;

    end
//    frame;
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


//jewel2(num,xpos,ypos);

end

process jewel2(num,xpos,ypos)

private
jewelid;
px;
py;

shimmer;

begin

region = num+1;
x=xpos*16+gameinfo[num].xpos+8;
y=ypos*16+gameinfo[num].ypos+8;



end

process jewel3(num,xpos,ypos);

private

jewelid;
px;
py;

shimmer;


begin


loop
if(true)
  /*
    if(jewelid>-1)
// check for drop

        if(ypos<12)
//debug;
            if(gameinfo[num].grid[xpos].col[ypos+1]==-1)
                gameinfo[num].grid[xpos].col[ypos+1]=jewelid;
            //jewelid=-1;
                gameinfo[num].grid[xpos].col[ypos]=-1;
                jewelid=-1;
                graph=0;
                //frame;//(50);//(50);

            end
        end
    /*
    if(jewelid>-1)
        if(shimmer==0)
            if(rand(0,60)>50)
                //shimmer=7;
            end
        end

        if(shimmer>0)
            graph=1+jewelid*10+(9-shimmer);
            shimmer--;
            if(shimmer==0)
                graph=1+jewelid*10;
            end

        end
      */
    end
    */

    if(jewelid>0)
        if(shimmer==0)
            if(rand(0,500)>490)
                shimmer=7;
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

    if(jewelid>0)
    //if(1)
        if(ypos>0)
            if(abs(gameinfo[num].grid[xpos].col[ypos-1])==jewelid &&
               abs(gameinfo[num].grid[xpos].col[ypos+1])==jewelid)

                gameinfo[num].grid[xpos].col[ypos-1]=-jewelid;
                //gameinfo[num].grid[xpos].col[ypos]=0;
                gameinfo[num].grid[xpos].col[ypos-1]=-jewelid;
                gameinfo[num].matched=1;

                //jewelid=-1;
            end
        end

        if(xpos>0 && xpos<5 )
            if(abs(gameinfo[num].grid[xpos-1].col[ypos])==jewelid &&
               abs(gameinfo[num].grid[xpos+1].col[ypos])==jewelid)

                gameinfo[num].grid[xpos-1].col[ypos]=-jewelid;
                gameinfo[num].grid[xpos+1].col[ypos]=-jewelid;
                //gameinfo[num].grid[xpos].col[ypos]=-1;
                gameinfo[num].matched=1;
//jewelid=-1;
            end

            if(ypos>0)
                if(abs(gameinfo[num].grid[xpos-1].col[ypos-1])==jewelid &&
                   abs(gameinfo[num].grid[xpos+1].col[ypos+1])==jewelid)

                    gameinfo[num].grid[xpos-1].col[ypos-1]=-jewelid;
                    gameinfo[num].grid[xpos+1].col[ypos+1]=-jewelid;
                   // gameinfo[num].grid[xpos].col[ypos]=-1;
                    gameinfo[num].matched=1;
//jewelid=-1;
                end


                if(abs(gameinfo[num].grid[xpos-1].col[ypos+1])==jewelid &&
                   abs(gameinfo[num].grid[xpos+1].col[ypos-1])==jewelid)

                    gameinfo[num].grid[xpos-1].col[ypos+1]=-jewelid;
                    gameinfo[num].grid[xpos+1].col[ypos-1]=-jewelid;
                //    gameinfo[num].grid[xpos].col[ypos]=-1;
                    gameinfo[num].matched=1;
//jewelid=-1;
                end
            end

        end

    //    end


    end
end

    frame;//(50);
    //(50);//(50);//(50);

end



//graph=
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

graph=1;
//break;
loop

if(gameinfo[num].next[idx]!=jewelid)
jewelid=gameinfo[num].next[idx];
graph=1+(jewelid-1)*10;
end

frame;

end


end

process player(num)


private
dropinter=100;
dropnext=0;
xpos=3;
ypos=1;
d=0;
gameover=0;
tp=0;
begin
gameinfo[0].played=0;
region=num+1;

//write_int(0,gameinfo[num].xpos,gameinfo[num].ypos,4,&y);
//write_int(0,gameinfo[num].xpos,gameinfo[num].ypos+8,4,&ypos);
//show player jewels

pjewel(num,0);
pjewel(num,1);
pjewel(num,2);




// show sprites
repeat

for(x=0;x<3;x++)
    gameinfo[num].play[x]=gameinfo[num].next[x];
end
d=0;
xpos=3;
ypos=-1;

graph=300;
y=-24;


x=gameinfo[num].xpos+8+16*3;

gameinfo[num].played=0;

// main loop, repeated until gameover
repeat

    if(scan_code == _space)
        tp=gameinfo[num].play[0];
        gameinfo[num].play[0]=gameinfo[num].play[1];
        gameinfo[num].play[1]=gameinfo[num].play[2];
        gameinfo[num].play[2]=tp;
    end

    if(scan_code == _left && xpos>0)
       if(gameinfo[num].grid[xpos-1].col[ypos+14*(ypos==-1)]==0)
       //gameinfo[num].play[2];

       x-=16;
       xpos--;
       end


    end
    if(scan_code == _right && xpos<5)
        if(gameinfo[num].grid[xpos+1].col[ypos+14*(ypos==-1)]==0)
            x+=16;
            xpos++;
        end

    end

    if(key(_down) || timer[1]>dropnext)
        dropnext=timer[1]+dropinter;

        // check if block below is free
        d=1-d;
        y+=8;
        if(y==32)
            getnext(num);
        end

        if(d==0)
            ypos++;
        end

        if(d==0)
        if(ypos==13 || gameinfo[num].grid[xpos].col[ypos]!=0)
            y=y-8;

            xpos=(x-8-(gameinfo[num].xpos))/16;
            ypos=(y-(y%16))/16;

            // populate play grid
            if(ypos>=0)
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
            gameinfo[num].played=1;
        end

        end
    end

    frame;

    until (gameinfo[num].played==1);

    // hide the player jewels and wait until main loop
    // has done its checks to resume play
    x=-1;
    repeat
        frame;
    until (gameinfo[num].played==0)


until(gameinfo[num].gameover==1);

end

process pjewel(num,idx)

// show the jewels the player has
begin
    priority=father.priority-1;

    region=num+1;
    graph=(gameinfo[num].play[idx]-1)*10+1;

    // repeat whilst not gameover
    repeat

        graph=(gameinfo[num].play[idx]-1)*10+1;

        // get coords from player
        x=father.x;
        y=father.y-16+idx*16;

        frame;

    until (gameinfo[num].gameover==1)

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

ydir=-6;//-(2-abs(xdir));
size=100;
while(count<40)//y<200+6*(abs(xdir)))//!out_region(id,0));
graph++;
if(graph==222)
graph=219;
end

count++;

if(ydir<0)
x=x+xdir;
else
//size;
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





process joystick()

begin

x=160;
y=200;
button();

loop
    graph=210;
    if(key(_left))
        graph=211;
    end

    if(key(_right))
        graph=212;
    end

    if(key(_down))
        graph=213;
    end

    frame;
end


end

process button()

begin

x=200;
y=180;


loop

    graph=214;

    if(key(_space))

        graph=215;

    end

    frame;

end

end



