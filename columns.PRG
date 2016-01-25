program columns;

global

struct gameinfo[3]
    struct grid[6]
         col[14];
    end

    xpos;
    ypos;
    score;
    level;
    curr[3];
    next[3];

    nextx;
//    nexty;
    jewels;

END

begin

set_mode(320224);

load_fpg("columns/columns.FPG");


put_screen(0,209);
while(timer[0]<200);
frame;
end

loop

graph=206;
x=160;
y=50;

gameinfo[0].nextx=120;
gameinfo[1].nextx=184;
gameinfo[2].nextx=88;

//mouse.graph=70;

//frame(20000);
put_screen(0,205);

//joystick();

while(!key(_space) && timer[0]<500)


frame;

end

graph=0;

put_screen(0,203);
game(16,8,0);
game(208,8,1);

frame;

while(!key(_esc) && timer[0]<1000)
frame;
end

signal(type game, s_kill_tree);


put_screen(0,205);

graph=206;
x=160;
y=50;

//joystick();
frame;

while(!key(_space) && timer[0]<1500)

frame;

end
graph=0;

put_screen(0,202);
game(112,8,2);
frame;

while(!key(_esc) && timer[0]<2000);
frame;
end
signal(type game, s_kill_tree);


timer[0]=0;

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




process game(xpos,ypos,num)

// start game engine in a scroll region starting x,y
private
falls=0;
gaps=0;
begin

//x=reserved.id_scan;
gameinfo[num].jewels=3+rand(0,3);
gameinfo[num].xpos=xpos;
gameinfo[num].ypos=ypos;

define_region(num+1,xpos,ypos,96,208);
shownext(num);

getnext(num);
getnext(num);
graph=70;
region=num+1;

for(x=0;x<6;x++)
for(y=12;y>=0;y--)
gameinfo[num].grid[x].col[y]=-1;
//rand(0,gameinfo[num].jewels);

jewel(x,y,num);
end
end

frame;


loop

//x=mouse.x;
//y=mouse.y;
//for(y=12;y>=0;y--)
//for(x=0;x<6;x++)
//for(y=0;y<14;y++)

x=rand(0,5);
y=0;//rand(0,12);

gameinfo[num].grid[x].col[y]=gameinfo[num].next[0];//rand(0,gameinfo[num].jewels-1);
gameinfo[num].grid[x].col[y+1]=gameinfo[num].next[1];
gameinfo[num].grid[x].col[y+2]=gameinfo[num].next[2];
//frame;

//jewel(x,y,num);
//end
//end
getnext(num);

repeat
    falls=0;
    gaps=0;
    for(y=12;y>=0;y--)
        for(x=0;x<6;x++)
            if(gameinfo[num].grid[x].col[y]==-1)
                gaps=1;
                if(y>0)
                    if(gameinfo[num].grid[x].col[y-1]>-1)
                        gameinfo[num].grid[x].col[y]=gameinfo[num].grid[x].col[y-1];
                        gameinfo[num].grid[x].col[y-1]=-1;
                        falls=1;
                    end
                end
            end
        end
    end

until (falls==0)

frame;

if(gaps==0)
    for(y=12;y>=0;y--)
        for(x=0;x<6;x++)
            gameinfo[num].grid[x].col[y]=-1;
        end
    end
end



frame;

end


end

function getnext(num)

begin

while(x<3)
gameinfo[num].curr[x]=gameinfo[num].next[x];
gameinfo[num].next[x]=rand(0,gameinfo[num].jewels-1);

x++;
end

return;

end




process jewel(xpos,ypos,num)

private

jewelid=-1;
px=0;
py=0;

shimmer=0;

begin

region = num+1;
x=xpos*16+gameinfo[num].xpos+8;
y=ypos*16+gameinfo[num].ypos+8;

loop

// check if jewel has changed
    if(gameinfo[num].grid[xpos].col[ypos]!=jewelid)
        jewelid = gameinfo[num].grid[xpos].col[ypos];
        graph=0;
        if(jewelid>-1)
            graph = 1+jewelid*10;
        //    frame;//(50);
            frame;//(200);//(50);
        end
        //frame;

    end
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

    if(jewelid>-1)
        if(shimmer==0)
            if(rand(0,500)>490)
                shimmer=7;
            end
        end

        if(shimmer>0)
            graph=1+jewelid*10+(9-shimmer);
            shimmer--;
            if(shimmer==0)
                graph=1+jewelid*10;
            end

        end
    end

    if(jewelid>-1)
    if(1)
            if(ypos>0)
            if(gameinfo[num].grid[xpos].col[ypos-1]==jewelid &&
               gameinfo[num].grid[xpos].col[ypos+1]==jewelid)

                gameinfo[num].grid[xpos].col[ypos-1]=-1;
                gameinfo[num].grid[xpos].col[ypos]=-1;
                gameinfo[num].grid[xpos].col[ypos-1]=-1;
                //jewelid=-1;
            end
            end

            if(xpos>0)
            if(gameinfo[num].grid[xpos-1].col[ypos]==jewelid &&
               gameinfo[num].grid[xpos+1].col[ypos]==jewelid)

                gameinfo[num].grid[xpos-1].col[ypos]=-1;
                gameinfo[num].grid[xpos+1].col[ypos]=-1;
                gameinfo[num].grid[xpos].col[ypos]=-1;
                //jewelid=-1;
            end
            if(ypos>0)
            if(gameinfo[num].grid[xpos-1].col[ypos-1]==jewelid &&
               gameinfo[num].grid[xpos+1].col[ypos+1]==jewelid)

                gameinfo[num].grid[xpos-1].col[ypos-1]=-1;
                gameinfo[num].grid[xpos+1].col[ypos+1]=-1;
                gameinfo[num].grid[xpos].col[ypos]=-1;
                //jewelid=-1;
            end


            if(gameinfo[num].grid[xpos-1].col[ypos+1]==jewelid &&
               gameinfo[num].grid[xpos+1].col[ypos-1]==jewelid)

                gameinfo[num].grid[xpos-1].col[ypos+1]=-1;
                gameinfo[num].grid[xpos+1].col[ypos-1]=-1;
                gameinfo[num].grid[xpos].col[ypos]=-1;
                //jewelid=-1;
            end
            end

            end

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
graph=1+jewelid*10;
end

frame;

end


end
