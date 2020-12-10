function idx = EBINT(bbx, current_bbx)
%EBINT Summary of this function goes here
%   Detailed explanation goes here
X = bbx(:,1);
Y = bbx(:,2);
R_X = X + bbx(:,3);
R_Y =Y + bbx(:,4);

idx = find((X>=current_bbx(1) & R_X <current_bbx(1)+current_bbx(3))&...
            (X>current_bbx(1) & R_X <= current_bbx(1)+current_bbx(3))&...
            (Y>=current_bbx(2) & R_Y <current_bbx(2)+current_bbx(4))&...
            (Y>current_bbx(2) & R_Y <=current_bbx(2)+current_bbx(4)));
end

