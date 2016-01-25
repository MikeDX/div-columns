program columns;

global

struct gameinfo[3]
    struct grid[6]
         col[14];

         struct data[14];
            jewelid;
            destroyed;
         end

    end


    matched=0;

    xpos;
    ypos;
    score;
    level;
    curr[3];
    next[3];
    play[3];
    nextx;
//    nexty;
    jewels;
    played=1;


END

attract=0;

begin

set_mode(320240);

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
//game(208,8,1);

frame;

while(attract==0 || (!key(_esc) && timer[0]<1000))
frame;
end

signal(type game, s_kill_tree);


put_screen(0,204);

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

while(attract==0 || (!key(_esc) && timer[0]<2000));
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
//getnext(num);
graph=70;
region=num+1;

for(x=0;x<6;x++)
for(y=12;y>=0;y--)
gameinfo[num].grid[x].col[y]=-1;
//rand(0,gameinfo[num].jewels);

jewel(x,y,num);
end
end

//frame;


loop

//x=mouse.x;
//y=mouse.y;
//for(y=12;y>=0;y--)
//for(x=0;x<6;x++)
//for(y=0;y<14;y++)
if(!attract)
    if(gameinfo[num].played==2)
        player(num);
        gameinfo[num].played=0;
    end

end

if(attract==1)
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

else

// player loop

end

if(gameinfo[num].played==1)
repeat

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
gameinfo[num].matched=0;

frame;
until(gameinfo[num].matched==0);

// allow player respawn
gameinfo[num].played=2;

end

//gameinfo[num].played=1;
//frame;
//gameinfo[num].played=0;
if(attract==1)
if(gaps==0)
    for(y=12;y>=0;y--)
        for(x=0;x<6;x++)
            gameinfo[num].grid[x].col[y]=-1;
        end
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
    if(true) //gameinfo[num].played==1)
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
                gameinfo[num].matched=1;

                //jewelid=-1;
            end
            end

            if(xpos>0)
            if(gameinfo[num].grid[xpos-1].col[ypos]==jewelid &&
               gameinfo[num].grid[xpos+1].col[ypos]==jewelid)

                gameinfo[num].grid[xpos-1].col[ypos]=-1;
                gameinfo[num].grid[xpos+1].col[ypos]=-1;
                gameinfo[num].grid[xpos].col[ypos]=-1;
                gameinfo[num].matched=1;
//jewelid=-1;
            end
            if(ypos>0)
            if(gameinfo[num].grid[xpos-1].col[ypos-1]==jewelid &&
               gameinfo[num].grid[xpos+1].col[ypos+1]==jewelid)

                gameinfo[num].grid[xpos-1].col[ypos-1]=-1;
                gameinfo[num].grid[xpos+1].col[ypos+1]=-1;
                gameinfo[num].grid[xpos].col[ypos]=-1;
                gameinfo[num].matched=1;
//jewelid=-1;
            end


            if(gameinfo[num].grid[xpos-1].col[ypos+1]==jewelid &&
               gameinfo[num].grid[xpos+1].col[ypos-1]==jewelid)

                gameinfo[num].grid[xpos-1].col[ypos+1]=-1;
                gameinfo[num].grid[xpos+1].col[ypos-1]=-1;
                gameinfo[num].grid[xpos].col[ypos]=-1;
                gameinfo[num].matched=1;
//jewelid=-1;
            end
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

process player(num)


private
dropinter=10;
dropnext=0;
xpos=3;
ypos=1;

begin
gameinfo[0].played=0;
region=num+1;

for(x=0;x<3;x++)
    gameinfo[num].play[x]=gameinfo[num].next[x];
end

x=gameinfo[num].xpos+8+16*3;
graph=300;
y=-16;

// show sprites
pjewel(num,0);
pjewel(num,1);
pjewel(num,2);


repeat
    if(key(_left) && xpos>0)
       x-=16;
       xpos--;

    end


    if(timer[1]>dropnext)
        dropnext=timer[1]+dropinter;
        if(y<12*16 && gameinfo[num].grid[xpos].col[ypos-2+(2*(ypos<2))]==-1)
            y+=8;
            if((y+8)%16==0)
                ypos++;
            end

            if(y==32)
                 getnext(num);
            end

        else
            gameinfo[num].played=1;
        end

    end

    frame;

until (gameinfo[num].played==1);

xpos=(x-8-(gameinfo[num].xpos))/16;

ypos=(y-(y%16))/16;

//debug;

gameinfo[num].grid[xpos].col[ypos]=gameinfo.play[2];
gameinfo[num].grid[xpos].col[ypos-1]=gameinfo.play[1];
gameinfo[num].grid[xpos].col[ypos-2]=gameinfo.play[0];
//frame;
//x=-1;
frame(200);
x=-1;
frame(200);
//frame(200);

end

process pjewel(num,idx)

begin
region=num+1;
graph=gameinfo[num].play[idx]*10+1;

repeat
x=father.x;
y=father.y-16+idx*16;

frame;
until (father.x==-1)



end

