program columns;

global

struct gameinfo[3]
    struct grid[6]
         col[14];
    end

  //  [12];
//    gridy[6];
    xpos;
    ypos;
    score;
    level;
    curr[3];
    next[3];
    nextx;
    nexty;
    jewels;

END

begin

set_mode(320224);

load_fpg("columns/columns.FPG");

put_screen(0,209);
while(timer[0]<200);
frame;
end

graph=206;
x=160;
y=50;

gameinfo[0].nextx=120;
gameinfo[0].nextx=184;
gameinfo[1].nexty=8;
gameinfo[1].nexty=8;

//mouse.graph=70;

//frame(20000);
put_screen(0,205);

//joystick();

while(!key(_space) && timer[0]<500)
//mouse.x=mouse.x-(mouse.x%8);
//mouse.graph++;

//if(mouse.graph==76)
//mouse.graph=70;
//end



frame;

end

graph=0;

put_screen(0,203);
game(16,8,0);
game(208,8,1);

loop
frame;
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
begin

//x=reserved.id_scan;
gameinfo[num].jewels=4-num;
gameinfo[num].xpos=xpos;
gameinfo[num].ypos=ypos;

define_region(num+1,xpos,ypos,96,208);
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

loop

//x=mouse.x;
//y=mouse.y;
for(y=12;y>=0;y--)
for(x=0;x<6;x++)
//for(y=0;y<14;y++)

//x=rand(0,5);
y=0;//rand(0,12);

gameinfo[num].grid[x].col[y]=rand(0,gameinfo[num].jewels-1);
//frame;

//jewel(x,y,num);
end
end

repeat
falls=0;

for(y=12;y>0;y--)
for(x=0;x<6;x++)
if(gameinfo[num].grid[x].col[y]==-1 && gameinfo[num].grid[x].col[y-1]>-1)
gameinfo[num].grid[x].col[y]=gameinfo[num].grid[x].col[y-1];
gameinfo[num].grid[x].col[y-1]=-1;
falls=1;

end
end
end
until (falls==0)

frame;

end


end

function getnext(num)

begin

while(x<3)
gameinfo[num].curr[x]=gameinfo[num].next[x];
gameinfo[num].next[x]=rand(0,gameinfo[num].jewels);

x++;
end

return;

end

process next(num)


begin


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

