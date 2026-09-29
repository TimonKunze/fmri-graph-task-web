function rect = CenterRectOnPointd(rect, x, y)
 width = rect(3) - rect(1);
 height = rect(4) - rect(2);
 rect = [x-width/2, y-height/2, x+width/2, y+height/2];
end
